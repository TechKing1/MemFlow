"""
Authentication routes for MemFlow.
Handles register, login, token refresh, profile, password change & reset.
"""
import re
import secrets
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
)

from app.extensions.db import db
from app.models.user import User

auth_bp = Blueprint('auth', __name__)

# ── Password strength cache (reset tokens stored in-memory for simplicity) ──
_reset_tokens: dict = {}   # { token: { 'user_id': int, 'expires_at': datetime } }


# ── Helpers ──────────────────────────────────────────────────────────────────

def _validate_password(password: str) -> str | None:
    """
    Returns an error message string if the password fails strength rules,
    or None if the password is valid.

    Rules:
      - At least 8 characters
      - At least 1 uppercase letter
      - At least 1 digit (number)
      - At least 1 special character from: !@#$%^&*()_+-=[]{}|;',.<>?
    """
    if len(password) < 8:
        return "Password must be at least 8 characters long."
    if not re.search(r'[A-Z]', password):
        return "Password must contain at least one uppercase letter."
    if not re.search(r'\d', password):
        return "Password must contain at least one number."
    if not re.search(r'[!@#$%^&*()\-_=+\[\]{}|;:\'",.<>?/`~\\]', password):
        return "Password must contain at least one special character (!@#$%^&* etc.)."
    return None


def _validate_email(email: str) -> bool:
    """Basic email format validation."""
    pattern = r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


# ── Register ─────────────────────────────────────────────────────────────────

@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Create a new user account.

    Body: {
        "username": str,
        "email": str,
        "password": str,
        "role": str  (optional: "analyst" | "admin", default: "analyst"),
        "admin_code": str  (required only when role == "admin")
    }
    Returns: 201 with user info, or 400/409 on validation error.
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'Request body must be JSON.'}), 400

    username   = (data.get('username')   or '').strip()
    email      = (data.get('email')      or '').strip().lower()
    password   =  data.get('password')   or ''
    role       = (data.get('role')       or 'analyst').strip().lower()
    admin_code =  data.get('admin_code') or ''

    # ── Field presence ────────────────────────────────────────────────────────
    if not username or not email or not password:
        return jsonify({'error': 'username, email and password are all required.'}), 400

    # ── Role validation ───────────────────────────────────────────────────────
    if role not in ('analyst', 'admin'):
        return jsonify({'error': 'role must be either "analyst" or "admin".'}), 400

    if role == 'admin':
        expected_code = current_app.config.get('ADMIN_REGISTRATION_CODE', '')
        if not admin_code or admin_code != expected_code:
            return jsonify({'error': 'Invalid admin registration code.'}), 403

    # ── Username length ───────────────────────────────────────────────────────
    if len(username) < 3 or len(username) > 80:
        return jsonify({'error': 'Username must be between 3 and 80 characters.'}), 400

    # ── Email format ──────────────────────────────────────────────────────────
    if not _validate_email(email):
        return jsonify({'error': 'Invalid email format.'}), 400

    # ── Password strength ─────────────────────────────────────────────────────
    pwd_error = _validate_password(password)
    if pwd_error:
        return jsonify({'error': pwd_error}), 400

    # ── Uniqueness ────────────────────────────────────────────────────────────
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'An account with this email already exists.'}), 409
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'This username is already taken.'}), 409

    # ── Create user ───────────────────────────────────────────────────────────
    user = User(username=username, email=email, role=role)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return jsonify({
        'message': f'Account created successfully as {role}.',
        'user': user.to_dict(),
    }), 201


# ── Login ─────────────────────────────────────────────────────────────────────

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Authenticate a user and issue JWT access + refresh tokens.

    Body: { "email": str, "password": str }
    Returns: 200 with tokens + user info, or 401 on failure.
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'Request body must be JSON.'}), 400

    email    = (data.get('email')    or '').strip().lower()
    password =  data.get('password') or ''

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    user = User.query.filter_by(email=email).first()

    # Use the same error for both "not found" and "wrong password" to
    # prevent user enumeration attacks.
    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid email or password.'}), 401

    if not user.is_active:
        return jsonify({'error': 'This account has been deactivated. Contact an administrator.'}), 403

    # Update last login timestamp
    user.last_login = datetime.utcnow()
    db.session.commit()

    # Issue tokens — identity is the user's integer ID (string form required by flask-jwt)
    identity = str(user.id)
    access_token  = create_access_token(identity=identity)
    refresh_token = create_refresh_token(identity=identity)

    return jsonify({
        'access_token':  access_token,
        'refresh_token': refresh_token,
        'user': user.to_dict(),
    }), 200


# ── Refresh Access Token ──────────────────────────────────────────────────────

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """
    Issue a new access token using a valid refresh token.
    The refresh token must be sent in the Authorization header.

    Returns: 200 with new access_token.
    """
    identity = get_jwt_identity()
    new_access_token = create_access_token(identity=identity)
    return jsonify({'access_token': new_access_token}), 200


# ── Current User Profile ──────────────────────────────────────────────────────

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    """
    Return the currently authenticated user's profile.
    Returns: 200 with user dict.
    """
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found.'}), 404
    return jsonify({'user': user.to_dict()}), 200


# ── Change Password ───────────────────────────────────────────────────────────

@auth_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    """
    Change the authenticated user's password.

    Body: { "current_password": str, "new_password": str }
    Returns: 200 on success, 400/401 on failure.
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'Request body must be JSON.'}), 400

    current_password = data.get('current_password') or ''
    new_password     = data.get('new_password')     or ''

    if not current_password or not new_password:
        return jsonify({'error': 'current_password and new_password are required.'}), 400

    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    if not user.check_password(current_password):
        return jsonify({'error': 'Current password is incorrect.'}), 401

    pwd_error = _validate_password(new_password)
    if pwd_error:
        return jsonify({'error': pwd_error}), 400

    user.set_password(new_password)
    db.session.commit()

    return jsonify({'message': 'Password changed successfully.'}), 200


# ── Password Reset — Request ──────────────────────────────────────────────────

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password_request():
    """
    Request a password reset. Generates a time-limited reset token.

    Body: { "email": str }
    Returns: 200 with reset_token (in production this would be emailed).

    Note: Always returns 200 even if email not found, to prevent enumeration.
    """
    data = request.get_json(silent=True)
    email = (data.get('email') or '').strip().lower() if data else ''

    user = User.query.filter_by(email=email).first()
    if not user:
        # Return 200 with a generic message — don't reveal if email exists
        return jsonify({'message': 'If that email is registered, a reset token has been generated.'}), 200

    # Generate a secure random token valid for 1 hour
    token = secrets.token_urlsafe(32)
    _reset_tokens[token] = {
        'user_id':    user.id,
        'expires_at': datetime.utcnow() + timedelta(hours=1),
    }

    return jsonify({
        'message':     'Password reset token generated. Use it within 1 hour.',
        'reset_token': token,   # In production: send this via email, not in response
    }), 200


# ── Password Reset — Confirm ──────────────────────────────────────────────────

@auth_bp.route('/reset-password/confirm', methods=['POST'])
def reset_password_confirm():
    """
    Confirm a password reset using the token from /reset-password.

    Body: { "reset_token": str, "new_password": str }
    Returns: 200 on success, 400 on expired/invalid token.
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'Request body must be JSON.'}), 400

    reset_token  = data.get('reset_token')  or ''
    new_password = data.get('new_password') or ''

    if not reset_token or not new_password:
        return jsonify({'error': 'reset_token and new_password are required.'}), 400

    # Look up the token
    token_data = _reset_tokens.get(reset_token)
    if not token_data:
        return jsonify({'error': 'Invalid or expired reset token.'}), 400

    if datetime.utcnow() > token_data['expires_at']:
        _reset_tokens.pop(reset_token, None)
        return jsonify({'error': 'Reset token has expired. Please request a new one.'}), 400

    # Validate new password
    pwd_error = _validate_password(new_password)
    if pwd_error:
        return jsonify({'error': pwd_error}), 400

    # Apply the new password
    user = User.query.get(token_data['user_id'])
    if not user:
        return jsonify({'error': 'User not found.'}), 404

    user.set_password(new_password)
    db.session.commit()

    # Invalidate the used token
    _reset_tokens.pop(reset_token, None)

    return jsonify({'message': 'Password reset successfully. You can now log in.'}), 200
