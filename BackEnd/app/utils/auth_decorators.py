"""
Custom authentication decorators for role-based access control.
Use @admin_required for endpoints that only admins can access.
"""
import functools
from flask import jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.user import User


def admin_required(fn):
    """
    Decorator: only users with role='admin' can access this endpoint.
    Combines @jwt_required() + admin role check.

    Usage:
        @cases_bp.route('/delete/<int:id>', methods=['DELETE'])
        @admin_required
        def delete_case(id):
            ...
    """
    @functools.wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found.'}), 404
        if user.role != 'admin':
            return jsonify({'error': 'Admin access required.'}), 403
        return fn(*args, **kwargs)
    return wrapper


def active_user_required(fn):
    """
    Decorator: jwt_required + checks the user's is_active flag.
    Rejects requests from deactivated accounts even with a valid token.
    """
    @functools.wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)
        if not user or not user.is_active:
            return jsonify({'error': 'Account is deactivated.'}), 403
        return fn(*args, **kwargs)
    return wrapper
