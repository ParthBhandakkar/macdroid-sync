import 'dart:async';
import 'package:flutter/services.dart';
import '../models/clipboard_entry.dart';

typedef ClipboardBroadcastCallback = void Function(ClipboardEntry entry);

class ClipboardSyncService {
  final String localDeviceId;
  final String localDeviceName;
  final ClipboardBroadcastCallback onBroadcast;

  Timer? _pollingTimer;
  String? _lastHash;
  bool _isAutoSyncEnabled = true;

  ClipboardSyncService({
    required this.localDeviceId,
    required this.localDeviceName,
    required this.onBroadcast,
  });

  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  void setAutoSync(bool enabled) {
    _isAutoSyncEnabled = enabled;
  }

  void start() {
    _pollingTimer?.cancel();
    // ponytail: 800ms polling loop is a cross-platform compromise for Windows, Mac, and Android
    // to avoid complex C-FFI Win32 clipboard hooks and Android foreground Accessibility Services.
    // Upgrade path: platform-specific native plugins (AddClipboardFormatListener on Win32, NSPasteboard changeCount on macOS).
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _checkClipboard());
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkClipboard() async {
    if (!_isAutoSyncEnabled) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) return;

      final entry = ClipboardEntry(
        id: UniqueKeyString.generate(),
        text: text,
        originDeviceId: localDeviceId,
        originDeviceName: localDeviceName,
        timestamp: DateTime.now(),
      );

      // Loop prevention check: if same content hash, do not rebroadcast
      if (entry.hash == _lastHash) return;

      _lastHash = entry.hash;
      onBroadcast(entry);
    } catch (_) {
      // Ignore transient clipboard access errors
    }
  }

  Future<void> applyRemoteClipboard(ClipboardEntry entry) async {
    // If we were the ones who sent it, or hash matches, do not re-apply
    if (entry.originDeviceId == localDeviceId || entry.hash == _lastHash) {
      return;
    }

    _lastHash = entry.hash;
    await Clipboard.setData(ClipboardData(text: entry.text));
  }

  Future<void> manualPushText(String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    final entry = ClipboardEntry(
      id: UniqueKeyString.generate(),
      text: text,
      originDeviceId: localDeviceId,
      originDeviceName: localDeviceName,
      timestamp: DateTime.now(),
    );
    _lastHash = entry.hash;
    onBroadcast(entry);
  }
}
