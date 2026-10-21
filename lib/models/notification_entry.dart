class NotificationEntry {
  final String id;
  final String appPackage;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? subText;
  final bool hasReplyAction;
  final bool isDismissed;

  const NotificationEntry({
    required this.id,
    required this.appPackage,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.subText,
    this.hasReplyAction = true,
    this.isDismissed = false,
  });

  NotificationEntry copyWith({
    String? id,
    String? appPackage,
    String? appName,
    String? title,
    String? body,
    DateTime? timestamp,
    String? subText,
    bool? hasReplyAction,
    bool? isDismissed,
  }) {
    return NotificationEntry(
      id: id ?? this.id,
      appPackage: appPackage ?? this.appPackage,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      subText: subText ?? this.subText,
      hasReplyAction: hasReplyAction ?? this.hasReplyAction,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appPackage': appPackage,
      'appName': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'subText': subText,
      'hasReplyAction': hasReplyAction,
      'isDismissed': isDismissed,
    };
  }

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'] as String? ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
      appPackage: json['appPackage'] as String? ?? 'com.android.system',
      appName: json['appName'] as String? ?? 'System',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      subText: json['subText'] as String?,
      hasReplyAction: json['hasReplyAction'] as bool? ?? true,
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}
