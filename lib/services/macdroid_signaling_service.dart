import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnMessageReceived = void Function(Map<String, dynamic> message);
typedef OnConnectionStateChanged = void Function(bool isConnected);

class MacdroidSignalingService {
  final String deviceId;
  final String deviceName;
  final String platform;
  final OnMessageReceived onMessage;
  final OnConnectionStateChanged onStateChanged;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  String? _currentSessionId;

  MacdroidSignalingService({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.onMessage,
    required this.onStateChanged,
  });

  bool get isConnected => _isConnected;
  String? get currentSessionId => _currentSessionId;

  // Connect to signaling endpoint
  Future<void> connect(String wsUrl, {String? joinSessionId}) async {
    disconnect();
    _currentSessionId = joinSessionId;

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (data) {
          if (!_isConnected) {
            _isConnected = true;
            onStateChanged(true);
            _startHeartbeat();
          }

          try {
            final parsed = jsonDecode(data.toString());
            if (parsed is Map<String, dynamic>) {
              onMessage(parsed);
            }
          } catch (_) {}
        },
        onError: (err) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Send initial register / join room message
      sendRaw({
        'type': 'REGISTER',
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'sessionId': joinSessionId,
      });
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isConnected) {
        sendRaw({'type': 'PING', 'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  void sendRaw(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (_) {}
    }
  }

  void sendPeerMessage(Map<String, dynamic> message, {String? targetDeviceId}) {
    sendRaw({
      'type': 'FORWARD',
      'targetDeviceId': targetDeviceId,
      'payload': message,
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    onStateChanged(false);
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _handleDisconnect();
  }
}
