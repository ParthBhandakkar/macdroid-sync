enum CallType {
  incoming,
  outgoing,
  missed,
}

class CallLogEntry {
  final String id;
  final String phoneNumber;
  final String contactName;
  final CallType type;
  final DateTime timestamp;
  final int durationSeconds;

  const CallLogEntry({
    required this.id,
    required this.phoneNumber,
    required this.contactName,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
    };
  }

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'incoming';
    return CallLogEntry(
      id: json['id'] as String? ?? 'call-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: json['phoneNumber'] as String? ?? 'Unknown',
      contactName: json['contactName'] as String? ?? 'Unknown',
      type: CallType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => CallType.incoming,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }

  String get formattedDuration {
    if (durationSeconds == 0) return '0s';
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }
}

class SmsMessage {
  final String id;
  final String threadId;
  final String sender;
  final String body;
  final DateTime timestamp;
  final bool isFromMe;
  final bool isRead;

  const SmsMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.body,
    required this.timestamp,
    required this.isFromMe,
    this.isRead = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'sender': sender,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFromMe': isFromMe,
      'isRead': isRead,
    };
  }

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] as String? ?? 'sms-${DateTime.now().millisecondsSinceEpoch}',
      threadId: json['threadId'] as String? ?? 'thread-1',
      sender: json['sender'] as String? ?? 'Sender',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      isFromMe: json['isFromMe'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? true,
    );
  }
}

class SmsConversation {
  final String threadId;
  final String contactName;
  final String phoneNumber;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  const SmsConversation({
    required this.threadId,
    required this.contactName,
    required this.phoneNumber,
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  factory SmsConversation.fromJson(Map<String, dynamic> json) {
    return SmsConversation(
      threadId: json['threadId'] as String? ?? 'thread-1',
      contactName: json['contactName'] as String? ?? 'Unknown',
      phoneNumber: json['phoneNumber'] as String? ?? 'Unknown',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastTimestamp: json['lastTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastTimestamp'] as int)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
