import 'package:flutter/foundation.dart';
import '../models/screen_mirror_models.dart';
import '../protocols/macdroid_protocol.dart';

class ScreenMirrorService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  bool _isStreaming = false;
  bool _isPrivacyBlanked = false;
  int _fps = 30;
  int _quality = 80;
  ScreenFrameMessage? _currentFrame;
  String? _lastInjectedEvent;

  ScreenMirrorService({
    required this.sendMessage,
    required this.onStateUpdated,
  });

  bool get isStreaming => _isStreaming;
  bool get isPrivacyBlanked => _isPrivacyBlanked;
  int get fps => _fps;
  int get quality => _quality;
  ScreenFrameMessage? get currentFrame => _currentFrame;
  String? get lastInjectedEvent => _lastInjectedEvent;

  void startMirroring({int fps = 30, int quality = 80}) {
    _isStreaming = true;
    _fps = fps;
    _quality = quality;
    sendMessage(MacDroidProtocol.createScreenStart(fps: fps, quality: quality));
    onStateUpdated();
  }

  void stopMirroring() {
    _isStreaming = false;
    _currentFrame = null;
    sendMessage(MacDroidProtocol.createScreenStop());
    onStateUpdated();
  }

  void togglePrivacyBlank(bool enabled) {
    _isPrivacyBlanked = enabled;
    sendMessage(MacDroidProtocol.createPrivacyScreenToggle(enabled));
    onStateUpdated();
  }

  void sendTouch({
    required String action,
    required double xRatio,
    required double yRatio,
  }) {
    final event = TouchInputEvent(
      action: action,
      xRatio: xRatio.clamp(0.0, 1.0),
      yRatio: yRatio.clamp(0.0, 1.0),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _lastInjectedEvent = 'Touch $action at (${(xRatio * 100).toStringAsFixed(0)}%, ${(yRatio * 100).toStringAsFixed(0)}%)';
    sendMessage(MacDroidProtocol.createInputTouch(event));
    onStateUpdated();
  }

  void sendNavigation(String action) {
    _lastInjectedEvent = 'Nav: $action';
    sendMessage(MacDroidProtocol.createInputNav(action));
    onStateUpdated();
  }

  void handleIncomingFrame(ScreenFrameMessage frame) {
    _currentFrame = frame;
    onStateUpdated();
  }

  void handleIncomingTouch(TouchInputEvent event) {
    _lastInjectedEvent = 'Received Touch ${event.action} (${(event.xRatio * 100).toStringAsFixed(0)}%, ${(event.yRatio * 100).toStringAsFixed(0)}%)';
    onStateUpdated();
  }

  void handleIncomingNav(String action) {
    _lastInjectedEvent = 'Received Nav: $action';
    onStateUpdated();
  }

  void handleIncomingPrivacyToggle(bool blankEnabled) {
    _isPrivacyBlanked = blankEnabled;
    onStateUpdated();
  }
}
