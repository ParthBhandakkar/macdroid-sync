enum TransferDirection { outgoing, incoming }
enum TransferStatus { pending, inProgress, completed, failed, cancelled }

class TransferTask {
  final String id;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final TransferDirection direction;
  final TransferStatus status;
  final double speedMBps;
  final String? localFilePath;
  final String? peerDeviceId;
  final String? errorMessage;
  final DateTime startTime;

  const TransferTask({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.transferredBytes = 0,
    required this.direction,
    this.status = TransferStatus.pending,
    this.speedMBps = 0.0,
    this.localFilePath,
    this.peerDeviceId,
    this.errorMessage,
    required this.startTime,
  });

  double get progress => totalBytes > 0 ? (transferredBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get formattedTotalSize => _formatBytes(totalBytes);
  String get formattedTransferred => _formatBytes(transferredBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  TransferTask copyWith({
    String? id,
    String? fileName,
    int? totalBytes,
    int? transferredBytes,
    TransferDirection? direction,
    TransferStatus? status,
    double? speedMBps,
    String? localFilePath,
    String? peerDeviceId,
    String? errorMessage,
    DateTime? startTime,
  }) {
    return TransferTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      speedMBps: speedMBps ?? this.speedMBps,
      localFilePath: localFilePath ?? this.localFilePath,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
    );
  }
}
