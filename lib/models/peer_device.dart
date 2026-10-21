enum DevicePlatform { macos, windows, android, linux, web, unknown }

enum ConnectionStatus { disconnected, connecting, connected, failed }

class PeerDevice {
  final String id;
  final String name;
  final DevicePlatform platform;
  final String? ipAddress;
  final ConnectionStatus status;
  final DateTime lastSeen;

  const PeerDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.ipAddress,
    this.status = ConnectionStatus.disconnected,
    required this.lastSeen,
  });

  PeerDevice copyWith({
    String? id,
    String? name,
    DevicePlatform? platform,
    String? ipAddress,
    ConnectionStatus? status,
    DateTime? lastSeen,
  }) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform.name,
    'ipAddress': ipAddress,
    'status': status.name,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory PeerDevice.fromJson(Map<String, dynamic> json) {
    return PeerDevice(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Device',
      platform: DevicePlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => DevicePlatform.unknown,
      ),
      ipAddress: json['ipAddress'] as String?,
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.disconnected,
      ),
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
