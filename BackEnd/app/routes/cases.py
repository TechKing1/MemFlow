import os
import uuid
import hashlib
from datetime import datetime
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
from sqlalchemy.exc import SQLAlchemyError
from app.extensions import db, task_queue
from app.models import Case, CaseFile

# Initialize Blueprint
cases_bp = Blueprint("cases", __name__)

# Allowed file extensions for memory dumps
ALLOWED_EXTENSIONS = {'raw', 'mem', 'vmem', 'bin'}

def allowed_file(filename):
    """Check if the file has an allowed extension"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def create_case_directory(case_id):
    """Create directory structure for a new case"""
    case_dir = os.path.join(current_app.config['UPLOAD_DIR'], str(case_id))
    os.makedirs(case_dir, exist_ok=True)
    return case_dir

def calculate_checksum(file_path):
    """Calculate SHA-256 checksum of a file"""
    sha256_hash = hashlib.sha256()
    with open(file_path, 'rb') as f:
        # Read and update hash in chunks of 4K
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

@cases_bp.route("", methods=["GET"])
def get_all_cases():
    """
    Get list of all cases with optional filtering and pagination
    ---
    tags:
      - Cases
    parameters:
      - name: status
        in: query
        type: string
        required: false
        description: Filter by case status (queued, processing, completed, failed)
      - name: page
        in: query
        type: integer
        required: false
        default: 1
        description: Page number for pagination
      - name: limit
        in: query
        type: integer
        required: false
        default: 10
        description: Number of cases per page
    responses:
      200:
        description: List of cases
    """
    try:
        # Get query parameters
        status = request.args.get('status')
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 10, type=int)
        
        # Validate pagination parameters
        if page < 1:
            page = 1
        if limit < 1 or limit > 100:
            limit = 10
        
        # Build query
        query = Case.query
        
        # Apply status filter if provided
        if status:
            query = query.filter_by(status=status)
        
        # Order by created_at descending (newest first)
        query = query.order_by(Case.created_at.desc())
        
        # Get total count before pagination
        total = query.count()
        
        # Apply pagination
        cases = query.paginate(page=page, per_page=limit, error_out=False)
        
        return jsonify({
            "cases": [case.to_dict() for case in cases.items],
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total,
                "pages": cases.pages,
                "has_next": cases.has_next,
                "has_prev": cases.has_prev
            }
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching cases: {str(e)}")
        return jsonify({"error": "Error fetching cases"}), 500

@cases_bp.route("/upload", methods=["POST"])
def upload_case():
    """
    Upload a memory dump file and create a new case
    ---
    tags:
      - Cases
    consumes:
      - multipart/form-data
    parameters:
      - in: formData
        name: file
        type: file
        required: true
        description: The memory dump file to upload
      - in: formData
        name: name
        type: string
        required: true
        description: Name for the case
      - in: formData
        name: description
        type: string
        required: false
        description: Optional case description
      - in: formData
        name: priority
        type: integer
        required: false
        description: Priority of the case (1-10, default 5)
    responses:
      201:
        description: Case created successfully
      400:
        description: Invalid file or missing parameters
    """
    # Check if the post request has the file part
    if 'file' not in request.files:
        return jsonify({"error": "No file part in request"}), 400
    
    file = request.files['file']
    
    # Check if file is empty
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    
    # Validate file extension
    if not (file and allowed_file(file.filename)):
        return jsonify({
            "error": "Invalid file type",
            "allowed_extensions": list(ALLOWED_EXTENSIONS)
        }), 400
    
    # Get form data
    case_name = request.form.get('name')
    if not case_name:
        return jsonify({"error": "Case name is required"}), 400
    
    description = request.form.get('description', '')
    priority = request.form.get('priority', 5, type=int)
    
    # Validate priority
    if not (1 <= priority <= 10):
        return jsonify({"error": "Priority must be between 1 and 10"}), 400
    
    try:
        # Start a database transaction
        db.session.begin()
        
        # Create case directory
        case = Case(
            name=case_name,
            description=description,
            priority=priority,
            status='queued',
            case_metadata={"original_filename": file.filename}
        )
        
        # Add to session to generate ID
        db.session.add(case)
        db.session.flush()  # This will generate the case ID
        
        # Create case directory
        case_dir = create_case_directory(case.id)
        
        # Save the file
        filename = secure_filename(file.filename)
        file_extension = os.path.splitext(filename)[1].lower()
        file_path = os.path.join(case_dir, f'raw{file_extension}')
        file.save(file_path)
        
        # Checksum is deferred to the worker task for faster upload response
        
        # Create case file record
        case_file = CaseFile(
            case_id=case.id,
            file_path=file_path,
            file_size=os.path.getsize(file_path),
            checksum='pending',
            mime_type=file.mimetype or 'application/octet-stream',
            notes=f"Original filename: {file.filename}"
        )
        
        db.session.add(case_file)
        
        # Commit the transaction
        db.session.commit()
        
        # ========== JOB ENQUEUE LOGIC ==========
        # After successful file upload and database commit,
        # enqueue the analysis job to Redis Queue
        job = None
        job_id = None
        
        if task_queue:
            try:
                # Import the task function
                from app.tasks import analyze_memory_dump
                
                # Enqueue the job with case_id as the only parameter
                # The worker will pick this up and process it asynchronously
                job = task_queue.enqueue(
                    analyze_memory_dump,  # Function to execute
                    case.id,              # Argument: case_id
                    job_timeout='2h',     # Maximum execution time (2 hours)
                    result_ttl=86400,     # Keep result for 24 hours
                    failure_ttl=86400     # Keep failure info for 24 hours
                )
                
                job_id = job.id
                current_app.logger.info(f"Enqueued analysis job {job_id} for case {case.id}")
                
            except Exception as e:
                # Log the error but don't fail the upload
                # The case is already created, user can retry analysis later
                current_app.logger.error(f"Failed to enqueue job for case {case.id}: {str(e)}")
        else:
            current_app.logger.warning("Task queue not available - job not enqueued")
        
        # Return success response with job information
        response_data = {
            "message": "Case created successfully",
            "case": case.to_dict()
        }
        
        # Add job info if job was enqueued
        if job_id:
            response_data["job"] = {
                "job_id": job_id,
                "status": "queued",
                "message": "Analysis job has been queued for processing"
            }
        
        return jsonify(response_data), 201
        
    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(f"Database error: {str(e)}")
        return jsonify({"error": "Database error occurred"}), 500
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error processing file: {str(e)}")
        return jsonify({"error": f"Error processing file: {str(e)}"}), 500

@cases_bp.route("/<int:case_id>", methods=["GET"])
def get_case(case_id):
    """
    Get case details by ID
    ---
    tags:
      - Cases
    parameters:
      - name: case_id
        in: path
        type: integer
        required: true
        description: ID of the case to retrieve
    responses:
      200:
        description: Case details
      404:
        description: Case not found
    """
    case = Case.query.get_or_404(case_id)
    return jsonify({"case": case.to_dict()})

@cases_bp.route("/<int:case_id>/status", methods=["GET"])
def get_case_status(case_id):
    """
    Get processing status of a case
    ---
    tags:
      - Cases
    parameters:
      - name: case_id
        in: path
        type: integer
        required: true
        description: ID of the case
    responses:
      200:
        description: Case status
      404:
        description: Case not found
    """
    case = Case.query.get_or_404(case_id)
    return jsonify({
        "case_id": case_id,
        "status": case.status,
        "updated_at": case.updated_at.isoformat() if case.updated_at else None
    })

@cases_bp.route("/<int:case_id>/report", methods=["GET"])
def get_case_report(case_id):
    """
    Get analysis report for a case — reads the real report.json.
    """
    case = Case.query.get_or_404(case_id)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()

    # Find report.json in the case directory
    if case_file:
        case_dir = os.path.dirname(case_file.file_path)
        report_path = os.path.join(case_dir, 'report.json')
    else:
        return jsonify({"error": "No files found for this case"}), 404

    if not os.path.exists(report_path):
        return jsonify({
            "case_id": case_id,
            "status": case.status,
            "report": None,
            "message": "Report not yet generated. Analysis may still be in progress."
        }), 200

    # Read the real report
    import json as json_lib
    with open(report_path, 'r', encoding='utf-8') as f:
        report_data = json_lib.load(f)

    return jsonify({
        "case_id": case_id,
        "case_name": case.name,
        "status": case.status,
        "report": report_data,
    }), 200


@cases_bp.route("/<int:case_id>/report/pdf", methods=["GET"])
def export_report_pdf(case_id):
    """Export report as PDF."""
    from app.services.report_generator import ReportGenerator

    case = Case.query.get_or_404(case_id)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()

    if not case_file:
        return jsonify({"error": "No files found for this case"}), 404

    case_dir = os.path.dirname(case_file.file_path)
    report_path = os.path.join(case_dir, 'report.json')

    if not os.path.exists(report_path):
        return jsonify({"error": "Report not yet generated"}), 404

    import json as json_lib
    with open(report_path, 'r', encoding='utf-8') as f:
        report_data = json_lib.load(f)

    generator = ReportGenerator()
    pdf_bytes = generator.generate_pdf(report_data, case.name)

    from flask import send_file
    import io
    return send_file(
        io.BytesIO(pdf_bytes),
        mimetype='application/pdf',
        as_attachment=True,
        download_name=f'memflow_report_case_{case_id}.pdf'
    )


@cases_bp.route("/<int:case_id>/report/html", methods=["GET"])
def export_report_html(case_id):
    """Export report as HTML."""
    from app.services.report_generator import ReportGenerator

    case = Case.query.get_or_404(case_id)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()

    if not case_file:
        return jsonify({"error": "No files found for this case"}), 404

    case_dir = os.path.dirname(case_file.file_path)
    report_path = os.path.join(case_dir, 'report.json')

    if not os.path.exists(report_path):
        return jsonify({"error": "Report not yet generated"}), 404

    import json as json_lib
    with open(report_path, 'r', encoding='utf-8') as f:
        report_data = json_lib.load(f)

    generator = ReportGenerator()
    html_content = generator.generate_html(report_data, case.name)

    from flask import Response
    return Response(html_content, mimetype='text/html')


@cases_bp.route("/<int:case_id>/stages", methods=["GET"])
def get_case_stages(case_id):
    """
    Get analysis pipeline stages + analysis logs for the case view screen.
    Derives stages from report.json performance data and case status.
    """
    case = Case.query.get_or_404(case_id)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()

    # Define pipeline stages
    pipeline = [
        {"key": "file_upload", "name": "File Upload", "description": "Validating and storing memory dump"},
        {"key": "format_detection", "name": "Format Detection", "description": "Identifying memory dump format"},
        {"key": "hashing", "name": "File Hashing", "description": "Computing MD5, SHA1, SHA256 hashes"},
        {"key": "os_detection", "name": "OS Detection", "description": "Detecting operating system"},
        {"key": "plugin_execution", "name": "Plugin Execution", "description": "Running Volatility3 plugins"},
        {"key": "report_generation", "name": "Report Generation", "description": "Generating analysis report"},
    ]

    report_data = None
    if case_file:
        case_dir = os.path.dirname(case_file.file_path)
        report_path = os.path.join(case_dir, 'report.json')
        if os.path.exists(report_path):
            import json as json_lib
            with open(report_path, 'r', encoding='utf-8') as f:
                report_data = json_lib.load(f)

    # Build stage statuses based on case state + report data
    stage_timings = {}
    if report_data:
        stage_timings = report_data.get('performance', {}).get('stage_timings', {})

    stages = []
    logs = []
    analysis_date = None
    if report_data:
        analysis_date = report_data.get('analysis_metadata', {}).get('analysis_date', '')

    for stage in pipeline:
        timing = stage_timings.get(stage['key'])

        if case.status == 'completed':
            status = 'completed'
            time_taken = round(timing, 2) if timing else None
        elif case.status == 'failed':
            # Mark stages up to where it failed
            if timing is not None:
                status = 'completed'
                time_taken = round(timing, 2)
            else:
                status = 'failed' if stage == pipeline[-1] else 'pending'
                time_taken = None
        elif case.status == 'processing':
            if timing is not None:
                status = 'completed'
                time_taken = round(timing, 2)
            elif not any(s.get('status') == 'running' for s in stages):
                status = 'running'
                time_taken = None
            else:
                status = 'pending'
                time_taken = None
        else:  # queued
            status = 'pending'
            time_taken = None

        # File upload is always completed if case exists
        if stage['key'] == 'file_upload':
            status = 'completed'
            time_taken = None  # instant

        stages.append({
            "key": stage['key'],
            "name": stage['name'],
            "description": stage['description'],
            "status": status,
            "time_taken": time_taken,
        })

    # Generate synthetic log entries from report data
    if report_data and analysis_date:
        try:
            from datetime import datetime as dt
            base_time = dt.fromisoformat(analysis_date)
            elapsed = 0

            logs.append({"time": base_time.strftime("%H:%M:%S"), "message": f"Starting analysis for Case #{case_id}..."})

            file_info = report_data.get('file_information', {})
            if file_info:
                logs.append({"time": base_time.strftime("%H:%M:%S"), "message": f"File validation passed. Size: {file_info.get('size_human', 'Unknown')}"})

            fmt = report_data.get('file_information', {}).get('format', {})
            if fmt:
                elapsed += stage_timings.get('format_detection', 0)
                t = base_time.replace(second=min(int(base_time.second + elapsed), 59))
                logs.append({"time": t.strftime("%H:%M:%S"), "message": f"Format detected: {fmt.get('type', 'unknown').upper()} ({fmt.get('confidence', 0)}% confidence)"})

            if stage_timings.get('hashing'):
                elapsed += stage_timings['hashing']
                minutes = int(elapsed // 60)
                secs = int(elapsed % 60)
                t_str = f"{base_time.hour:02}:{base_time.minute + minutes:02}:{secs:02}"
                hashes = file_info.get('hashes', {})
                logs.append({"time": t_str, "message": f"Hashing complete. MD5: {(hashes.get('md5', '')[:16])}..."})

            os_info = report_data.get('os_detection', {})
            if os_info.get('operating_system'):
                elapsed += stage_timings.get('os_detection', 0)
                minutes = int(elapsed // 60)
                secs = int(elapsed % 60)
                t_str = f"{base_time.hour:02}:{base_time.minute + minutes:02}:{secs:02}"
                logs.append({"time": t_str, "message": f"OS identified: {os_info['operating_system']} (confidence: {os_info.get('confidence_score', 0)}%)"})
                for ev in os_info.get('evidence', [])[:3]:
                    logs.append({"time": t_str, "message": f"  ↳ {ev}"})

            # Plugin execution
            plugins = report_data.get('raw_volatility_data', {}).get('plugins_attempted', {})
            if plugins:
                elapsed += stage_timings.get('plugin_execution', 0) * 0.1
                minutes = int(elapsed // 60)
                secs = int(elapsed % 60)
                t_str = f"{base_time.hour:02}:{base_time.minute + minutes:02}:{secs:02}"
                logs.append({"time": t_str, "message": f"Starting plugin execution ({len(plugins)} plugins)..."})

                for plugin_name, success in plugins.items():
                    icon = "✓" if success else "✗"
                    logs.append({"time": t_str, "message": f"  {icon} {plugin_name}: {'success' if success else 'no output'}"})

            # Process analysis
            proc = report_data.get('process_analysis', {})
            if proc.get('detected'):
                logs.append({"time": t_str, "message": f"Found {proc.get('count', 0)} running processes"})

            # Final
            total_time = report_data.get('performance', {}).get('total_time', 0)
            total_min = int(total_time // 60)
            total_sec = int(total_time % 60)
            logs.append({"time": t_str if plugins else base_time.strftime("%H:%M:%S"), "message": f"Analysis complete. Total time: {total_min}m {total_sec}s"})
        except Exception as e:
            logs.append({"time": "00:00:00", "message": f"Log generation error: {e}"})
    elif case.status == 'queued':
        logs.append({"time": datetime.utcnow().strftime("%H:%M:%S"), "message": "Case queued. Waiting for worker..."})
    elif case.status == 'processing':
        logs.append({"time": datetime.utcnow().strftime("%H:%M:%S"), "message": "Analysis in progress..."})

    # Pull threat summary from report if available
    threat_summary = None
    if report_data:
        threat_summary = report_data.get('threat_summary')

    # Build response
    overall_progress = sum(1 for s in stages if s['status'] == 'completed') / len(stages)

    return jsonify({
        "case_id": case_id,
        "case_name": case.name,
        "status": case.status,
        "file_name": case.case_metadata.get('original_filename', 'Unknown') if case.case_metadata else 'Unknown',
        "file_size": case_file.file_size if case_file else 0,
        "created_at": case.created_at.isoformat() if case.created_at else None,
        "overall_progress": round(overall_progress, 2),
        "total_time": report_data.get('performance', {}).get('total_time') if report_data else None,
        "stages": stages,
        "logs": logs,
        "threat_summary": threat_summary,
        "stats": {
            "processes_found": report_data.get('process_analysis', {}).get('total_count', 0) if report_data else 0,
            "network_connections": report_data.get('network_analysis', {}).get('total_connections', 0) if report_data else 0,
            "os_detected": report_data.get('os_detection', {}).get('operating_system') if report_data else None,
            "threats_found": threat_summary.get('total', 0) if threat_summary else 0,
            "critical_alerts": threat_summary.get('critical', 0) if threat_summary else 0,
        }
    }), 200


@cases_bp.route("/<int:case_id>/threats", methods=["GET"])
def get_case_threats(case_id):
    """
    Get full threat alert list for a case (from Rule Engine output in report.json).
    Returns structured alerts with MITRE ATT&CK mappings and DFIR explanations.
    """
    case = Case.query.get_or_404(case_id)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()

    if not case_file:
        return jsonify({"error": "No files found for this case"}), 404

    case_dir = os.path.dirname(case_file.file_path)
    report_path = os.path.join(case_dir, 'report.json')

    if not os.path.exists(report_path):
        return jsonify({"alerts": [], "summary": None, "status": case.status}), 200

    import json as json_lib
    with open(report_path, 'r', encoding='utf-8') as f:
        report_data = json_lib.load(f)

    alerts = report_data.get('threat_alerts', [])
    summary = report_data.get('threat_summary')

    # Optional: filter by severity via query param ?severity=CRITICAL
    severity_filter = request.args.get('severity', '').upper()
    if severity_filter:
        alerts = [a for a in alerts if a.get('severity') == severity_filter]

    return jsonify({
        "case_id": case_id,
        "case_name": case.name,
        "status": case.status,
        "alerts": alerts,
        "summary": summary,
        "total": len(alerts),
    }), 200
