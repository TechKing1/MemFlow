import os
import uuid
import hashlib
from datetime import datetime
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
from sqlalchemy.exc import SQLAlchemyError
from app.extensions import db
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
        
        # Calculate file checksum
        checksum = calculate_checksum(file_path)
        
        # Create case file record
        case_file = CaseFile(
            case_id=case.id,
            file_path=file_path,
            file_size=os.path.getsize(file_path),
            checksum=checksum,
            mime_type=file.mimetype or 'application/octet-stream',
            notes=f"Original filename: {file.filename}"
        )
        
        db.session.add(case_file)
        
        # Commit the transaction
        db.session.commit()
        
        return jsonify({
            "message": "Case created successfully",
            "case": case.to_dict()
        }), 201
        
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
    Get analysis report for a case (placeholder)
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
        description: Case report
      404:
        description: Case not found
    """
    case = Case.query.get_or_404(case_id)
    
    # Get the first file (in a real app, you might have multiple files per case)
    case_file = CaseFile.query.filter_by(case_id=case_id).first()
    
    # Basic report data
    report = {
        "case_id": case_id,
        "status": case.status,
        "report": {
            "summary": "This is a placeholder report. Real analysis will be implemented in a future update.",
            "analysis_date": datetime.utcnow().isoformat(),
            "file_info": {
                "original_filename": case.case_metadata.get('original_filename', 'unknown'),
                "file_size": case_file.file_size if case_file else 0,
                "checksum": case_file.checksum if case_file else None,
                "stored_at": case_file.stored_at.isoformat() if case_file and case_file.stored_at else None
            },
            "analysis": {
                "indicators_found": 0,
                "processes_analyzed": 0,
                "network_connections": [],
                "artifacts_found": []
            }
        }
    }
    
    return jsonify(report)
