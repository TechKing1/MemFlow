"""
Notification model for storing case lifecycle events.
"""
from datetime import datetime
from app.extensions.db import db
from sqlalchemy.sql import func


class Notification(db.Model):
    """Notification model for case status events."""
    __tablename__ = 'notifications'

    id = db.Column(db.Integer, primary_key=True)
    case_id = db.Column(db.Integer, db.ForeignKey('cases.id', ondelete='CASCADE'), nullable=False, index=True)
    type = db.Column(db.String(50), nullable=False)  # case_processing, case_completed, case_failed
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.String(500), nullable=False)
    is_read = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, server_default=func.now())

    # Relationship
    case = db.relationship('Case', backref='notifications')

    def __repr__(self):
        return f'<Notification {self.id}: {self.type} for case {self.case_id}>'

    def to_dict(self):
        return {
            "id": self.id,
            "case_id": self.case_id,
            "type": self.type,
            "title": self.title,
            "message": self.message,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
