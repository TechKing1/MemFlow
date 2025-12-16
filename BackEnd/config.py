import os
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
