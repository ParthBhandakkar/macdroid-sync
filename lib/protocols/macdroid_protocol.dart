import 'dart:convert';
import '../models/clipboard_entry.dart';
import '../models/remote_file_entry.dart';

class MacDroidProtocol {
  static const String typeHandshake = 'HANDSHAKE';
  static const String typeClipboardSync = 'CLIPBOARD_SYNC';
  static const String typeFileBrowseRequest = 'FILE_BROWSE_REQUEST';
  static const String typeFileBrowseResponse = 'FILE_BROWSE_RESPONSE';
  static const String typeFileTransferRequest = 'FILE_TRANSFER_REQUEST';
  static const String typeFileTransferAccept = 'FILE_TRANSFER_ACCEPT';
  static const String typeFileTransferChunk = 'FILE_TRANSFER_CHUNK';
  static const String typeFileTransferComplete = 'FILE_TRANSFER_COMPLETE';
  static const String typePing = 'PING';
  static const String typePong = 'PONG';

  // Format message to JSON string
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
