"""import os
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
    #REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6382/0")
    REDIS_URL = os.getenv("REDIS_URL", "redis://172.19.160.1:6382/0")
    
    # RQ Queue name for forensics analysis
    RQ_QUEUE_NAME = os.getenv("RQ_QUEUE_NAME", "forensics_analysis")
"""
import os
import platform
from dotenv import load_dotenv

load_dotenv()

class Config:
    # --- AUTO-DETECT BRIDGE IP ---
    # If we are on Linux (Ubuntu/WSL), use the bridge IP. 
    # If on Windows, use localhost.
    IS_LINUX = platform.system() == "Linux"
    BRIDGE_IP = "172.19.160.1"
    TARGET_IP = BRIDGE_IP if IS_LINUX else "localhost"

    # Database connection string
    # Dynamically switches between localhost (Windows) and 172.19.160.1 (Ubuntu)
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        f"postgresql://postgres:password@{TARGET_IP}:5432/forensics"
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "data/cases")
    MAX_CONTENT_LENGTH = 8 * 1024 * 1024 * 1024  # 8 GB
    FLASK_ENV = os.getenv("FLASK_ENV", "development")

    # Redis configuration for job queue
    # Dynamically switches between localhost:6382 and 172.19.160.1:6382
    REDIS_URL = os.getenv("REDIS_URL", f"redis://{TARGET_IP}:6382/0")
    
    RQ_QUEUE_NAME = os.getenv("RQ_QUEUE_NAME", "forensics_analysis")