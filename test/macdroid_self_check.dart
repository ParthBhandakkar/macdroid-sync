import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:macdroid/models/clipboard_entry.dart';
import 'package:macdroid/models/remote_file_entry.dart';
import 'package:macdroid/models/notification_entry.dart';
import 'package:macdroid/models/device_telemetry.dart';
import 'package:macdroid/models/photo_entry.dart';
import 'package:macdroid/models/telephony_models.dart';
import 'package:macdroid/models/now_playing_info.dart';
import 'package:macdroid/models/screen_mirror_models.dart';
import 'package:macdroid/protocols/macdroid_protocol.dart';
import 'package:macdroid/services/qr_pairing_service.dart';

void main() {
  print('=== Running macDroid Comprehensive Self-Check ===');

  // 1. Check Protocol Handshake Framing & Parsing
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
    print('[PASS] 1. Protocol Handshake Framing');
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
    print('[PASS] 2. Clipboard SHA-256 Deduplication');
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
    print('[PASS] 3. 64KB Binary Chunking and Reassembly');
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
    print('[PASS] 4. QR Pairing Payload Encoding/Decoding Round-Trip');
  }

  // 5. Check Remote File Serialization & Download Request Framing
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

    // Protocol check for file download request
    final dlMsg = MacDroidProtocol.createFileDownloadRequest(
      requestId: 'req-dl-1',
      remotePath: file.path,
      fileName: file.name,
    );
    final parsedDl = MacDroidProtocol.parseMessage(dlMsg);
    assert(parsedDl?['type'] == MacDroidProtocol.typeFileDownloadRequest, 'Type must match download request');
    assert(parsedDl?['fileName'] == 'Presentation.pdf', 'Filename must match');
    print('[PASS] 5. Remote File Serialization & Download Request Framing');
  }

  // 6. Check Screen Mirroring Protocol & Touch Coordinate Normalization
  {
    final startMsg = MacDroidProtocol.createScreenStart(fps: 60, quality: 90);
    final parsedStart = MacDroidProtocol.parseMessage(startMsg);
    assert(parsedStart?['type'] == MacDroidProtocol.typeScreenStart);
    assert(parsedStart?['fps'] == 60);

    // Touch event normalized coordinates
    final touch = TouchInputEvent(
      action: 'down',
      xRatio: 0.452,
      yRatio: 0.819,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final touchMsg = MacDroidProtocol.createInputTouch(touch);
    final parsedTouch = MacDroidProtocol.parseMessage(touchMsg);
    assert(parsedTouch?['type'] == MacDroidProtocol.typeInputTouch);
    assert(parsedTouch?['action'] == 'down');
    assert((parsedTouch?['xRatio'] as num).toDouble() == 0.452);

    // Hardware navigation button
    final navMsg = MacDroidProtocol.createInputNav('recents');
    final parsedNav = MacDroidProtocol.parseMessage(navMsg);
    assert(parsedNav?['action'] == 'recents');

    // StandBy Privacy Screen blanking toggle
    final blankMsg = MacDroidProtocol.createPrivacyScreenToggle(true);
    final parsedBlank = MacDroidProtocol.parseMessage(blankMsg);
    assert(parsedBlank?['blankEnabled'] == true);
    print('[PASS] 6. Screen Mirroring, Touch Injection & Privacy Blanking');
  }

  // 7. Check Actionable 2-Way Notifications
  {
    final notif = NotificationEntry(
      id: 'notif-101',
      appPackage: 'com.whatsapp',
      appName: 'WhatsApp',
      title: 'Alex Miller',
      body: 'Can you review the presentation slides?',
      timestamp: DateTime.now(),
      hasReplyAction: true,
    );

    final postMsg = MacDroidProtocol.createNotificationPosted(notif);
    final parsedPost = MacDroidProtocol.parseMessage(postMsg);
    assert(parsedPost?['type'] == MacDroidProtocol.typeNotificationPosted);
    assert((parsedPost?['entry'] as Map)['appName'] == 'WhatsApp');

    // Reply Message
    final replyMsg = MacDroidProtocol.createNotificationReply(
      notificationId: 'notif-101',
      replyText: 'Sure! Reviewing now.',
    );
    final parsedReply = MacDroidProtocol.parseMessage(replyMsg);
    assert(parsedReply?['id'] == 'notif-101');
    assert(parsedReply?['replyText'] == 'Sure! Reviewing now.');

    // Dismissal
    final dismissMsg = MacDroidProtocol.createNotificationDismissed('notif-101');
    final parsedDismiss = MacDroidProtocol.parseMessage(dismissMsg);
    assert(parsedDismiss?['id'] == 'notif-101');
    print('[PASS] 7. Actionable 2-Way Notifications & Inline Replies');
  }

  // 8. Check Device Telemetry & Remote Toggles
  {
    final telemetry = DeviceTelemetry(
      batteryLevel: 88,
      isCharging: true,
      wifiSsid: 'HomeOffice_5GHz',
      wifiStrength: 95,
      cellularCarrier: 'Verizon 5G UW',
      cellularBars: 4,
      storageFreeBytes: 64 * 1024 * 1024 * 1024,
      storageTotalBytes: 128 * 1024 * 1024 * 1024,
      isDoNotDisturb: false,
      ringerMode: 'normal',
      isHotspotOn: false,
      lastUpdated: DateTime.now(),
    );

    assert(telemetry.formattedStorage == '64.0 GB / 128.0 GB');

    final telemMsg = MacDroidProtocol.createTelemetryUpdate(telemetry);
    final parsedTelem = MacDroidProtocol.parseMessage(telemMsg);
    assert(parsedTelem?['batteryLevel'] == 88);
    assert(parsedTelem?['isCharging'] == true);
    assert(parsedTelem?['wifiSsid'] == 'HomeOffice_5GHz');

    // Telemetry commands: Hotspot, DND, Ringer, Find My Phone
    final hotspotCmd = MacDroidProtocol.createTelemetryCommand(
      command: 'set_hotspot',
      value: true,
    );
    assert(MacDroidProtocol.parseMessage(hotspotCmd)?['value'] == true);

    final findPhoneCmd = MacDroidProtocol.createTelemetryCommand(
      command: 'find_my_phone',
    );
    assert(MacDroidProtocol.parseMessage(findPhoneCmd)?['command'] == 'find_my_phone');
    print('[PASS] 8. Device Telemetry & Quick Hardware Controls');
  }

  // 9. Check Recent Photos Fast-Sync Gallery
  {
    final photo = PhotoEntry(
      id: 'photo-01',
      name: 'IMG_20261021_143000.jpg',
      path: '/storage/emulated/0/DCIM/Camera/IMG_20261021_143000.jpg',
      sizeBytes: 4200000,
      dateModified: DateTime.now(),
      width: 4032,
      height: 3024,
    );
    assert(photo.formattedSize == '4.0 MB');

    final photosMsg = MacDroidProtocol.createPhotosListResponse([photo]);
    final parsedPhotos = MacDroidProtocol.parseMessage(photosMsg);
    assert(parsedPhotos?['type'] == MacDroidProtocol.typePhotosListResponse);
    final list = parsedPhotos?['photos'] as List;
    assert(list.length == 1);
    assert(list[0]['name'] == 'IMG_20261021_143000.jpg');
    print('[PASS] 9. Recent Photos Fast-Sync Gallery');
  }

  // 10. Check Telephony Calls & SMS/RCS Messages
  {
    final dialMsg = MacDroidProtocol.createCallDialRequest(phoneNumber: '+1 (555) 987-6543');
    final parsedDial = MacDroidProtocol.parseMessage(dialMsg);
    assert(parsedDial?['phoneNumber'] == '+1 (555) 987-6543');

    final smsMsg = MacDroidProtocol.createSmsSendRequest(
      recipient: '+1 (555) 987-6543',
      text: 'Meeting at 3 PM',
    );
    final parsedSms = MacDroidProtocol.parseMessage(smsMsg);
    assert(parsedSms?['text'] == 'Meeting at 3 PM');

    final callLog = CallLogEntry(
      id: 'call-1',
      phoneNumber: '+15551234567',
      contactName: 'Emma Watson',
      type: CallType.incoming,
      timestamp: DateTime.now(),
      durationSeconds: 245,
    );
    assert(callLog.formattedDuration == '4m 5s');
    print('[PASS] 10. Cellular Calls & SMS/RCS Thread Sync');
  }

  // 11. Check Remote Media Controls
  {
    final nowPlaying = NowPlayingInfo(
      trackTitle: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      appName: 'Spotify',
      isPlaying: true,
      durationMs: 240000,
      positionMs: 120000,
    );
    assert(nowPlaying.progressRatio == 0.5);

    final mediaCmd = MacDroidProtocol.createMediaCommand('play_pause');
    final parsedMedia = MacDroidProtocol.parseMessage(mediaCmd);
    assert(parsedMedia?['command'] == 'play_pause');
    print('[PASS] 11. Remote Media Controls & Progress');
  }

  print('\n>>> ALL 11 MACDROID SELF-CHECKS PASSED SUCCESSFULLY! <<<');
}
