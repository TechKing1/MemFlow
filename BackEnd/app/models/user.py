"""
User model for MemFlow authentication.
Stores analyst/admin accounts with bcrypt-hashed passwords.
"""
import bcrypt
from datetime import datetime
from app.extensions.db import db


class User(db.Model):
    """User account for MemFlow platform."""
    __tablename__ = 'users'

    id           = db.Column(db.Integer, primary_key=True)
    username     = db.Column(db.String(80),  unique=True, nullable=False, index=True)
    email        = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role         = db.Column(db.String(20),  nullable=False, default='analyst')  # 'analyst' | 'admin'
    is_active    = db.Column(db.Boolean,     nullable=False, default=True)
    created_at   = db.Column(db.DateTime,    nullable=False, default=datetime.utcnow)
    last_login   = db.Column(db.DateTime,    nullable=True)

    def set_password(self, password: str) -> None:
        """Hash and store the password using bcrypt."""
        salt = bcrypt.gensalt()
        self.password_hash = bcrypt.hashpw(
            password.encode('utf-8'), salt
        ).decode('utf-8')

    def check_password(self, password: str) -> bool:
        """Verify a plain-text password against the stored hash."""
        return bcrypt.checkpw(
            password.encode('utf-8'),
            self.password_hash.encode('utf-8')
        )

    def to_dict(self) -> dict:
        """Return user info safe for API responses (no password hash)."""
        return {
            'id':         self.id,
            'username':   self.username,
            'email':      self.email,
            'role':       self.role,
            'is_active':  self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
        }

    def __repr__(self):
        return f'<User {self.id}: {self.email} ({self.role})>'
