import os
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    # Database connection string
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@localhost:5432/forensics"
    )

    # Disable tracking (improves performance)
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Where uploaded memory dumps will be stored
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "data/cases")

    # Max upload size (8GB)
    MAX_CONTENT_LENGTH = 8 * 1024 * 1024 * 1024  # 8 GB

    # Flask environment (development by default)
    FLASK_ENV = os.getenv("FLASK_ENV", "development")

    # Redis configuration for job queue
    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6382/0")
    
    # RQ Queue name for forensics analysis
    RQ_QUEUE_NAME = os.getenv("RQ_QUEUE_NAME", "forensics_analysis")

    # ── JWT Authentication ──────────────────────────────────────────────────
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "memflow-change-this-secret-in-production")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)    # Short-lived access token
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)   # Long-lived refresh token
    JWT_TOKEN_LOCATION = ["headers"]
    JWT_HEADER_NAME = "Authorization"
    JWT_HEADER_TYPE = "Bearer"

    # ── Admin Registration ──────────────────────────────────────────────────
    # Secret code required when registering as admin.
    # Set ADMIN_CODE env var to change it. Keep this secret!
    ADMIN_REGISTRATION_CODE = os.getenv("ADMIN_CODE", "MEMFLOW@Admin2026!")
