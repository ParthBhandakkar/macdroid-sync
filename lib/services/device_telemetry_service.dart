import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device_telemetry.dart';
import '../protocols/macdroid_protocol.dart';
import 'native_platform_service.dart';

class DeviceTelemetryService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  DeviceTelemetry _telemetry = DeviceTelemetry.mock();
  String? _lastAlertMessage;
  bool _isAlarmRinging = false;
  Timer? _telemetryTimer;

  DeviceTelemetryService({
    required this.sendMessage,
    required this.onStateUpdated,
  }) {
    _initPlatform();
  }

  DeviceTelemetry get telemetry => _telemetry;
  String? get lastAlertMessage => _lastAlertMessage;
  bool get isAlarmRinging => _isAlarmRinging;

  Future<void> _initPlatform() async {
    if (NativePlatformService.isAndroid) {
      final initial = await NativePlatformService.getRealTelemetry();
      if (initial != null) {
        _telemetry = initial;
        onStateUpdated();
        broadcastCurrentState();
      }

      _telemetryTimer?.cancel();
      _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        final current = await NativePlatformService.getRealTelemetry();
        if (current != null) {
          _telemetry = current;
          broadcastCurrentState();
          onStateUpdated();
        }
      });
    }
  }

  void handleIncomingTelemetry(Map<String, dynamic> data) {
    _telemetry = DeviceTelemetry.fromJson(data);
    onStateUpdated();
  }

  Future<void> handleIncomingCommand(String command, dynamic value) async {
    switch (command) {
      case 'toggle_hotspot':
        _telemetry = _telemetry.copyWith(
          isHotspotOn: !(_telemetry.isHotspotOn),
          lastUpdated: DateTime.now(),
        );
        broadcastCurrentState();
        break;
      case 'toggle_dnd':
        final enable = value is bool ? value : !(_telemetry.isDoNotDisturb);
        if (NativePlatformService.isAndroid) {
          await NativePlatformService.toggleDnd(enable);
          final real = await NativePlatformService.getRealTelemetry();
          if (real != null) {
            _telemetry = real;
          } else {
            _telemetry = _telemetry.copyWith(
              isDoNotDisturb: enable,
              lastUpdated: DateTime.now(),
            );
          }
        } else {
          _telemetry = _telemetry.copyWith(
            isDoNotDisturb: enable,
            lastUpdated: DateTime.now(),
          );
        }
        broadcastCurrentState();
        break;
      case 'set_ringer':
        if (value is String) {
          if (NativePlatformService.isAndroid) {
            await NativePlatformService.setRingerMode(value);
            final real = await NativePlatformService.getRealTelemetry();
            if (real != null) {
              _telemetry = real;
            } else {
              _telemetry = _telemetry.copyWith(
                ringerMode: value,
                lastUpdated: DateTime.now(),
              );
            }
          } else {
            _telemetry = _telemetry.copyWith(
              ringerMode: value,
              lastUpdated: DateTime.now(),
            );
          }
          broadcastCurrentState();
        }
        break;
      case 'find_my_phone':
        _isAlarmRinging = true;
        _lastAlertMessage = '🔊 Remote Phone is ringing at full volume!';
        if (NativePlatformService.isAndroid) {
          await NativePlatformService.findMyPhone();
        }
        onStateUpdated();
        break;
      case 'stop_find_my_phone':
        _isAlarmRinging = false;
        _lastAlertMessage = null;
        if (NativePlatformService.isAndroid) {
          await NativePlatformService.stopFindMyPhone();
        }
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
    if (NativePlatformService.isAndroid) {
      NativePlatformService.toggleDnd(enabled);
    }
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
    if (NativePlatformService.isAndroid) {
      NativePlatformService.setRingerMode(mode);
    }
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'set_ringer',
      value: mode,
    ));
    onStateUpdated();
  }

  void triggerFindMyPhone() {
    _isAlarmRinging = true;
    _lastAlertMessage = '🔊 Ring command sent to remote phone';
    if (NativePlatformService.isAndroid) {
      NativePlatformService.findMyPhone();
    }
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'find_my_phone',
    ));
    onStateUpdated();
  }

  void stopFindMyPhone() {
    _isAlarmRinging = false;
    _lastAlertMessage = null;
    if (NativePlatformService.isAndroid) {
      NativePlatformService.stopFindMyPhone();
    }
    sendMessage(MacDroidProtocol.createTelemetryCommand(
      command: 'stop_find_my_phone',
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

  void dispose() {
    _telemetryTimer?.cancel();
  }
}
