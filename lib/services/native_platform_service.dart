import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/device_telemetry.dart';
import '../models/photo_entry.dart';

class NativePlatformService {
  static const MethodChannel _channel = MethodChannel('com.macdroid/native');
  static bool _callbacksInitialized = false;

  static Function(Map<String, dynamic>)? _onNotificationPosted;
  static Function(String id)? _onNotificationDismissed;

  static void initializeCallbacks({
    Function(Map<String, dynamic>)? onNotificationPosted,
    Function(String id)? onNotificationDismissed,
  }) {
    if (_callbacksInitialized) return;
    _onNotificationPosted = onNotificationPosted;
    _onNotificationDismissed = onNotificationDismissed;

    if (!kIsWeb && Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onNotificationPosted':
            if (call.arguments is Map) {
              final map = Map<String, dynamic>.from(call.arguments as Map);
              _onNotificationPosted?.call(map);
            }
            break;
          case 'onNotificationDismissed':
            if (call.arguments is Map && call.arguments['id'] is String) {
              _onNotificationDismissed?.call(call.arguments['id'] as String);
            }
            break;
        }
      });
      _callbacksInitialized = true;
    }
  }

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static Future<DeviceTelemetry?> getRealTelemetry() async {
    if (!isAndroid) return null;
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTelemetry');
      if (res != null) {
        final map = Map<String, dynamic>.from(res);
        return DeviceTelemetry.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error getting native telemetry: $e');
    }
    return null;
  }

  static Future<void> findMyPhone() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('findMyPhone');
    } catch (e) {
      debugPrint('Error triggering native findMyPhone: $e');
    }
  }

  static Future<void> stopFindMyPhone() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('stopFindMyPhone');
    } catch (e) {
      debugPrint('Error stopping native findMyPhone: $e');
    }
  }

  static Future<bool> isAlarmPlaying() async {
    if (!isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isAlarmPlaying');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setRingerMode(String mode) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('setRingerMode', {'mode': mode});
    } catch (e) {
      debugPrint('Error setting native ringerMode: $e');
    }
  }

  static Future<bool> toggleDnd(bool enable) async {
    if (!isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('toggleDnd', {'enable': enable});
      return res ?? false;
    } catch (e) {
      debugPrint('Error setting native DND: $e');
      return false;
    }
  }

  static Future<void> dialCall(String number) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('dialCall', {'number': number});
    } catch (e) {
      debugPrint('Error invoking native dialCall: $e');
    }
  }

  static Future<void> sendSms(String number, String message) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('sendSms', {'number': number, 'message': message});
    } catch (e) {
      debugPrint('Error invoking native sendSms: $e');
    }
  }

  static Future<List<PhotoEntry>> getRecentPhotos({int limit = 30}) async {
    if (!isAndroid) return [];
    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getRecentPhotos', {'limit': limit});
      if (res != null) {
        return res.map((m) {
          final map = Map<String, dynamic>.from(m);
          return PhotoEntry(
            id: map['id']?.toString() ?? '',
            name: map['fileName']?.toString() ?? 'photo.jpg',
            path: '',
            sizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 1024000,
            dateModified: map['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt())
                : DateTime.now(),
            thumbnailBase64: map['thumbnailBase64']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getting native photos: $e');
    }
    return [];
  }

  static Future<Uint8List?> getPhotoBytes(String photoId) async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('getPhotoBytes', {'photoId': photoId});
    } catch (e) {
      debugPrint('Error fetching native photo bytes: $e');
      return null;
    }
  }

  static Future<void> openNotificationSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }
}
