import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          const AppSidebar(currentRoute: '/notifications'),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Notifications',
                  subtitle: 'Case analysis events and alerts',
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;

        return Column(
          children: [
            // Header with mark all read
            _buildHeader(provider),
            const Divider(color: Color(0xFF1E293B), height: 1),
            // Notification list
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Color(0xFF1E293B),
                        height: 1,
                        indent: 72,
                      ),
                      itemBuilder: (context, index) => _buildNotificationItem(
                        notifications[index],
                        provider,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: provider.unreadCount > 0
                  ? const Color(0xFF00D9FF).withOpacity(0.1)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.unreadCount} unread',
              style: TextStyle(
                color: provider.unreadCount > 0
                    ? const Color(0xFF00D9FF)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all as read'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00D9FF),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => provider.fetchNotifications(),
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 20),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: const Color(0xFF64748B).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a memory dump to get started',
            style: TextStyle(color: Color(0xFF475569), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final icon = _getIcon(notification.type);
    final iconColor = _getColor(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          provider.markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: notification.isRead
            ? Colors.transparent
            : const Color(0xFF00D9FF).withOpacity(0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'case_completed':
        return Icons.check_circle_rounded;
      case 'case_failed':
        return Icons.error_rounded;
      case 'case_processing':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'case_completed':
        return const Color(0xFF10B981); // green
      case 'case_failed':
        return const Color(0xFFEF4444); // red
      case 'case_processing':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
