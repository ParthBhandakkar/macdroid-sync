class NowPlayingInfo {
  final String trackTitle;
  final String artist;
  final String album;
  final String? albumArtBase64;
  final bool isPlaying;
  final int durationMs;
  final int positionMs;
  final String appName;

  const NowPlayingInfo({
    required this.trackTitle,
    required this.artist,
    required this.album,
    this.albumArtBase64,
    required this.isPlaying,
    required this.durationMs,
    required this.positionMs,
    required this.appName,
  });

  factory NowPlayingInfo.mock() {
    return const NowPlayingInfo(
      trackTitle: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      isPlaying: true,
      durationMs: 243000,
      positionMs: 82000,
      appName: 'Spotify',
    );
  }

  NowPlayingInfo copyWith({
    String? trackTitle,
    String? artist,
    String? album,
    String? albumArtBase64,
    bool? isPlaying,
    int? durationMs,
    int? positionMs,
    String? appName,
  }) {
    return NowPlayingInfo(
      trackTitle: trackTitle ?? this.trackTitle,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtBase64: albumArtBase64 ?? this.albumArtBase64,
      isPlaying: isPlaying ?? this.isPlaying,
      durationMs: durationMs ?? this.durationMs,
      positionMs: positionMs ?? this.positionMs,
      appName: appName ?? this.appName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackTitle': trackTitle,
      'artist': artist,
      'album': album,
      'albumArtBase64': albumArtBase64,
      'isPlaying': isPlaying,
      'durationMs': durationMs,
      'positionMs': positionMs,
      'appName': appName,
    };
  }

  factory NowPlayingInfo.fromJson(Map<String, dynamic> json) {
    return NowPlayingInfo(
      trackTitle: json['trackTitle'] as String? ?? 'No Media Playing',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      albumArtBase64: json['albumArtBase64'] as String?,
      isPlaying: json['isPlaying'] as bool? ?? false,
      durationMs: json['durationMs'] as int? ?? 0,
      positionMs: json['positionMs'] as int? ?? 0,
      appName: json['appName'] as String? ?? 'Music',
    );
  }

  String get formattedPosition => _formatTime(positionMs);
  String get formattedDuration => _formatTime(durationMs);

  double get progressRatio {
    if (durationMs <= 0) return 0.0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  static String _formatTime(int ms) {
    final totalSecs = ms ~/ 1000;
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
