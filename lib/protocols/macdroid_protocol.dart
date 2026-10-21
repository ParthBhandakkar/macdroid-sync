import 'dart:convert';
import '../models/clipboard_entry.dart';
import '../models/remote_file_entry.dart';
import '../models/notification_entry.dart';
import '../models/device_telemetry.dart';
import '../models/photo_entry.dart';
import '../models/telephony_models.dart';
import '../models/now_playing_info.dart';
import '../models/screen_mirror_models.dart';

class MacDroidProtocol {
  // Core & Handshake
  static const String typeHandshake = 'HANDSHAKE';
  static const String typePing = 'PING';
  static const String typePong = 'PONG';

  // Clipboard Sync
  static const String typeClipboardSync = 'CLIPBOARD_SYNC';

  // Storage & Files
  static const String typeFileBrowseRequest = 'FILE_BROWSE_REQUEST';
  static const String typeFileBrowseResponse = 'FILE_BROWSE_RESPONSE';
  static const String typeFileTransferRequest = 'FILE_TRANSFER_REQUEST';
  static const String typeFileTransferAccept = 'FILE_TRANSFER_ACCEPT';
  static const String typeFileTransferChunk = 'FILE_TRANSFER_CHUNK';
  static const String typeFileTransferComplete = 'FILE_TRANSFER_COMPLETE';
  static const String typeFileDownloadRequest = 'FILE_DOWNLOAD_REQUEST';

  // Screen Mirroring & Remote Input
  static const String typeScreenStart = 'SCREEN_START';
  static const String typeScreenStop = 'SCREEN_STOP';
  static const String typeScreenFrame = 'SCREEN_FRAME';
  static const String typeInputTouch = 'INPUT_TOUCH';
  static const String typeInputNav = 'INPUT_NAV';
  static const String typePrivacyScreenToggle = 'PRIVACY_SCREEN_TOGGLE';

  // Notifications
  static const String typeNotificationPosted = 'NOTIFICATION_POSTED';
  static const String typeNotificationDismissed = 'NOTIFICATION_DISMISSED';
  static const String typeNotificationReply = 'NOTIFICATION_REPLY';
  static const String typeNotificationListRequest = 'NOTIFICATION_LIST_REQUEST';
  static const String typeNotificationListResponse = 'NOTIFICATION_LIST_RESPONSE';

  // Device Telemetry & Quick Toggles
  static const String typeTelemetryUpdate = 'TELEMETRY_UPDATE';
  static const String typeTelemetryCommand = 'TELEMETRY_COMMAND';

  // Recent Photos Gallery
  static const String typePhotosListRequest = 'PHOTOS_LIST_REQUEST';
  static const String typePhotosListResponse = 'PHOTOS_LIST_RESPONSE';

  // Calls & SMS Hub
  static const String typeCallLogRequest = 'CALL_LOG_REQUEST';
  static const String typeCallLogResponse = 'CALL_LOG_RESPONSE';
  static const String typeCallDialRequest = 'CALL_DIAL_REQUEST';
  static const String typeSmsListRequest = 'SMS_LIST_REQUEST';
  static const String typeSmsListResponse = 'SMS_LIST_RESPONSE';
  static const String typeSmsSendRequest = 'SMS_SEND_REQUEST';

  // Media Player Control
  static const String typeMediaUpdate = 'MEDIA_UPDATE';
  static const String typeMediaCommand = 'MEDIA_COMMAND';

  // ==================== Handshake & Ping ====================

  static String createHandshake({
    required String deviceId,
    required String deviceName,
    required String platform,
  }) {
    return jsonEncode({
      'type': typeHandshake,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==================== Clipboard ====================

  static String createClipboardSync(ClipboardEntry entry) {
    return jsonEncode({
      'type': typeClipboardSync,
      'id': entry.id,
      'text': entry.text,
      'hash': entry.hash,
      'originDeviceId': entry.originDeviceId,
      'originDeviceName': entry.originDeviceName,
      'timestamp': entry.timestamp.millisecondsSinceEpoch,
    });
  }

  // ==================== File Browsing & Transfer ====================

  static String createFileBrowseRequest({
    required String requestId,
    required String path,
  }) {
    return jsonEncode({
      'type': typeFileBrowseRequest,
      'requestId': requestId,
      'path': path,
    });
  }

  static String createFileBrowseResponse({
    required String requestId,
    required String path,
    required List<RemoteFileEntry> entries,
  }) {
    return jsonEncode({
      'type': typeFileBrowseResponse,
      'requestId': requestId,
      'path': path,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  static String createFileDownloadRequest({
    required String requestId,
    required String remotePath,
    required String fileName,
  }) {
    return jsonEncode({
      'type': typeFileDownloadRequest,
      'requestId': requestId,
      'remotePath': remotePath,
      'fileName': fileName,
    });
  }

  static String createFileTransferRequest({
    required String transferId,
    required String fileName,
    required int totalBytes,
    required String mimeType,
    String? sha256Hash,
  }) {
    return jsonEncode({
      'type': typeFileTransferRequest,
      'transferId': transferId,
      'fileName': fileName,
      'totalBytes': totalBytes,
      'mimeType': mimeType,
      'sha256': sha256Hash,
    });
  }

  static String createFileTransferAccept({required String transferId}) {
    return jsonEncode({
      'type': typeFileTransferAccept,
      'transferId': transferId,
    });
  }

  static String createFileTransferChunk({
    required String transferId,
    required int chunkIndex,
    required int totalChunks,
    required String base64Payload,
  }) {
    return jsonEncode({
      'type': typeFileTransferChunk,
      'transferId': transferId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'payload': base64Payload,
    });
  }

  static String createFileTransferComplete({
    required String transferId,
    required bool success,
    String? message,
  }) {
    return jsonEncode({
      'type': typeFileTransferComplete,
      'transferId': transferId,
      'success': success,
      'message': message,
    });
  }

  // ==================== Screen Mirroring ====================

  static String createScreenStart({int fps = 30, int quality = 80}) {
    return jsonEncode({
      'type': typeScreenStart,
      'fps': fps,
      'quality': quality,
    });
  }

  static String createScreenStop() {
    return jsonEncode({
      'type': typeScreenStop,
    });
  }

  static String createScreenFrame(ScreenFrameMessage frame) {
    return jsonEncode({
      'type': typeScreenFrame,
      ...frame.toJson(),
    });
  }

  static String createInputTouch(TouchInputEvent touch) {
    return jsonEncode({
      'type': typeInputTouch,
      ...touch.toJson(),
    });
  }

  static String createInputNav(String action) {
    return jsonEncode({
      'type': typeInputNav,
      'action': action,
    });
  }

  static String createPrivacyScreenToggle(bool blankEnabled) {
    return jsonEncode({
      'type': typePrivacyScreenToggle,
      'blankEnabled': blankEnabled,
    });
  }

  // ==================== Notifications ====================

  static String createNotificationPosted(NotificationEntry entry) {
    return jsonEncode({
      'type': typeNotificationPosted,
      'entry': entry.toJson(),
    });
  }

  static String createNotificationDismissed(String notificationId) {
    return jsonEncode({
      'type': typeNotificationDismissed,
      'id': notificationId,
    });
  }

  static String createNotificationReply({
    required String notificationId,
    required String replyText,
  }) {
    return jsonEncode({
      'type': typeNotificationReply,
      'id': notificationId,
      'replyText': replyText,
    });
  }

  static String createNotificationListRequest() {
    return jsonEncode({
      'type': typeNotificationListRequest,
    });
  }

  static String createNotificationListResponse(List<NotificationEntry> entries) {
    return jsonEncode({
      'type': typeNotificationListResponse,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  // ==================== Device Telemetry ====================

  static String createTelemetryUpdate(DeviceTelemetry telemetry) {
    return jsonEncode({
      'type': typeTelemetryUpdate,
      ...telemetry.toJson(),
    });
  }

  static String createTelemetryCommand({
    required String command,
    dynamic value,
  }) {
    return jsonEncode({
      'type': typeTelemetryCommand,
      'command': command,
      'value': value,
    });
  }

  // ==================== Photos Gallery ====================

  static String createPhotosListRequest() {
    return jsonEncode({
      'type': typePhotosListRequest,
    });
  }

  static String createPhotosListResponse(List<PhotoEntry> photos) {
    return jsonEncode({
      'type': typePhotosListResponse,
      'photos': photos.map((p) => p.toJson()).toList(),
    });
  }

  // ==================== Calls & SMS ====================

  static String createCallLogRequest() {
    return jsonEncode({
      'type': typeCallLogRequest,
    });
  }

  static String createCallLogResponse(List<CallLogEntry> calls) {
    return jsonEncode({
      'type': typeCallLogResponse,
      'calls': calls.map((c) => c.toJson()).toList(),
    });
  }

  static String createCallDialRequest({required String phoneNumber}) {
    return jsonEncode({
      'type': typeCallDialRequest,
      'phoneNumber': phoneNumber,
    });
  }

  static String createSmsListRequest() {
    return jsonEncode({
      'type': typeSmsListRequest,
    });
  }

  static String createSmsListResponse({
    required List<SmsConversation> conversations,
    required List<SmsMessage> recentMessages,
  }) {
    return jsonEncode({
      'type': typeSmsListResponse,
      'conversations': conversations.map((c) => c.toJson()).toList(),
      'messages': recentMessages.map((m) => m.toJson()).toList(),
    });
  }

  static String createSmsSendRequest({
    required String recipient,
    required String text,
  }) {
    return jsonEncode({
      'type': typeSmsSendRequest,
      'recipient': recipient,
      'text': text,
    });
  }

  // ==================== Media Player ====================

  static String createMediaUpdate(NowPlayingInfo media) {
    return jsonEncode({
      'type': typeMediaUpdate,
      ...media.toJson(),
    });
  }

  static String createMediaCommand(String command) {
    return jsonEncode({
      'type': typeMediaCommand,
      'command': command, // 'play', 'pause', 'play_pause', 'next', 'previous'
    });
  }

  // ==================== Parser ====================

  static Map<String, dynamic>? parseMessage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed frames
    }
    return null;
  }
}
