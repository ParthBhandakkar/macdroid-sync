import 'package:flutter/foundation.dart';
import '../models/notification_entry.dart';
import '../protocols/macdroid_protocol.dart';

class NotificationSyncService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  final List<NotificationEntry> _notifications = [];

  NotificationSyncService({
    required this.sendMessage,
    required this.onStateUpdated,
  }) {
    _populateDefaultNotifications();
  }

  List<NotificationEntry> get notifications =>
      _notifications.where((n) => !n.isDismissed).toList();

  List<NotificationEntry> get allHistory => List.unmodifiable(_notifications);

  void handleIncomingNotification(NotificationEntry entry) {
    final idx = _notifications.indexWhere((n) => n.id == entry.id);
    if (idx >= 0) {
      _notifications[idx] = entry;
    } else {
      _notifications.insert(0, entry);
    }
    onStateUpdated();
  }

  void handleIncomingDismiss(String notificationId) {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isDismissed: true);
      onStateUpdated();
    }
  }

  void dismissNotification(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isDismissed: true);
      sendMessage(MacDroidProtocol.createNotificationDismissed(id));
      onStateUpdated();
    }
  }

  void clearAll() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isDismissed) {
        _notifications[i] = _notifications[i].copyWith(isDismissed: true);
        sendMessage(MacDroidProtocol.createNotificationDismissed(_notifications[i].id));
      }
    }
    onStateUpdated();
  }

  void sendReply(String notificationId, String replyText) {
    if (replyText.trim().isEmpty) return;
    sendMessage(MacDroidProtocol.createNotificationReply(
      notificationId: notificationId,
      replyText: replyText,
    ));
    // Also append feedback locally
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      final old = _notifications[idx];
      _notifications[idx] = old.copyWith(
        subText: 'Replied: "$replyText"',
      );
      onStateUpdated();
    }
  }

  void postSimulatedNotification({
    required String appName,
    required String appPackage,
    required String title,
    required String body,
    bool hasReply = true,
  }) {
    final notif = NotificationEntry(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      appName: appName,
      appPackage: appPackage,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      hasReplyAction: hasReply,
    );
    _notifications.insert(0, notif);
    sendMessage(MacDroidProtocol.createNotificationPosted(notif));
    onStateUpdated();
  }

  void _populateDefaultNotifications() {
    _notifications.addAll([
      NotificationEntry(
        id: 'n-wa-1',
        appName: 'WhatsApp',
        appPackage: 'com.whatsapp',
        title: 'Alex Miller',
        body: 'Hey! Are you still joining the design review meeting at 3 PM?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        hasReplyAction: true,
      ),
      NotificationEntry(
        id: 'n-slack-1',
        appName: 'Slack',
        appPackage: 'com.Slack',
        title: '#eng-architecture',
        body: 'Merged PR #142: P2P WebRTC chunk streaming protocol upgraded to 64KB.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        hasReplyAction: true,
      ),
      NotificationEntry(
        id: 'n-cal-1',
        appName: 'Google Calendar',
        appPackage: 'com.google.android.calendar',
        title: 'Sprint Planning (in 15 mins)',
        body: 'Conference Room B / Google Meet link attached',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        hasReplyAction: false,
      ),
    ]);
  }
}
