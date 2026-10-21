import 'package:flutter/material.dart';
import '../models/telephony_models.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';

class CallsAndSmsView extends StatefulWidget {
  final MacDroidState state;

  const CallsAndSmsView({super.key, required this.state});

  @override
  State<CallsAndSmsView> createState() => _CallsAndSmsViewState();
}

class _CallsAndSmsViewState extends State<CallsAndSmsView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _dialNumberCtrl = TextEditingController();
  final TextEditingController _smsMessageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dialNumberCtrl.dispose();
    _smsMessageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar & Tab Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Calls & Messaging Hub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bluetooth HFP audio telephony • SMS/RCS thread sync • Remote dialer',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    tabs: const [
                      Tab(text: 'Phone & Calls', icon: Icon(Icons.phone_rounded, size: 16)),
                      Tab(text: 'Messages (SMS/RCS)', icon: Icon(Icons.chat_bubble_rounded, size: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCallsTab(),
                  _buildMessagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Calls & Dialer Tab ====================

  Widget _buildCallsTab() {
    final calls = widget.state.calls;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final dialerWidget = Container(
          width: isWide ? 320 : double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dialNumberCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    onPressed: () {
                      final t = _dialNumberCtrl.text;
                      if (t.isNotEmpty) {
                        _dialNumberCtrl.text = t.substring(0, t.length - 1);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Keypad grid
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['*', '0', '#'],
              ]) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((d) => _buildKeypadButton(d)).toList(),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Start Phone Call'),
                  onPressed: () {
                    final num = _dialNumberCtrl.text.trim();
                    if (num.isNotEmpty) {
                      widget.state.telephonyService.dialCall(num);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dialing $num on remote device...'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );

        final callHistoryWidget = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Call History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: calls.isEmpty
                    ? const Center(child: Text('No call history found'))
                    : ListView.builder(
                        itemCount: calls.length,
                        itemBuilder: (context, index) {
                          final call = calls[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _callColor(call.type).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_callIcon(call.type), color: _callColor(call.type), size: 16),
                              ),
                              title: Text(call.contactName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${call.phoneNumber} • ${call.formattedDuration}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              trailing: Text(_formatDate(call.timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              onTap: () {
                                _dialNumberCtrl.text = call.phoneNumber;
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dialerWidget,
              const SizedBox(width: 20),
              Expanded(child: callHistoryWidget),
            ],
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                dialerWidget,
                const SizedBox(height: 16),
                SizedBox(height: 380, child: callHistoryWidget),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        _dialNumberCtrl.text = _dialNumberCtrl.text + digit;
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHover,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _callColor(CallType type) {
    switch (type) {
      case CallType.incoming:
        return AppTheme.emerald;
      case CallType.outgoing:
        return AppTheme.accent;
      case CallType.missed:
        return AppTheme.rose;
    }
  }

  IconData _callIcon(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
    }
  }

  // ==================== Messages (SMS/RCS) Tab ====================

  Widget _buildMessagesTab() {
    final threads = widget.state.smsConversations;
    final activeMessages = widget.state.activeSmsMessages;
    final activeThreadId = widget.state.telephonyService.activeThreadId;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left: Conversations list
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.message_rounded, size: 16, color: AppTheme.accent),
                      SizedBox(width: 8),
                      Text('Conversations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      final isSelected = thread.threadId == activeThreadId;

                      return InkWell(
                        onTap: () {
                          widget.state.telephonyService.selectThread(thread.threadId);
                        },
                        child: Container(
                          color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    thread.contactName,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(thread.lastTimestamp),
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                thread.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
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

          const VerticalDivider(width: 1, color: AppTheme.border),

          // Right: Active Conversation
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.surfaceHover,
                        child: Icon(Icons.person, size: 18, color: AppTheme.accent),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            threads.firstWhere((t) => t.threadId == activeThreadId, orElse: () => threads.first).contactName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const Text('SMS / RCS via Paired Phone', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = activeMessages[index];
                      final isMe = msg.isFromMe;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 380),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : AppTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.body,
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppTheme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(msg.timestamp),
                                style: TextStyle(
                                  color: isMe ? Colors.white60 : AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // SMS Input bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _smsMessageCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Type text message (SMS)...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (text) => _sendCurrentSms(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded, size: 18),
                        onPressed: _sendCurrentSms,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendCurrentSms() {
    final text = _smsMessageCtrl.text.trim();
    if (text.isEmpty) return;
    final activeThread = widget.state.smsConversations.firstWhere(
      (t) => t.threadId == widget.state.telephonyService.activeThreadId,
      orElse: () => widget.state.smsConversations.first,
    );
    widget.state.telephonyService.sendSms(activeThread.phoneNumber, text);
    _smsMessageCtrl.clear();
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
