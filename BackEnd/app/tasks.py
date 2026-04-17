"""
Background tasks for memory dump analysis.
These tasks are executed by RQ workers asynchronously.
"""
import os
import sys
import json
from datetime import datetime


def _emit_case_update(socketio, case_id: int, status: str, message: str):
    """Emit a WebSocket event AND create a persistent Notification record."""
    # 1. Emit WebSocket event for real-time UI update
    try:
        socketio.emit('case_update', {
            'case_id': case_id,
            'status': status,
            'message': message,
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        print(f"[TASK] WebSocket emit failed (non-critical): {e}")

    # 2. Create persistent notification in database
    try:
        from app.models.notification import Notification
        from app.extensions import db

        # Map status to notification type and title
        type_map = {
            'processing': ('case_processing', f'Case #{case_id} Processing'),
            'completed': ('case_completed', f'Case #{case_id} Completed'),
            'failed': ('case_failed', f'Case #{case_id} Failed'),
        }

        notif_type, title = type_map.get(status, ('case_update', f'Case #{case_id} Updated'))

        notification = Notification(
            case_id=case_id,
            type=notif_type,
            title=title,
            message=message,
            is_read=False,
        )
        db.session.add(notification)
        db.session.commit()
        print(f"[TASK] Notification created: {title}")
    except Exception as e:
        print(f"[TASK] Notification creation failed (non-critical): {e}")


def analyze_memory_dump(case_id: int):
    """
    Analyze a memory dump file for a given case using Volatility3 via MemflowAnalyzer.

    This task is executed asynchronously by RQ workers.

    Args:
        case_id: The ID of the case to analyze

    Returns:
        dict: Analysis results summary
    """
    # Import create_app here to build the Flask app context
    # The worker runs as a separate process with no app context by default
    from app import create_app
    from app.extensions import db
    from app.models.case import Case
    from app.models.casefile import CaseFile

    # Add cli_tool directory to path for MemflowAnalyzer import
    cli_tool_path = os.path.join(
        os.path.dirname(__file__), '..', '..', 'cli_tool'
    )
    if cli_tool_path not in sys.path:
        sys.path.insert(0, cli_tool_path)

    from memflow_cli_v2 import MemflowAnalyzer
    from rule_engine import RuleEngine

    app = create_app()

    analysis_start = datetime.utcnow()
    print(f"🔍 Analyzing memory dump: case_id={case_id}")
    print(f"[TASK] Starting analysis for case_id={case_id}")

    # Wrap all DB operations inside app context
    with app.app_context():
        try:
            # Get case from database
            case = Case.query.get(case_id)
            if not case:
                raise ValueError(f"Case {case_id} not found")

            # Get the file path from the database (NOT passing binary data through Redis)
            case_file = CaseFile.query.filter_by(case_id=case_id).first()
            if not case_file:
                raise ValueError(f"No file found for case {case_id}")

            dump_path = case_file.file_path
            print(f"[TASK] Memory dump path: {dump_path}")

            # Verify file exists on disk
            if not os.path.exists(dump_path):
                raise FileNotFoundError(f"Memory dump file not found: {dump_path}")

            file_size = os.path.getsize(dump_path)
            print(f"[TASK] File size: {file_size} bytes")

            # Update case status to PROCESSING
            case.status = 'processing'
            case.updated_at = datetime.utcnow()
            db.session.commit()
            print(f"[TASK] Case {case_id} status updated to PROCESSING")
            from app.extensions import socketio
            _emit_case_update(socketio, case_id, 'processing', f'Case {case_id} analysis started')

            # ─────────────────────────────────────────────────────────────
            # Calculate SHA256 checksum (deferred from upload for speed)
            # ─────────────────────────────────────────────────────────────
            import hashlib
            print(f"[TASK] Calculating SHA256 checksum...")
            sha256_hash = hashlib.sha256()
            with open(dump_path, "rb") as f:
                for byte_block in iter(lambda: f.read(65536), b""):
                    sha256_hash.update(byte_block)
            checksum = sha256_hash.hexdigest()

            # Update CaseFile with real checksum
            case_file.checksum = checksum
            db.session.commit()
            print(f"[TASK] Checksum: {checksum}")

            # ─────────────────────────────────────────────────────────────
            # Run Volatility3 Analysis via MemflowAnalyzer
            # ─────────────────────────────────────────────────────────────
            print(f"🧠 Starting Volatility3 analysis for case {case_id}...")

            def on_progress(progress):
                """Log analysis progress to worker console"""
                print(f"  [{progress.stage}] {progress.message} ({progress.percentage:.1f}%)")

            analyzer = MemflowAnalyzer(progress_callback=on_progress)

            # Run the full analysis (standard level includes network + essential plugins)
            results = analyzer.analyze(
                dump_path=dump_path,
                plugin_level="standard",
                use_color=False   # Disable colors since we're in a background process
            )

            print(f"✅ Volatility3 analysis completed for case {case_id}")

            # ─────────────────────────────────────────────────────────────
            # Run Rule Engine — threat detection on analysis results
            # ─────────────────────────────────────────────────────────────
            print(f"🔎 Running Rule Engine threat detection for case {case_id}...")
            try:
                engine     = RuleEngine()
                alerts     = engine.run_all_rules(results)
                threat_summary = engine.summarize(alerts)

                # Attach to results so they land in report.json
                results['threat_alerts']  = [a.to_dict() for a in alerts]
                results['threat_summary'] = threat_summary

                print(
                    f"🚨 Rule Engine complete: "
                    f"{threat_summary['total']} alerts "
                    f"({threat_summary['critical']} CRITICAL, "
                    f"{threat_summary['high']} HIGH, "
                    f"{threat_summary['medium']} MEDIUM)"
                )
            except Exception as re_err:
                print(f"[TASK] Rule Engine failed (non-critical): {re_err}")
                results['threat_alerts']  = []
                results['threat_summary'] = {
                    'total': 0, 'critical': 0, 'high': 0,
                    'medium': 0, 'low': 0, 'info': 0,
                    'error': str(re_err)
                }

            # ─────────────────────────────────────────────────────────────
            # Save JSON report to the case directory
            # ─────────────────────────────────────────────────────────────
            report_path = os.path.join(os.path.dirname(dump_path), 'report.json')

            with open(report_path, 'w', encoding='utf-8') as f:
                json.dump(results, f, indent=2, default=str)

            print(f"[TASK] Report saved to: {report_path}")

            # ─────────────────────────────────────────────────────────────
            # Update case status to COMPLETED (+ store threat count in metadata)
            # ─────────────────────────────────────────────────────────────
            case.status = 'completed'
            case.updated_at = datetime.utcnow()

            # Persist threat count in case metadata for dashboard stats card
            threat_count = results.get('threat_summary', {}).get('total', 0)
            current_meta = case.case_metadata or {}
            current_meta['threats_found'] = threat_count
            current_meta['critical_alerts'] = results.get('threat_summary', {}).get('critical', 0)
            case.case_metadata = current_meta

            db.session.commit()
            elapsed = (datetime.utcnow() - analysis_start).total_seconds()
            print(f"[TASK] Case {case_id} status updated to COMPLETED")
            print(f"⏱ Total analysis time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
            _emit_case_update(socketio, case_id, 'completed',
                              f'Case {case_id} analysis complete in {elapsed:.0f}s')

            # Summary for the job return value
            os_info = results.get("os_detection", {})
            process_info = results.get("process_analysis", {})
            perf = results.get("performance", {})

            return {
                "status": "success",
                "case_id": case_id,
                "dump_path": dump_path,
                "report_path": report_path,
                "analysis_summary": {
                    "os": os_info.get("operating_system", "Unknown"),
                    "os_confidence": os_info.get("confidence_score", 0),
                    "total_processes": process_info.get("total_count", 0),
                    "analysis_time_seconds": perf.get("total_time", 0)
                }
            }

        except Exception as e:
            print(f"[TASK ERROR] Failed to analyze case {case_id}: {e}")

            # Update case status to FAILED
            try:
                case = Case.query.get(case_id)
                if case:
                    case.status = 'failed'
                    case.updated_at = datetime.utcnow()
                    db.session.commit()
                    _emit_case_update(socketio, case_id, 'failed',
                                      f'Case {case_id} analysis failed: {str(e)[:80]}')
            except Exception as db_error:
                print(f"[TASK ERROR] Failed to update case status: {db_error}")

            raise
