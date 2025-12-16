from datetime import datetime
from app.extensions.db import db
from sqlalchemy.sql import func

class CaseFile(db.Model):
    """CaseFile model representing a file associated with a memory forensics case."""
    __tablename__ = 'case_files'
    
    id = db.Column(db.Integer, primary_key=True)
    case_id = db.Column(db.Integer, db.ForeignKey('cases.id', ondelete='CASCADE'), nullable=False)
    file_path = db.Column(db.String(512), nullable=False)
    file_size = db.Column(db.BigInteger, nullable=False)
    checksum = db.Column(db.String(128), nullable=False)
    mime_type = db.Column(db.String(100))
    stored_at = db.Column(db.DateTime, nullable=False, server_default=func.now())
    report_path = db.Column(db.String(512))
    notes = db.Column(db.Text)
    
    # Relationship with Case
    case = db.relationship('Case', back_populates='files')
    
    def __repr__(self):
        return f'<CaseFile {self.id}: {self.file_path}>'
    
    def to_dict(self):
        """Convert the case file object to a dictionary."""
        return {
            "id": self.id,
            "case_id": self.case_id,
            "file_path": self.file_path,
            "file_size": self.file_size,
            "checksum": self.checksum,
            "mime_type": self.mime_type,
            "stored_at": self.stored_at.isoformat() if self.stored_at else None,
            "report_path": self.report_path,
            "notes": self.notes
        }
