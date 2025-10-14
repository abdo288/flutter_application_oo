import 'dart:convert';

/// إعدادات التحديثات الفورية
class RealtimeSettings {
  const RealtimeSettings({
    this.syncInterval = const Duration(seconds: 10),
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = false,
    this.maxLogSize = 1000,
    this.autoStart = true,
    this.enableDebugMode = false,
    this.healthCheckInterval = const Duration(seconds: 10),
    this.updateTimeout = const Duration(seconds: 30),
    this.enableBatching = true,
    this.batchSize = 50,
    this.enableCaching = true,
    this.cacheTimeout = const Duration(minutes: 5),
  });

  /// إنشاء من Map
  factory RealtimeSettings.fromMap(Map<String, dynamic> map) => RealtimeSettings(
      syncInterval:
          Duration(milliseconds: map['syncInterval'] as int? ?? 10000),
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      enableSounds: map['enableSounds'] as bool? ?? true,
      enableVibration: map['enableVibration'] as bool? ?? false,
      maxLogSize: map['maxLogSize'] as int? ?? 1000,
      autoStart: map['autoStart'] as bool? ?? true,
      enableDebugMode: map['enableDebugMode'] as bool? ?? false,
      healthCheckInterval:
          Duration(milliseconds: map['healthCheckInterval'] as int? ?? 10000),
      updateTimeout:
          Duration(milliseconds: map['updateTimeout'] as int? ?? 30000),
      enableBatching: map['enableBatching'] as bool? ?? true,
      batchSize: map['batchSize'] as int? ?? 50,
      enableCaching: map['enableCaching'] as bool? ?? true,
      cacheTimeout:
          Duration(milliseconds: map['cacheTimeout'] as int? ?? 300000),
    );

  /// إنشاء من JSON
  factory RealtimeSettings.fromJson(String source) =>
      RealtimeSettings.fromMap(json.decode(source) as Map<String, dynamic>);
  final Duration syncInterval;
  final bool enableNotifications;
  final bool enableSounds;
  final bool enableVibration;
  final int maxLogSize;
  final bool autoStart;
  final bool enableDebugMode;
  final Duration healthCheckInterval;
  final Duration updateTimeout;
  final bool enableBatching;
  final int batchSize;
  final bool enableCaching;
  final Duration cacheTimeout;

  /// الإعدادات الافتراضية
  static const RealtimeSettings defaultSettings = RealtimeSettings();

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
        'syncInterval': syncInterval.inMilliseconds,
        'enableNotifications': enableNotifications,
        'enableSounds': enableSounds,
        'enableVibration': enableVibration,
        'maxLogSize': maxLogSize,
        'autoStart': autoStart,
        'enableDebugMode': enableDebugMode,
        'healthCheckInterval': healthCheckInterval.inMilliseconds,
        'updateTimeout': updateTimeout.inMilliseconds,
        'enableBatching': enableBatching,
        'batchSize': batchSize,
        'enableCaching': enableCaching,
        'cacheTimeout': cacheTimeout.inMilliseconds,
      };

  /// تحويل إلى JSON
  String toJson() => json.encode(toMap());

  /// نسخ مع تعديلات
  RealtimeSettings copyWith({
    Duration? syncInterval,
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    int? maxLogSize,
    bool? autoStart,
    bool? enableDebugMode,
    Duration? healthCheckInterval,
    Duration? updateTimeout,
    bool? enableBatching,
    int? batchSize,
    bool? enableCaching,
    Duration? cacheTimeout,
  }) =>
      RealtimeSettings(
        syncInterval: syncInterval ?? this.syncInterval,
        enableNotifications: enableNotifications ?? this.enableNotifications,
        enableSounds: enableSounds ?? this.enableSounds,
        enableVibration: enableVibration ?? this.enableVibration,
        maxLogSize: maxLogSize ?? this.maxLogSize,
        autoStart: autoStart ?? this.autoStart,
        enableDebugMode: enableDebugMode ?? this.enableDebugMode,
        healthCheckInterval: healthCheckInterval ?? this.healthCheckInterval,
        updateTimeout: updateTimeout ?? this.updateTimeout,
        enableBatching: enableBatching ?? this.enableBatching,
        batchSize: batchSize ?? this.batchSize,
        enableCaching: enableCaching ?? this.enableCaching,
        cacheTimeout: cacheTimeout ?? this.cacheTimeout,
      );

  /// التحقق من صحة الإعدادات
  bool get isValid =>
      syncInterval.inSeconds > 0 &&
      maxLogSize > 0 &&
      batchSize > 0 &&
      healthCheckInterval.inSeconds > 0 &&
      updateTimeout.inSeconds > 0;

  /// الحصول على إعدادات محسّنة للأداء
  RealtimeSettings get performanceOptimized => copyWith(
        syncInterval: const Duration(seconds: 5),
        enableBatching: true,
        batchSize: 100,
        enableCaching: true,
        cacheTimeout: const Duration(minutes: 10),
      );

  /// الحصول على إعدادات توفير البطارية
  RealtimeSettings get batteryOptimized => copyWith(
        syncInterval: const Duration(seconds: 30),
        enableBatching: true,
        batchSize: 200,
        healthCheckInterval: const Duration(seconds: 30),
      );

  /// الحصول على إعدادات التطوير
  RealtimeSettings get developmentMode => copyWith(
        enableDebugMode: true,
        syncInterval: const Duration(seconds: 2),
        enableNotifications: true,
        enableSounds: true,
      );

  @override
  String toString() =>
      'RealtimeSettings(syncInterval: $syncInterval, enableNotifications: $enableNotifications, enableSounds: $enableSounds, enableVibration: $enableVibration, maxLogSize: $maxLogSize, autoStart: $autoStart, enableDebugMode: $enableDebugMode, healthCheckInterval: $healthCheckInterval, updateTimeout: $updateTimeout, enableBatching: $enableBatching, batchSize: $batchSize, enableCaching: $enableCaching, cacheTimeout: $cacheTimeout)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeSettings &&
        other.syncInterval == syncInterval &&
        other.enableNotifications == enableNotifications &&
        other.enableSounds == enableSounds &&
        other.enableVibration == enableVibration &&
        other.maxLogSize == maxLogSize &&
        other.autoStart == autoStart &&
        other.enableDebugMode == enableDebugMode &&
        other.healthCheckInterval == healthCheckInterval &&
        other.updateTimeout == updateTimeout &&
        other.enableBatching == enableBatching &&
        other.batchSize == batchSize &&
        other.enableCaching == enableCaching &&
        other.cacheTimeout == cacheTimeout;
  }

  @override
  int get hashCode => Object.hash(
        syncInterval,
        enableNotifications,
        enableSounds,
        enableVibration,
        maxLogSize,
        autoStart,
        enableDebugMode,
        healthCheckInterval,
        updateTimeout,
        enableBatching,
        batchSize,
        enableCaching,
        cacheTimeout,
      );
}
