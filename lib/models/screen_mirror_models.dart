class ScreenFrameMessage {
  final int frameNumber;
  final int width;
  final int height;
  final String orientation; // 'portrait', 'landscape'
  final String imageBase64;
  final DateTime timestamp;

  const ScreenFrameMessage({
    required this.frameNumber,
    required this.width,
    required this.height,
    required this.orientation,
    required this.imageBase64,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'frameNumber': frameNumber,
      'width': width,
      'height': height,
      'orientation': orientation,
      'imageBase64': imageBase64,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ScreenFrameMessage.fromJson(Map<String, dynamic> json) {
    return ScreenFrameMessage(
      frameNumber: json['frameNumber'] as int? ?? 0,
      width: json['width'] as int? ?? 1080,
      height: json['height'] as int? ?? 2400,
      orientation: json['orientation'] as String? ?? 'portrait',
      imageBase64: json['imageBase64'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }
}

class TouchInputEvent {
  final String action; // 'down', 'move', 'up'
  final double xRatio; // 0.0 - 1.0 (normalized)
  final double yRatio; // 0.0 - 1.0 (normalized)
  final int pointerId;
  final int timestamp;

  const TouchInputEvent({
    required this.action,
    required this.xRatio,
    required this.yRatio,
    this.pointerId = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'pointerId': pointerId,
      'timestamp': timestamp,
    };
  }

  factory TouchInputEvent.fromJson(Map<String, dynamic> json) {
    return TouchInputEvent(
      action: json['action'] as String? ?? 'down',
      xRatio: (json['xRatio'] as num?)?.toDouble() ?? 0.0,
      yRatio: (json['yRatio'] as num?)?.toDouble() ?? 0.0,
      pointerId: json['pointerId'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class NavigationCommand {
  final String action; // 'back', 'home', 'recents', 'power', 'volume_up', 'volume_down'

  const NavigationCommand({required this.action});

  Map<String, dynamic> toJson() => {'action': action};

  factory NavigationCommand.fromJson(Map<String, dynamic> json) =>
      NavigationCommand(action: json['action'] as String? ?? 'home');
}
