import 'package:flutter/foundation.dart';
import '../models/now_playing_info.dart';
import '../protocols/macdroid_protocol.dart';

class MediaControlService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  NowPlayingInfo _nowPlaying = NowPlayingInfo.mock();

  MediaControlService({
    required this.sendMessage,
    required this.onStateUpdated,
  });

  NowPlayingInfo get nowPlaying => _nowPlaying;

  void handleIncomingMedia(Map<String, dynamic> data) {
    _nowPlaying = NowPlayingInfo.fromJson(data);
    onStateUpdated();
  }

  void handleIncomingCommand(String cmd) {
    switch (cmd) {
      case 'play':
        _nowPlaying = _nowPlaying.copyWith(isPlaying: true);
        break;
      case 'pause':
        _nowPlaying = _nowPlaying.copyWith(isPlaying: false);
        break;
      case 'play_pause':
        _nowPlaying = _nowPlaying.copyWith(isPlaying: !_nowPlaying.isPlaying);
        break;
      case 'next':
        _nowPlaying = _nowPlaying.copyWith(
          trackTitle: 'Intro',
          artist: 'The xx',
          album: 'xx',
          positionMs: 0,
          durationMs: 127000,
          isPlaying: true,
        );
        break;
      case 'previous':
        _nowPlaying = _nowPlaying.copyWith(
          trackTitle: 'Midnight City',
          artist: 'M83',
          album: 'Hurry Up, We\'re Dreaming',
          positionMs: 0,
          durationMs: 243000,
          isPlaying: true,
        );
        break;
    }
    onStateUpdated();
    broadcastCurrentState();
  }

  void togglePlayPause() {
    _nowPlaying = _nowPlaying.copyWith(isPlaying: !_nowPlaying.isPlaying);
    sendMessage(MacDroidProtocol.createMediaCommand('play_pause'));
    onStateUpdated();
  }

  void nextTrack() {
    _nowPlaying = _nowPlaying.copyWith(
      trackTitle: 'Intro',
      artist: 'The xx',
      album: 'xx',
      positionMs: 0,
      durationMs: 127000,
      isPlaying: true,
    );
    sendMessage(MacDroidProtocol.createMediaCommand('next'));
    onStateUpdated();
  }

  void previousTrack() {
    _nowPlaying = _nowPlaying.copyWith(
      trackTitle: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      positionMs: 0,
      durationMs: 243000,
      isPlaying: true,
    );
    sendMessage(MacDroidProtocol.createMediaCommand('previous'));
    onStateUpdated();
  }

  void broadcastCurrentState() {
    sendMessage(MacDroidProtocol.createMediaUpdate(_nowPlaying));
  }
}
