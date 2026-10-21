class PhotoEntry {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime dateModified;
  final String? thumbnailBase64;
  final int? width;
  final int? height;

  const PhotoEntry({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.dateModified,
    this.thumbnailBase64,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'sizeBytes': sizeBytes,
      'dateModified': dateModified.millisecondsSinceEpoch,
      'thumbnailBase64': thumbnailBase64,
      'width': width,
      'height': height,
    };
  }

  factory PhotoEntry.fromJson(Map<String, dynamic> json) {
    return PhotoEntry(
      id: json['id'] as String? ?? 'photo-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Photo.jpg',
      path: json['path'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      dateModified: json['dateModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateModified'] as int)
          : DateTime.now(),
      thumbnailBase64: json['thumbnailBase64'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
