import 'package:backpackr/features/chat/models/notification_item.dart';
import 'package:flutter/foundation.dart';

class NotificationController extends ChangeNotifier {
  final List<NotificationItem> notifications = [];

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  bool get hasUnread =>
      notifications.any((notification) => !notification.isRead);

  void markAsRead(String id) {
    final index = notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;

    notifications[index] = notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  bool markAllAsRead() {
    if (!hasUnread) return false;

    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    return true;
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'MESSAGE';
      case NotificationType.sale:
        return 'SALE';
      case NotificationType.offer:
        return 'OFFER';
      case NotificationType.system:
        return 'SYSTEM';
      case NotificationType.social:
        return 'SOCIAL';
    }
  }
}
