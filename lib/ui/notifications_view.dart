import 'package:flutter/material.dart';
import '../models/notification_entry.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';

class NotificationsView extends StatefulWidget {
  final MacDroidState state;

  const NotificationsView({super.key, required this.state});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final Map<String, TextEditingController> _replyControllers = {};
  final Set<String> _expandedReplyIds = {};

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getReplyController(String id) {
    return _replyControllers.putIfAbsent(id, () => TextEditingController());
  }

  void _showSimulateDialog() {
    final titleCtrl = TextEditingController(text: 'Incoming Message');
    final bodyCtrl = TextEditingController(text: 'Hey! Are we meeting for coffee today?');
    String appName = 'WhatsApp';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Simulate Incoming Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: appName,
                decoration: const InputDecoration(labelText: 'Source App'),
                items: const [
                  DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'Slack', child: Text('Slack')),
                  DropdownMenuItem(value: 'Telegram', child: Text('Telegram')),
                  DropdownMenuItem(value: 'Messages', child: Text('SMS / RCS')),
                  DropdownMenuItem(value: 'Instagram', child: Text('Instagram')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => appName = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title / Sender'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Notification Body'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.state.notificationSync.postSimulatedNotification(
                  appName: appName,
                  appPackage: 'com.${appName.toLowerCase()}.app',
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  hasReply: true,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Simulate Push'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifs = widget.state.notifications;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notification Center',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${notifs.length} active',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bidirectional notification sync • Inline replies • Mirrored from phone',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_alert_rounded, size: 16),
                      label: const Text('Simulate Push'),
                      onPressed: _showSimulateDialog,
                    ),
                    if (notifs.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Clear All'),
                        onPressed: () => widget.state.notificationSync.clearAll(),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notification Feed
            Expanded(
              child: notifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHover,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 40,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Notifications',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Notifications received on your mobile device will appear here in real time.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_alert_rounded, size: 16),
                            label: const Text('Simulate Sample Notification'),
                            onPressed: _showSimulateDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        final notif = notifs[index];
                        final isReplying = _expandedReplyIds.contains(notif.id);
                        final controller = _getReplyController(notif.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: App icon, name, timestamp, dismiss
                                Row(
                                  children: [
                                    _buildAppBadge(notif.appName),
                                    const SizedBox(width: 10),
                                    Text(
                                      notif.appName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${_formatTimeAgo(notif.timestamp)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      color: AppTheme.textMuted,
                                      tooltip: 'Dismiss from phone',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        widget.state.notificationSync.dismissNotification(notif.id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Title & Body
                                Text(
                                  notif.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),

                                // Feedback subtext if present
                                if (notif.subText != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      notif.subText!,
                                      style: const TextStyle(
                                        color: AppTheme.emerald,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],

                                // Reply action button & Inline Reply Composer
                                if (notif.hasReplyAction) ...[
                                  const SizedBox(height: 12),
                                  if (!isReplying)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.reply_rounded, size: 14),
                                        label: const Text('Quick Reply'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () {
                                          setState(() => _expandedReplyIds.add(notif.id));
                                        },
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: 'Reply to ${notif.title}...',
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                            ),
                                            onSubmitted: (text) {
                                              if (text.trim().isNotEmpty) {
                                                widget.state.notificationSync.sendReply(notif.id, text.trim());
                                                controller.clear();
                                                setState(() => _expandedReplyIds.remove(notif.id));
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton.filled(
                                          icon: const Icon(Icons.send_rounded, size: 16),
                                          onPressed: () {
                                            final text = controller.text.trim();
                                            if (text.isNotEmpty) {
                                              widget.state.notificationSync.sendReply(notif.id, text);
                                              controller.clear();
                                              setState(() => _expandedReplyIds.remove(notif.id));
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            setState(() => _expandedReplyIds.remove(notif.id));
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBadge(String appName) {
    IconData icon = Icons.chat_bubble_outline_rounded;
    Color color = AppTheme.primary;

    final lower = appName.toLowerCase();
    if (lower.contains('whatsapp')) {
      icon = Icons.chat_rounded;
      color = const Color(0xFF25D366);
    } else if (lower.contains('slack')) {
      icon = Icons.work_rounded;
      color = const Color(0xFFE01E5A);
    } else if (lower.contains('calendar')) {
      icon = Icons.calendar_today_rounded;
      color = const Color(0xFF4285F4);
    } else if (lower.contains('telegram')) {
      icon = Icons.send_rounded;
      color = const Color(0xFF0088CC);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
