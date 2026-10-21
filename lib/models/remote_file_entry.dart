class RemoteFileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int size; // In bytes
  final DateTime modified;
  final String mimeType;

  const RemoteFileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.mimeType,
  });

  String get formattedSize {
    if (isDirectory) return 'Folder';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'isDirectory': isDirectory,
    'size': size,
    'modified': modified.millisecondsSinceEpoch,
    'mimeType': mimeType,
  };

  factory RemoteFileEntry.fromJson(Map<String, dynamic> json) {
    return RemoteFileEntry(
      name: json['name'] as String? ?? 'Unknown',
      path: json['path'] as String? ?? '',
      isDirectory: json['isDirectory'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt() ?? 0,
      modified: DateTime.fromMillisecondsSinceEpoch(
        json['modified'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
    );
  }
}
