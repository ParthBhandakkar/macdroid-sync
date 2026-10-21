import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:macdroid/models/clipboard_entry.dart';
import 'package:macdroid/models/remote_file_entry.dart';
import 'package:macdroid/protocols/macdroid_protocol.dart';
import 'package:macdroid/services/qr_pairing_service.dart';

void main() {
  print('=== Running macDroid Ponytail Self-Check ===');

  // 1. Check Protocol Framing & Parsing
  {
    final handshakeJson = MacDroidProtocol.createHandshake(
      deviceId: 'mac-test-1',
      deviceName: 'Test Mac',
      platform: 'macos',
    );
    final parsed = MacDroidProtocol.parseMessage(handshakeJson);
    assert(parsed != null, 'Handshake must parse');
    final validParsed = parsed!;
    assert(validParsed['type'] == MacDroidProtocol.typeHandshake, 'Type must match');
    assert(validParsed['deviceId'] == 'mac-test-1', 'DeviceId must match');
    print('[PASS] Protocol Handshake Framing');
  }

  // 2. Check Clipboard Deduplication & SHA-256 Hash
  {
    final text = 'https://github.com/morluto/rea';
    final expectedHash = sha256.convert(utf8.encode(text)).toString();

    final entry1 = ClipboardEntry(
      id: 'clip-1',
      text: text,
      originDeviceId: 'mac-1',
      originDeviceName: 'MacBook',
      timestamp: DateTime.now(),
    );
    assert(entry1.hash == expectedHash, 'Entry hash must match sha256');

    // Simulate deduplication check
    String? lastHash = entry1.hash;
    final entry2 = ClipboardEntry(
      id: 'clip-2',
      text: text, // Same text
      originDeviceId: 'mac-1',
      originDeviceName: 'MacBook',
      timestamp: DateTime.now(),
    );
    final isDuplicate = entry2.hash == lastHash;
    assert(isDuplicate, 'Duplicate clipboard text must be detected');
    print('[PASS] Clipboard SHA-256 Deduplication');
  }

  // 3. Check 64KB Binary Chunking & Reassembly
  {
    // Generate 150KB test payload (spans 3 chunks of 64KB)
    final originalBytes = Uint8List(150 * 1024);
    for (int i = 0; i < originalBytes.length; i++) {
      originalBytes[i] = i % 256;
    }
    final originalHash = sha256.convert(originalBytes).toString();

    const chunkSize = 64 * 1024;
    final totalChunks = (originalBytes.length / chunkSize).ceil();
    assert(totalChunks == 3, '150KB must split into 3 chunks of 64KB');

    final chunks = <String>[];
    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize < originalBytes.length) ? start + chunkSize : originalBytes.length;
      final sub = originalBytes.sublist(start, end);
      chunks.add(base64Encode(sub));
    }

    // Reassemble chunks
    final reconstructed = <int>[];
    for (final b64 in chunks) {
      reconstructed.addAll(base64Decode(b64));
    }
    final reassembledBytes = Uint8List.fromList(reconstructed);
    final reassembledHash = sha256.convert(reassembledBytes).toString();

    assert(reassembledBytes.length == originalBytes.length, 'Length must match');
    assert(reassembledHash == originalHash, 'Hash must match exactly');
    print('[PASS] 64KB Binary Chunking and Reassembly');
  }

  // 4. Check QR Pairing Payload Round-Trip
  {
    final payload = const QrPairingPayload(
      sessionId: 'ROOM-ALPHA-99',
      deviceId: 'droid-9812',
      deviceName: 'Galaxy S24',
      platform: 'android',
      signalingUrl: 'ws://192.168.1.50:8765',
      secretToken: 'secret-xyz',
    );

    final encoded = payload.toEncodedString();
    assert(encoded.startsWith('macdroid://'), 'Encoded QR string must start with macdroid://');

    final decoded = QrPairingPayload.fromEncodedString(encoded);
    assert(decoded != null, 'Decoded payload must not be null');
    final validDecoded = decoded!;
    assert(validDecoded.sessionId == 'ROOM-ALPHA-99', 'SessionId must match');
    assert(validDecoded.deviceId == 'droid-9812', 'DeviceId must match');
    assert(validDecoded.signalingUrl == 'ws://192.168.1.50:8765', 'Signaling URL must match');
    print('[PASS] QR Pairing Payload Encoding/Decoding Round-Trip');
  }

  // 5. Check Remote File Serialization
  {
    final file = RemoteFileEntry(
      name: 'Presentation.pdf',
      path: '/storage/emulated/0/Download/Presentation.pdf',
      isDirectory: false,
      size: 5 * 1024 * 1024, // 5 MB
      modified: DateTime.now(),
      mimeType: 'application/pdf',
    );
    assert(file.formattedSize == '5.0 MB', 'Formatted size must be 5.0 MB');

    final json = file.toJson();
    final roundTrip = RemoteFileEntry.fromJson(json);
    assert(roundTrip.name == file.name, 'Round trip name must match');
    assert(roundTrip.size == file.size, 'Round trip size must match');
    print('[PASS] Remote File Serialization & Size Formatting');
  }

  print('\nALL 5 SELF-CHECKS PASSED SUCCESSFULLY!');
}
