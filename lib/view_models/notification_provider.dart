import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../api-routes/notifications/notifications_api_routes.dart';
import '../models/notification_model.dart';

/// ChangeNotifier that:
/// - Listens to WebSocket for real-time case_update events
/// - Fetches notifications from backend API
/// - Drives dashboard status updates + bell icon badge
class NotificationProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  // Case status map for real-time dashboard updates
  final Map<String, String> _caseStatuses = {};

  // Notification data from API
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  NotificationProvider() {
    _socketService.addListener(_onCaseUpdate);
    _socketService.connect();
    fetchUnreadCount();
  }

  Map<String, String> get caseStatuses => Map.unmodifiable(_caseStatuses);
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  /// Called when a WebSocket case_update event arrives.
  void _onCaseUpdate(Map<String, dynamic> event) {
    final caseId = event['case_id'];
    final String caseIdStr = caseId?.toString() ?? '';
    final status = event['status'] as String?;

    if (caseIdStr.isEmpty || status == null) return;

    // Update status map for dashboard
    _caseStatuses[caseIdStr] = status;

    // Refresh unread count since a new notification was created
    fetchUnreadCount();

    notifyListeners();
  }

  /// Fetch unread count from API (for badge).
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await NotificationsApiRoutes.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch unread count: $e');
    }
  }

  /// Fetch full notification list from API.
  Future<void> fetchNotifications({int limit = 50}) async {
    try {
      _notifications = await NotificationsApiRoutes.getNotifications(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      print('Failed to fetch notifications: $e');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    try {
      await NotificationsApiRoutes.markAsRead(notificationId);
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await NotificationsApiRoutes.markAllAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  @override
  void dispose() {
    _socketService.removeListener(_onCaseUpdate);
    super.dispose();
  }
}
