import 'dart:convert';
import 'package:crypto/crypto.dart';

class ClipboardEntry {
  final String id;
  final String text;
  final String originDeviceId;
  final String originDeviceName;
  final DateTime timestamp;
  final String hash;

  ClipboardEntry({
    required this.id,
    required this.text,
    required this.originDeviceId,
    required this.originDeviceName,
    required this.timestamp,
    String? hash,
  }) : hash = hash ?? sha256.convert(utf8.encode(text)).toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'originDeviceId': originDeviceId,
    'originDeviceName': originDeviceName,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'hash': hash,
  };

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) {
    return ClipboardEntry(
      id: json['id'] as String? ?? UniqueKeyString.generate(),
      text: json['text'] as String? ?? '',
      originDeviceId: json['originDeviceId'] as String? ?? 'remote',
      originDeviceName: json['originDeviceName'] as String? ?? 'Device',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      hash: json['hash'] as String?,
    );
  }
}

class UniqueKeyString {
  static int _counter = 0;
  static String generate() {
    _counter++;
    return 'clip-${DateTime.now().millisecondsSinceEpoch}-$_counter';
  }
}
