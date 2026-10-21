import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/transfer_task.dart';
import '../protocols/macdroid_protocol.dart';

typedef MessageSenderCallback = void Function(String message);
typedef TaskUpdateCallback = void Function(TransferTask task);

class FileTransferService {
  final MessageSenderCallback sendMessage;
  final TaskUpdateCallback onTaskUpdated;

  // Track active transfers
  final Map<String, TransferTask> _tasks = {};
  // Buffer for incoming file bytes / sink
  final Map<String, IOSink> _incomingFileSinks = {};
  final Map<String, String> _incomingFilePaths = {};
  final Map<String, int> _incomingBytesAccumulated = {};

  FileTransferService({
    required this.sendMessage,
    required this.onTaskUpdated,
  });

  List<TransferTask> get allTasks => _tasks.values.toList();

  // Initiate an outgoing one-tap file send
  Future<void> sendFile({
    required String filePath,
    required String peerDeviceId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final fileName = p.basename(filePath);
    final totalBytes = await file.length();
    final transferId = 'tx-${DateTime.now().millisecondsSinceEpoch}';

    var task = TransferTask(
      id: transferId,
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: 0,
      direction: TransferDirection.outgoing,
      status: TransferStatus.inProgress,
      localFilePath: filePath,
      peerDeviceId: peerDeviceId,
      startTime: DateTime.now(),
    );

    _tasks[transferId] = task;
    onTaskUpdated(task);

    // 1. Send transfer request
    sendMessage(MacDroidProtocol.createFileTransferRequest(
      transferId: transferId,
      fileName: fileName,
      totalBytes: totalBytes,
      mimeType: 'application/octet-stream',
    ));

    // 2. Stream chunks
    // ponytail: 64KB chunk size balances WebRTC DataChannel packet limits and base64 framing overhead.
    // Upgrade path: binary data channels with ArrayBuffer zero-copy framing.
    const chunkSize = 64 * 1024;
    final totalChunks = (totalBytes / chunkSize).ceil().clamp(1, 9999999);

    final stream = file.openRead();
    int chunkIndex = 0;
    int transferred = 0;
    final stopwatch = Stopwatch()..start();

    try {
      await for (final chunk in stream) {
        final b64 = base64Encode(chunk);
        sendMessage(MacDroidProtocol.createFileTransferChunk(
          transferId: transferId,
          chunkIndex: chunkIndex,
          totalChunks: totalChunks,
          base64Payload: b64,
        ));

        chunkIndex++;
        transferred += chunk.length;

        final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
        final speed = elapsedSec > 0.1 ? (transferred / (1024 * 1024)) / elapsedSec : 0.0;

        task = task.copyWith(
          transferredBytes: transferred,
          speedMBps: speed,
        );
        _tasks[transferId] = task;
        onTaskUpdated(task);

        // Small delay to yield to UI and avoid buffer overflow
        if (chunkIndex % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }

      // 3. Send complete
      sendMessage(MacDroidProtocol.createFileTransferComplete(
        transferId: transferId,
        success: true,
      ));

      task = task.copyWith(
        status: TransferStatus.completed,
        transferredBytes: totalBytes,
      );
      _tasks[transferId] = task;
      onTaskUpdated(task);
    } catch (e) {
      task = task.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      );
      _tasks[transferId] = task;
      onTaskUpdated(task);
    }
  }

  // Handle incoming download request (peer asking us to send them a file)
  Future<void> handleIncomingDownloadRequest(Map<String, dynamic> data, String peerDeviceId) async {
    final remotePath = data['remotePath'] as String;
    await sendFile(filePath: remotePath, peerDeviceId: peerDeviceId);
  }

  // Handle incoming transfer request
  Future<void> handleIncomingRequest(Map<String, dynamic> data) async {
    final transferId = data['transferId'] as String;
    final fileName = data['fileName'] as String;
    final totalBytes = (data['totalBytes'] as num?)?.toInt() ?? 0;

    String targetDir = '/tmp';
    if (!kIsWeb) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          targetDir = downloads.path;
        } else {
          final docs = await getApplicationDocumentsDirectory();
          targetDir = docs.path;
        }
      } catch (_) {}
    }

    final outPath = p.join(targetDir, fileName);
    final outFile = File(outPath);
    final sink = outFile.openWrite();

    _incomingFileSinks[transferId] = sink;
    _incomingFilePaths[transferId] = outPath;
    _incomingBytesAccumulated[transferId] = 0;

    final task = TransferTask(
      id: transferId,
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: 0,
      direction: TransferDirection.incoming,
      status: TransferStatus.inProgress,
      localFilePath: outPath,
      startTime: DateTime.now(),
    );

    _tasks[transferId] = task;
    onTaskUpdated(task);

    // Accept transfer
    sendMessage(MacDroidProtocol.createFileTransferAccept(transferId: transferId));
  }

  // Handle incoming chunk
  void handleIncomingChunk(Map<String, dynamic> data) {
    final transferId = data['transferId'] as String;
    final b64 = data['payload'] as String;
    final bytes = base64Decode(b64);

    final sink = _incomingFileSinks[transferId];
    if (sink != null) {
      sink.add(bytes);
    }

    final acc = (_incomingBytesAccumulated[transferId] ?? 0) + bytes.length;
    _incomingBytesAccumulated[transferId] = acc;

    var task = _tasks[transferId];
    if (task != null) {
      final elapsed = (DateTime.now().difference(task.startTime).inMilliseconds) / 1000.0;
      final speed = elapsed > 0.1 ? (acc / (1024 * 1024)) / elapsed : 0.0;
      task = task.copyWith(
        transferredBytes: acc,
        speedMBps: speed,
      );
      _tasks[transferId] = task;
      onTaskUpdated(task);
    }
  }

  // Handle incoming complete
  Future<void> handleIncomingComplete(Map<String, dynamic> data) async {
    final transferId = data['transferId'] as String;
    final sink = _incomingFileSinks.remove(transferId);
    if (sink != null) {
      await sink.flush();
      await sink.close();
    }

    var task = _tasks[transferId];
    if (task != null) {
      task = task.copyWith(
        status: TransferStatus.completed,
        transferredBytes: task.totalBytes,
      );
      _tasks[transferId] = task;
      onTaskUpdated(task);
    }
  }

  void dispose() {
    for (final sink in _incomingFileSinks.values) {
      sink.close();
    }
    _incomingFileSinks.clear();
  }
}
