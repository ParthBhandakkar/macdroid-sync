import 'dart:convert';
import 'dart:math';

class QrPairingPayload {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String signalingUrl;
  final String secretToken;

  const QrPairingPayload({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.signalingUrl,
    required this.secretToken,
  });

  String toEncodedString() {
    final map = {
      's': sessionId,
      'd': deviceId,
      'n': deviceName,
      'p': platform,
      'u': signalingUrl,
      'k': secretToken,
    };
    final jsonStr = jsonEncode(map);
    return 'macdroid://${base64Url.encode(utf8.encode(jsonStr))}';
  }

  static QrPairingPayload? fromEncodedString(String encoded) {
    try {
      String clean = encoded.trim();
      if (clean.startsWith('macdroid://')) {
        clean = clean.substring('macdroid://'.length);
      }
      final decodedJson = utf8.decode(base64Url.decode(clean));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      return QrPairingPayload(
        sessionId: map['s'] as String,
        deviceId: map['d'] as String,
        deviceName: map['n'] as String? ?? 'Peer Device',
        platform: map['p'] as String? ?? 'unknown',
        signalingUrl: map['u'] as String,
        secretToken: map['k'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static String generateShortCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
