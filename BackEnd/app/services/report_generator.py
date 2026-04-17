"""
Report generation service — HTML rendering and PDF export.
"""
from datetime import datetime
from jinja2 import Environment, FileSystemLoader
import os


class ReportGenerator:
    """Generates HTML and PDF reports from Volatility3 analysis data."""

    def __init__(self):
        template_dir = os.path.join(os.path.dirname(__file__), '..', 'templates')
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            autoescape=True
        )

    def _transform_data(self, report_data: dict, case_name: str) -> dict:
        """Transform raw report.json into UI-friendly format."""
        metadata = report_data.get('analysis_metadata', {})
        file_info = report_data.get('file_information', {})
        os_info = report_data.get('os_detection', {})
        process = report_data.get('process_analysis', {})
        network = report_data.get('network_analysis', {})
        performance = report_data.get('performance', {})
        plugin_failures = report_data.get('plugin_failures', {})
        raw_data = report_data.get('raw_volatility_data', {})

        # Format total time
        total_time = performance.get('total_time', 0)
        if total_time > 60:
            time_str = f"{total_time / 60:.1f} min"
        else:
            time_str = f"{total_time:.1f}s"

        # Format analysis date
        analysis_date_raw = metadata.get('analysis_date', '')
        try:
            dt = datetime.fromisoformat(analysis_date_raw)
            analysis_date = dt.strftime('%B %d, %Y at %H:%M')
        except (ValueError, TypeError):
            analysis_date = analysis_date_raw or 'Unknown'

        # Count successful/failed plugins
        plugins_attempted = raw_data.get('plugins_attempted', {})
        plugins_total = len(plugins_attempted)
        plugins_success = sum(1 for v in plugins_attempted.values() if v)
        plugins_failed = plugins_total - plugins_success

        # Stage timings
        stage_timings = performance.get('stage_timings', {})
        stages = []
        for stage, seconds in stage_timings.items():
            name = stage.replace('_', ' ').title()
            stages.append({'name': name, 'seconds': round(seconds, 2)})

        return {
            'case_name': case_name,
            'generated_at': datetime.utcnow().strftime('%B %d, %Y at %H:%M UTC'),
            'analyzer': metadata.get('analyzer', 'Unknown'),
            'analysis_date': analysis_date,
            'plugin_level': metadata.get('plugin_level', 'Unknown'),
            'plugins_executed': metadata.get('plugins_executed', 0),
            'plugins_successful': metadata.get('plugins_successful', 0),
            'file_size': file_info.get('size_human', 'Unknown'),
            'file_format': file_info.get('format', {}).get('type', 'Unknown'),
            'format_confidence': file_info.get('format', {}).get('confidence', 0),
            'hashes': file_info.get('hashes', {}),
            'os_name': os_info.get('operating_system', 'Unknown'),
            'os_confidence': os_info.get('confidence_score', 0),
            'os_confidence_level': os_info.get('confidence_level', 'Unknown'),
            'os_method': os_info.get('detection_method', 'Unknown'),
            'os_evidence': os_info.get('evidence', []),
            'process_detected': process.get('detected', False),
            'process_count': process.get('count', 0),
            'network_detected': network.get('detected', False),
            'network_count': network.get('count', 0),
            'network_failure': network.get('failure_reason', None),
            'total_time': time_str,
            'stages': stages,
            'plugins_total': plugins_total,
            'plugins_success': plugins_success,
            'plugins_failed': plugins_failed,
            'plugin_failures': plugin_failures,
        }

    def generate_html(self, report_data: dict, case_name: str = "Unknown") -> str:
        """Render the report as HTML using Jinja2 template."""
        context = self._transform_data(report_data, case_name)
        template = self.env.get_template('report_template.html')
        return template.render(**context)

    def generate_pdf(self, report_data: dict, case_name: str = "Unknown") -> bytes:
        """Generate PDF from HTML report using WeasyPrint."""
        html_content = self.generate_html(report_data, case_name)
        try:
            from weasyprint import HTML
            pdf_bytes = HTML(string=html_content).write_pdf()
            return pdf_bytes
        except ImportError:
            raise RuntimeError(
                "WeasyPrint is not installed. Run: pip install weasyprint\n"
                "Also install system deps: sudo apt install libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0"
            )
