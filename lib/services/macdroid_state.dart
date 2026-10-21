import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/peer_device.dart';
import '../models/clipboard_entry.dart';
import '../models/remote_file_entry.dart';
import '../models/transfer_task.dart';
import '../protocols/macdroid_protocol.dart';
import 'clipboard_sync_service.dart';
import 'remote_file_service.dart';
import 'file_transfer_service.dart';
import 'macdroid_signaling_service.dart';
import 'qr_pairing_service.dart';

class MacDroidState extends ChangeNotifier {
  late final String localDeviceId;
  late final String localDeviceName;
  late final DevicePlatform localPlatform;

  String signalingServerUrl = 'ws://127.0.0.1:8765';
  String currentSessionId = 'MD-DEMO-ROOM';

  // Connected peers
  final List<PeerDevice> _peers = [];
  PeerDevice? _activePeer;

  // Clipboard sync
  final List<ClipboardEntry> _clipboardHistory = [];
  late final ClipboardSyncService _clipboardSync;

  // Remote file explorer state
  String _currentRemotePath = '/';
  List<RemoteFileEntry> _remoteFiles = [];
  final List<String> _remotePathHistory = [];
  bool _isLoadingFiles = false;

  // File transfer tasks
  late final FileTransferService _transferService;

  // Signaling
  late final MacdroidSignalingService _signaling;

  MacDroidState() {
    _initDeviceIdentity();
    _initServices();
  }

  List<PeerDevice> get peers => _peers;
  PeerDevice? get activePeer => _activePeer;
  List<ClipboardEntry> get clipboardHistory => _clipboardHistory;
  String get currentRemotePath => _currentRemotePath;
  List<RemoteFileEntry> get remoteFiles => _remoteFiles;
  List<TransferTask> get transferTasks => _transferService.allTasks;
  bool get isLoadingFiles => _isLoadingFiles;
  bool get isConnected => _signaling.isConnected;
  bool get isAutoClipboardEnabled => _clipboardSync.isAutoSyncEnabled;

  void _initDeviceIdentity() {
    final rand = DateTime.now().millisecondsSinceEpoch % 10000;
    if (kIsWeb) {
      localPlatform = DevicePlatform.web;
      localDeviceName = 'Browser Client';
      localDeviceId = 'web-$rand';
    } else if (Platform.isMacOS) {
      localPlatform = DevicePlatform.macos;
      localDeviceName = 'MacBook Pro';
      localDeviceId = 'mac-$rand';
    } else if (Platform.isWindows) {
      localPlatform = DevicePlatform.windows;
      localDeviceName = 'Windows PC';
      localDeviceId = 'win-$rand';
    } else if (Platform.isAndroid) {
      localPlatform = DevicePlatform.android;
      localDeviceName = 'Android Phone';
      localDeviceId = 'droid-$rand';
    } else {
      localPlatform = DevicePlatform.unknown;
      localDeviceName = 'Device-$rand';
      localDeviceId = 'node-$rand';
    }
  }

  void _initServices() {
    _signaling = MacdroidSignalingService(
      deviceId: localDeviceId,
      deviceName: localDeviceName,
      platform: localPlatform.name,
      onMessage: _onSignalingMessage,
      onStateChanged: (connected) {
        notifyListeners();
      },
    );

    _clipboardSync = ClipboardSyncService(
      localDeviceId: localDeviceId,
      localDeviceName: localDeviceName,
      onBroadcast: (entry) {
        _clipboardHistory.insert(0, entry);
        if (_clipboardHistory.length > 50) {
          _clipboardHistory.removeLast();
        }
        _broadcastMessage(MacDroidProtocol.createClipboardSync(entry));
        notifyListeners();
      },
    );
    _clipboardSync.start();

    _transferService = FileTransferService(
      sendMessage: _broadcastMessage,
      onTaskUpdated: (task) {
        notifyListeners();
      },
    );

    // Auto-connect to default room
    connectSignaling(currentSessionId);
  }

  void connectSignaling(String roomId) {
    currentSessionId = roomId;
    _signaling.connect(signalingServerUrl, joinSessionId: roomId);
  }

  void _broadcastMessage(String rawJson) {
    final parsed = MacDroidProtocol.parseMessage(rawJson);
    if (parsed != null) {
      _signaling.sendPeerMessage(parsed, targetDeviceId: _activePeer?.id);
    }
  }

  void _onSignalingMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'PEER_JOINED' || type == MacDroidProtocol.typeHandshake) {
      final pid = msg['deviceId'] as String?;
      final pname = msg['deviceName'] as String? ?? 'Remote Device';
      final pplat = msg['platform'] as String? ?? 'unknown';

      if (pid != null && pid != localDeviceId) {
        final existingIdx = _peers.indexWhere((p) => p.id == pid);
        final peer = PeerDevice(
          id: pid,
          name: pname,
          platform: DevicePlatform.values.firstWhere(
            (e) => e.name == pplat,
            orElse: () => DevicePlatform.unknown,
          ),
          status: ConnectionStatus.connected,
          lastSeen: DateTime.now(),
        );

        if (existingIdx >= 0) {
          _peers[existingIdx] = peer;
        } else {
          _peers.add(peer);
        }
        _activePeer ??= peer;
        notifyListeners();

        // Send handshake back if peer joined
        if (type == 'PEER_JOINED') {
          _broadcastMessage(MacDroidProtocol.createHandshake(
            deviceId: localDeviceId,
            deviceName: localDeviceName,
            platform: localPlatform.name,
          ));
        }
      }
    } else if (type == MacDroidProtocol.typeClipboardSync) {
      final entry = ClipboardEntry.fromJson(msg);
      _clipboardSync.applyRemoteClipboard(entry);
      _clipboardHistory.insert(0, entry);
      if (_clipboardHistory.length > 50) _clipboardHistory.removeLast();
      notifyListeners();
    } else if (type == MacDroidProtocol.typeFileBrowseRequest) {
      // Remote device requested our file list
      final reqId = msg['requestId'] as String;
      final reqPath = msg['path'] as String;
      RemoteFileService.listDirectory(reqPath).then((entries) {
        _broadcastMessage(MacDroidProtocol.createFileBrowseResponse(
          requestId: reqId,
          path: reqPath,
          entries: entries,
        ));
      });
    } else if (type == MacDroidProtocol.typeFileBrowseResponse) {
      // Received directory listing from remote device
      _isLoadingFiles = false;
      _currentRemotePath = msg['path'] as String? ?? '/';
      final rawEntries = msg['entries'] as List<dynamic>? ?? [];
      _remoteFiles = rawEntries
          .map((e) => RemoteFileEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } else if (type == MacDroidProtocol.typeFileTransferRequest) {
      _transferService.handleIncomingRequest(msg);
    } else if (type == MacDroidProtocol.typeFileTransferChunk) {
      _transferService.handleIncomingChunk(msg);
    } else if (type == MacDroidProtocol.typeFileTransferComplete) {
      _transferService.handleIncomingComplete(msg);
    }
  }

  // Browse remote path
  void browseRemoteDirectory(String path) {
    if (_activePeer == null) return;
    _isLoadingFiles = true;
    _remotePathHistory.add(_currentRemotePath);
    notifyListeners();

    final reqId = 'req-${DateTime.now().millisecondsSinceEpoch}';
    _broadcastMessage(MacDroidProtocol.createFileBrowseRequest(
      requestId: reqId,
      path: path,
    ));
  }

  void navigateUpRemote() {
    if (_remotePathHistory.isNotEmpty) {
      final previous = _remotePathHistory.removeLast();
      browseRemoteDirectory(previous);
    } else {
      browseRemoteDirectory('/');
    }
  }

  // One-tap file send
  Future<void> sendOneTapFile(String filePath) async {
    if (_activePeer == null) {
      throw Exception('No active device paired. Please pair a device first.');
    }
    await _transferService.sendFile(
      filePath: filePath,
      peerDeviceId: _activePeer!.id,
    );
  }

  // Manual clipboard push
  Future<void> pushClipboardText(String text) async {
    await _clipboardSync.manualPushText(text);
  }

  void toggleAutoClipboard(bool enabled) {
    _clipboardSync.setAutoSync(enabled);
    notifyListeners();
  }

  void setActivePeer(PeerDevice peer) {
    _activePeer = peer;
    notifyListeners();
  }

  String getPairingQrCodeData() {
    final payload = QrPairingPayload(
      sessionId: currentSessionId,
      deviceId: localDeviceId,
      deviceName: localDeviceName,
      platform: localPlatform.name,
      signalingUrl: signalingServerUrl,
      secretToken: 'sec-${DateTime.now().millisecondsSinceEpoch}',
    );
    return payload.toEncodedString();
  }

  void pairWithScannedCode(String scanned) {
    final parsed = QrPairingPayload.fromEncodedString(scanned);
    if (parsed != null) {
      signalingServerUrl = parsed.signalingUrl;
      connectSignaling(parsed.sessionId);
    } else {
      // Assume raw room ID if text code
      connectSignaling(scanned.trim().toUpperCase());
    }
  }

  @override
  void dispose() {
    _clipboardSync.stop();
    _transferService.dispose();
    _signaling.disconnect();
    super.dispose();
  }
}
