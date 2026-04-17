import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/notification_model.dart';

/// API client for notification endpoints.
class NotificationsApiRoutes {
  static const String _baseUrl = '${ApiConfig.baseUrl}/api/notifications';

  /// Get recent notifications.
  static Future<List<NotificationModel>> getNotifications({
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    }
    throw Exception('Failed to fetch notifications: ${response.statusCode}');
  }

  /// Get unread notification count (for badge).
  static Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/unread-count'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] as int;
    }
    throw Exception('Failed to fetch unread count: ${response.statusCode}');
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead(int notificationId) async {
    await http.patch(
      Uri.parse('$_baseUrl/$notificationId/read'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    await http.patch(
      Uri.parse('$_baseUrl/read-all'),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
