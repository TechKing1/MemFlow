from datetime import datetime
from app.extensions.db import db
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func

class Case(db.Model):
    """Case model representing a memory forensics case."""
    __tablename__ = 'cases'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), nullable=False, default='queued')
    priority = db.Column(db.SmallInteger, nullable=False, default=5)
    created_at = db.Column(db.DateTime, nullable=False, server_default=func.now())
    updated_at = db.Column(db.DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    case_metadata = db.Column('metadata', JSONB, nullable=False, default=dict)
    
    # Relationship with CaseFile
    files = db.relationship('CaseFile', back_populates='case', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Case {self.id}: {self.name}>'

    def to_dict(self):
        """Convert the case object to a dictionary."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "status": self.status,
            "priority": self.priority,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "metadata": self.case_metadata,
            "files": [file.to_dict() for file in self.files] if self.files else []
        }
