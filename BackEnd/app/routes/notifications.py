"""
API routes for notifications.
"""
from flask import Blueprint, jsonify, request
from app.extensions import db
from app.models.notification import Notification

notifications_bp = Blueprint('notifications', __name__)


@notifications_bp.route("", methods=["GET"])
def get_notifications():
    """
    Get recent notifications (newest first).
    Query params: limit (default 20), unread_only (default false)
    """
    limit = request.args.get('limit', 20, type=int)
    unread_only = request.args.get('unread_only', 'false').lower() == 'true'

    query = Notification.query

    if unread_only:
        query = query.filter_by(is_read=False)

    notifications = query.order_by(
        Notification.created_at.desc()
    ).limit(limit).all()

    return jsonify({
        "notifications": [n.to_dict() for n in notifications],
        "count": len(notifications)
    }), 200


@notifications_bp.route("/unread-count", methods=["GET"])
def get_unread_count():
    """Get the number of unread notifications (for badge)."""
    count = Notification.query.filter_by(is_read=False).count()
    return jsonify({"count": count}), 200


@notifications_bp.route("/<int:notification_id>/read", methods=["PATCH"])
def mark_as_read(notification_id):
    """Mark a single notification as read."""
    notif = Notification.query.get_or_404(notification_id)
    notif.is_read = True
    db.session.commit()
    return jsonify(notif.to_dict()), 200


@notifications_bp.route("/read-all", methods=["PATCH"])
def mark_all_as_read():
    """Mark all notifications as read."""
    updated = Notification.query.filter_by(is_read=False).update({"is_read": True})
    db.session.commit()
    return jsonify({"message": f"Marked {updated} notifications as read"}), 200
