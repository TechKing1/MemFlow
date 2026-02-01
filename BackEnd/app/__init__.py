from flask import Flask
from config import Config
from app.extensions import db, migrate

def create_app():
    app = Flask(__name__)

    # Load config from Config class
    app.config.from_object(Config)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Initialize Redis connection (imported for side effects - connection test)
    from app.extensions import redis_conn, task_queue

    # Create database tables
    with app.app_context():
        db.create_all()

    # Register blueprints (API routes)
    from app.routes.cases import cases_bp
    app.register_blueprint(cases_bp, url_prefix="/api/cases")

    return app

