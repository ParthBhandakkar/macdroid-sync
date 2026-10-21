import 'package:flutter/foundation.dart';
import '../models/device_telemetry.dart';
import '../protocols/macdroid_protocol.dart';

class DeviceTelemetryService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  DeviceTelemetry _telemetry = DeviceTelemetry.mock();
  String? _lastAlertMessage;

  DeviceTelemetryService({
    required this.sendMessage,
    required this.onStateUpdated,
  });

  DeviceTelemetry get telemetry => _telemetry;
  String? get lastAlertMessage => _lastAlertMessage;

  void handleIncomingTelemetry(Map<String, dynamic> data) {
    _telemetry = DeviceTelemetry.fromJson(data);
    onStateUpdated();
  }

  void handleIncomingCommand(String command, dynamic value) {
    switch (command) {
      case 'toggle_hotspot':
        _telemetry = _telemetry.copyWith(
          isHotspotOn: !(_telemetry.isHotspotOn),
          lastUpdated: DateTime.now(),
        );
        broadcastCurrentState();
        break;
      case 'toggle_dnd':
        _telemetry = _telemetry.copyWith(
          isDoNotDisturb: !(_telemetry.isDoNotDisturb),
          lastUpdated: DateTime.now(),
        );
        broadcastCurrentState();
        break;
      case 'set_ringer':
        if (value is String) {
          _telemetry = _telemetry.copyWith(
            ringerMode: value,
            lastUpdated: DateTime.now(),
          );
          broadcastCurrentState();
        }
        break;
      case 'find_my_phone':
        _lastAlertMessage = '🔊 Remote Phone is ringing at full volume!';
        onStateUpdated();
        break;
    }
    onStateUpdated();
  }

  void setHotspot(bool enabled) {
    _telemetry = _telemetry.copyWith(isHotspotOn: enabled, lastUpdated: DateTime.now());
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'toggle_hotspot',
      value: enabled,
    ));
    onStateUpdated();
  }

  void toggleHotspot([bool? enabled]) {
    setHotspot(enabled ?? !_telemetry.isHotspotOn);
  }

  void setDoNotDisturb(bool enabled) {
    _telemetry = _telemetry.copyWith(isDoNotDisturb: enabled, lastUpdated: DateTime.now());
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'toggle_dnd',
      value: enabled,
    ));
    onStateUpdated();
  }

  void toggleDoNotDisturb([bool? enabled]) {
    setDoNotDisturb(enabled ?? !_telemetry.isDoNotDisturb);
  }

  void setRingerMode(String mode) {
    _telemetry = _telemetry.copyWith(ringerMode: mode, lastUpdated: DateTime.now());
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'set_ringer',
      value: mode,
    ));
    onStateUpdated();
  }

  void triggerFindMyPhone() {
    _lastAlertMessage = '🔊 Ring command sent to remote phone';
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'find_my_phone',
    ));
    onStateUpdated();
  }

  void clearAlert() {
    _lastAlertMessage = null;
    onStateUpdated();
  }

  void broadcastCurrentState() {
    sendMessage(MacDroidProtocol.createTelemetryUpdate(_telemetry));
  }
}
