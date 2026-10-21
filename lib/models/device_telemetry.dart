class DeviceTelemetry {
  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final String? wifiSsid;
  final int wifiStrength; // 0 - 4 bars
  final String? cellularCarrier;
  final int cellularBars; // 0 - 5 bars
  final int storageFreeBytes;
  final int storageTotalBytes;
  final bool isDoNotDisturb;
  final String ringerMode; // 'normal', 'vibrate', 'silent'
  final bool isHotspotOn;
  final DateTime lastUpdated;

  const DeviceTelemetry({
    this.batteryLevel = 100,
    this.isCharging = false,
    this.wifiSsid,
    this.wifiStrength = 4,
    this.cellularCarrier,
    this.cellularBars = 4,
    this.storageFreeBytes = 64000000000,
    this.storageTotalBytes = 128000000000,
    this.isDoNotDisturb = false,
    this.ringerMode = 'normal',
    this.isHotspotOn = false,
    required this.lastUpdated,
  });

  factory DeviceTelemetry.mock() {
    return DeviceTelemetry(
      batteryLevel: 84,
      isCharging: true,
      wifiSsid: 'MacDroid-5G',
      wifiStrength: 4,
      cellularCarrier: '5G UW',
      cellularBars: 4,
      storageFreeBytes: 48200000000,
      storageTotalBytes: 128000000000,
      isDoNotDisturb: false,
      ringerMode: 'normal',
      isHotspotOn: false,
      lastUpdated: DateTime.now(),
    );
  }

  DeviceTelemetry copyWith({
    int? batteryLevel,
    bool? isCharging,
    String? wifiSsid,
    int? wifiStrength,
    String? cellularCarrier,
    int? cellularBars,
    int? storageFreeBytes,
    int? storageTotalBytes,
    bool? isDoNotDisturb,
    String? ringerMode,
    bool? isHotspotOn,
    DateTime? lastUpdated,
  }) {
    return DeviceTelemetry(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiStrength: wifiStrength ?? this.wifiStrength,
      cellularCarrier: cellularCarrier ?? this.cellularCarrier,
      cellularBars: cellularBars ?? this.cellularBars,
      storageFreeBytes: storageFreeBytes ?? this.storageFreeBytes,
      storageTotalBytes: storageTotalBytes ?? this.storageTotalBytes,
      isDoNotDisturb: isDoNotDisturb ?? this.isDoNotDisturb,
      ringerMode: ringerMode ?? this.ringerMode,
      isHotspotOn: isHotspotOn ?? this.isHotspotOn,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get formattedStorage {
    final freeGb = (storageFreeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final totalGb = (storageTotalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    return '$freeGb GB / $totalGb GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'wifiSsid': wifiSsid,
      'wifiStrength': wifiStrength,
      'cellularCarrier': cellularCarrier,
      'cellularBars': cellularBars,
      'storageFreeBytes': storageFreeBytes,
      'storageTotalBytes': storageTotalBytes,
      'isDoNotDisturb': isDoNotDisturb,
      'ringerMode': ringerMode,
      'isHotspotOn': isHotspotOn,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory DeviceTelemetry.fromJson(Map<String, dynamic> json) {
    return DeviceTelemetry(
      batteryLevel: json['batteryLevel'] as int? ?? 100,
      isCharging: json['isCharging'] as bool? ?? false,
      wifiSsid: json['wifiSsid'] as String?,
      wifiStrength: json['wifiStrength'] as int? ?? 4,
      cellularCarrier: json['cellularCarrier'] as String?,
      cellularBars: json['cellularBars'] as int? ?? 4,
      storageFreeBytes: json['storageFreeBytes'] as int? ?? 64000000000,
      storageTotalBytes: json['storageTotalBytes'] as int? ?? 128000000000,
      isDoNotDisturb: json['isDoNotDisturb'] as bool? ?? false,
      ringerMode: json['ringerMode'] as String? ?? 'normal',
      isHotspotOn: json['isHotspotOn'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int)
          : DateTime.now(),
    );
  }
}
