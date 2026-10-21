import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';
import '../models/peer_device.dart';

class ClipboardSyncView extends StatefulWidget {
  final MacDroidState state;

  const ClipboardSyncView({super.key, required this.state});

  @override
  State<ClipboardSyncView> createState() => _ClipboardSyncViewState();
}

class _ClipboardSyncViewState extends State<ClipboardSyncView> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.state.clipboardHistory;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Universal Clipboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seamless real-time copy and paste between macOS, Windows, and Android',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                // Auto-sync Toggle Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.state.isAutoClipboardEnabled
                              ? AppTheme.emerald
                              : AppTheme.textMuted,
                          boxShadow: widget.state.isAutoClipboardEnabled
                              ? [
                                  BoxShadow(
                                    color: AppTheme.emerald.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.state.isAutoClipboardEnabled ? 'Auto-Sync Active' : 'Auto-Sync Paused',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: widget.state.isAutoClipboardEnabled,
                        activeColor: AppTheme.accent,
                        onChanged: (val) {
                          widget.state.toggleAutoClipboard(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Push Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Type or paste text to broadcast to all paired devices...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Broadcast'),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        widget.state.pushClipboardText(text);
                        _textController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pushed to paired devices!'),
                            backgroundColor: AppTheme.primary,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Synchronized Clipboard History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // History List
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_paste_off, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No clipboard items yet',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Copy text anywhere on your Mac, Windows PC, or Android phone to see it appear here.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final isLocal = item.originDeviceId == widget.state.localDeviceId;
                        final timeStr = DateFormat('HH:mm:ss').format(item.timestamp);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLocal ? AppTheme.border : AppTheme.primary.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Origin Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLocal ? AppTheme.surfaceHover : AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLocal ? Icons.devices : Icons.phone_android,
                                      size: 14,
                                      color: isLocal ? AppTheme.textMuted : AppTheme.accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isLocal ? 'This Device' : item.originDeviceName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLocal ? AppTheme.textSecondary : AppTheme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      item.text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Synced at $timeStr',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: AppTheme.textSecondary),
                                tooltip: 'Copy to Local Clipboard',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item.text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
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
}
