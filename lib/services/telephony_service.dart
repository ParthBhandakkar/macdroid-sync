import 'package:flutter/foundation.dart';
import '../models/telephony_models.dart';
import '../protocols/macdroid_protocol.dart';

class TelephonyService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  final List<CallLogEntry> _calls = [];
  final List<SmsConversation> _conversations = [];
  final List<SmsMessage> _messages = [];
  String? _activeThreadId;

  TelephonyService({
    required this.sendMessage,
    required this.onStateUpdated,
  }) {
    _populateDefaultData();
    if (_conversations.isNotEmpty) {
      _activeThreadId = _conversations.first.threadId;
    }
  }

  List<CallLogEntry> get calls => List.unmodifiable(_calls);
  List<SmsConversation> get conversations => List.unmodifiable(_conversations);
  List<SmsMessage> get messages => List.unmodifiable(_messages);
  String? get activeThreadId => _activeThreadId;

  List<SmsMessage> get activeConversationMessages {
    if (_activeThreadId == null) return [];
    return _messages.where((m) => m.threadId == _activeThreadId).toList();
  }

  void selectThread(String threadId) {
    _activeThreadId = threadId;
    onStateUpdated();
  }

  void dialCall(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return;
    sendMessage(MacDroidProtocol.createCallDialRequest(phoneNumber: phoneNumber));

    // Append to local call log as outgoing
    _calls.insert(
      0,
      CallLogEntry(
        id: 'call-${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phoneNumber,
        contactName: _findContactName(phoneNumber),
        type: CallType.outgoing,
        timestamp: DateTime.now(),
        durationSeconds: 0,
      ),
    );
    onStateUpdated();
  }

  void sendSms(String recipient, String text) {
    if (text.trim().isEmpty) return;
    sendMessage(MacDroidProtocol.createSmsSendRequest(
      recipient: recipient,
      text: text,
    ));

    final threadId = _activeThreadId ?? 'thread-${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = SmsMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      sender: 'Me',
      body: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      isRead: true,
    );
    _messages.add(newMsg);

    // Update conversation last message
    final cIdx = _conversations.indexWhere((c) => c.threadId == threadId);
    if (cIdx >= 0) {
      final old = _conversations[cIdx];
      _conversations[cIdx] = SmsConversation(
        threadId: old.threadId,
        contactName: old.contactName,
        phoneNumber: old.phoneNumber,
        lastMessage: text,
        lastTimestamp: DateTime.now(),
        unreadCount: 0,
      );
    } else {
      _conversations.insert(
        0,
        SmsConversation(
          threadId: threadId,
          contactName: recipient,
          phoneNumber: recipient,
          lastMessage: text,
          lastTimestamp: DateTime.now(),
          unreadCount: 0,
        ),
      );
    }
    _activeThreadId = threadId;
    onStateUpdated();
  }

  void handleIncomingCallLog(List<CallLogEntry> calls) {
    _calls.clear();
    _calls.addAll(calls);
    onStateUpdated();
  }

  void handleIncomingSmsList({
    required List<SmsConversation> conversations,
    required List<SmsMessage> messages,
  }) {
    _conversations.clear();
    _conversations.addAll(conversations);
    _messages.clear();
    _messages.addAll(messages);
    if (_activeThreadId == null && _conversations.isNotEmpty) {
      _activeThreadId = _conversations.first.threadId;
    }
    onStateUpdated();
  }

  String _findContactName(String number) {
    final match = _conversations.firstWhere(
      (c) => c.phoneNumber.replaceAll(RegExp(r'\D'), '') == number.replaceAll(RegExp(r'\D'), ''),
      orElse: () => SmsConversation(
        threadId: '',
        contactName: number,
        phoneNumber: number,
        lastMessage: '',
        lastTimestamp: DateTime.now(),
      ),
    );
    return match.contactName;
  }

  void _populateDefaultData() {
    final now = DateTime.now();

    _calls.addAll([
      CallLogEntry(
        id: 'c1',
        phoneNumber: '+1 (555) 234-5678',
        contactName: 'Sarah Connor',
        type: CallType.incoming,
        timestamp: now.subtract(const Duration(minutes: 25)),
        durationSeconds: 142,
      ),
      CallLogEntry(
        id: 'c2',
        phoneNumber: '+1 (555) 987-6543',
        contactName: 'Office Desk',
        type: CallType.missed,
        timestamp: now.subtract(const Duration(hours: 2)),
        durationSeconds: 0,
      ),
      CallLogEntry(
        id: 'c3',
        phoneNumber: '+1 (555) 432-1098',
        contactName: 'David Kim',
        type: CallType.outgoing,
        timestamp: now.subtract(const Duration(hours: 5)),
        durationSeconds: 385,
      ),
      CallLogEntry(
        id: 'c4',
        phoneNumber: '+1 (555) 876-5432',
        contactName: 'Courier Delivery',
        type: CallType.incoming,
        timestamp: now.subtract(const Duration(days: 1)),
        durationSeconds: 45,
      ),
    ]);

    _conversations.addAll([
      SmsConversation(
        threadId: 't1',
        contactName: 'Sarah Connor',
        phoneNumber: '+1 (555) 234-5678',
        lastMessage: 'Let\'s catch up once you are in the office!',
        lastTimestamp: now.subtract(const Duration(minutes: 10)),
        unreadCount: 1,
      ),
      SmsConversation(
        threadId: 't2',
        contactName: 'David Kim',
        phoneNumber: '+1 (555) 432-1098',
        lastMessage: 'Sent the updated slide deck over email.',
        lastTimestamp: now.subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      SmsConversation(
        threadId: 't3',
        contactName: 'Bank Alerts',
        phoneNumber: '22657',
        lastMessage: 'Security code: 849201. Expires in 10 minutes.',
        lastTimestamp: now.subtract(const Duration(hours: 4)),
        unreadCount: 0,
      ),
    ]);

    _messages.addAll([
      SmsMessage(
        id: 'm1',
        threadId: 't1',
        sender: 'Sarah Connor',
        body: 'Morning! Did you finish reviewing the report?',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isFromMe: false,
      ),
      SmsMessage(
        id: 'm2',
        threadId: 't1',
        sender: 'Me',
        body: 'Yes, just pushed all comments to GitHub.',
        timestamp: now.subtract(const Duration(minutes: 20)),
        isFromMe: true,
      ),
      SmsMessage(
        id: 'm3',
        threadId: 't1',
        sender: 'Sarah Connor',
        body: 'Let\'s catch up once you are in the office!',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isFromMe: false,
      ),
      SmsMessage(
        id: 'm4',
        threadId: 't2',
        sender: 'David Kim',
        body: 'Sent the updated slide deck over email.',
        timestamp: now.subtract(const Duration(hours: 1)),
        isFromMe: false,
      ),
      SmsMessage(
        id: 'm5',
        threadId: 't3',
        sender: 'Bank Alerts',
        body: 'Security code: 849201. Expires in 10 minutes.',
        timestamp: now.subtract(const Duration(hours: 4)),
        isFromMe: false,
      ),
    ]);
  }
}
