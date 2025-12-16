from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from sqlalchemy.dialects.postgresql import JSONB, ENUM as PgEnum
from sqlalchemy import Enum
import enum

# Create SQLAlchemy instance
db = SQLAlchemy()

# Create Migrate instance
migrate = Migrate()

# Define custom ENUM types
class CaseStatus(enum.Enum):
    QUEUED = 'queued'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    FAILED = 'failed'
    ARCHIVED = 'archived'

# Create custom ENUM type for case status
case_status_enum = PgEnum(
    CaseStatus,
    name='case_status',
    create_type=True,
    values_callable=lambda enum: [e.value for e in enum]
)

# Import models after db is defined to avoid circular imports
from app.models.case import Case
from app.models.casefile import CaseFile
