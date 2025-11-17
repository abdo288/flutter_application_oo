import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/realtime_settings.dart';
import '../models/update_log.dart';
import '../services/connectivity_service.dart';
import '../services/presence_service.dart';
import '../services/realtime_debug_service.dart';
import '../services/realtime_settings_service.dart';
import '../services/realtime_update_service.dart';

// ========== Service Providers (Singleton) ==========

/// Provider لخدمة التحديثات الفورية
final Provider<RealtimeUpdateService> realtimeUpdateServiceProvider = Provider<RealtimeUpdateService>((ProviderRef<RealtimeUpdateService> ref) => RealtimeUpdateService.instance);

/// Provider لخدمة الحضور
final Provider<PresenceService> presenceServiceProvider = Provider<PresenceService>((ProviderRef<PresenceService> ref) => PresenceService.instance);

/// Provider لخدمة الإعدادات
final Provider<RealtimeSettingsService> realtimeSettingsServiceProvider =
    Provider<RealtimeSettingsService>((ProviderRef<RealtimeSettingsService> ref) => RealtimeSettingsService.instance);

/// Provider لخدمة الاتصال
final Provider<ConnectivityService> connectivityServiceProvider = Provider<ConnectivityService>((ProviderRef<ConnectivityService> ref) => ConnectivityService());

// ========== State Classes ==========

/// حالة التحديثات الفورية
class RealtimeStatusState {

  const RealtimeStatusState({
    required this.isOnline,
    required this.isListening,
    this.lastUpdateTime,
    required this.productCallbackCount,
    required this.inventoryCallbackCount,
    required this.connectionCallbackCount,
    required this.isLoading,
    this.error,
  });

  factory RealtimeStatusState.initial() => const RealtimeStatusState(
        isOnline: false,
        isListening: false,
        productCallbackCount: 0,
        inventoryCallbackCount: 0,
        connectionCallbackCount: 0,
        isLoading: false,
      );
  final bool isOnline;
  final bool isListening;
  final DateTime? lastUpdateTime;
  final int productCallbackCount;
  final int inventoryCallbackCount;
  final int connectionCallbackCount;
  final bool isLoading;
  final String? error;

  RealtimeStatusState copyWith({
    bool? isOnline,
    bool? isListening,
    DateTime? lastUpdateTime,
    int? productCallbackCount,
    int? inventoryCallbackCount,
    int? connectionCallbackCount,
    bool? isLoading,
    String? error,
  }) => RealtimeStatusState(
      isOnline: isOnline ?? this.isOnline,
      isListening: isListening ?? this.isListening,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      productCallbackCount: productCallbackCount ?? this.productCallbackCount,
      inventoryCallbackCount:
          inventoryCallbackCount ?? this.inventoryCallbackCount,
      connectionCallbackCount:
          connectionCallbackCount ?? this.connectionCallbackCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
}

/// حالة الإعدادات
class RealtimeSettingsState {

  const RealtimeSettingsState({
    required this.notificationsEnabled,
    required this.soundsEnabled,
    required this.vibrationEnabled,
    required this.priority,
    required this.maxNotifications,
    required this.autoSyncEnabled,
    required this.syncInterval,
    required this.isLoading,
    this.error,
  });

  factory RealtimeSettingsState.initial() => const RealtimeSettingsState(
        notificationsEnabled: true,
        soundsEnabled: true,
        vibrationEnabled: false,
        priority: 'medium',
        maxNotifications: 10,
        autoSyncEnabled: false,
        syncInterval: Duration(seconds: 10),
        isLoading: false,
      );
  final bool notificationsEnabled;
  final bool soundsEnabled;
  final bool vibrationEnabled;
  final String priority;
  final int maxNotifications;
  final bool autoSyncEnabled;
  final Duration syncInterval;
  final bool isLoading;
  final String? error;

  RealtimeSettingsState copyWith({
    bool? notificationsEnabled,
    bool? soundsEnabled,
    bool? vibrationEnabled,
    String? priority,
    int? maxNotifications,
    bool? autoSyncEnabled,
    Duration? syncInterval,
    bool? isLoading,
    String? error,
  }) => RealtimeSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      priority: priority ?? this.priority,
      maxNotifications: maxNotifications ?? this.maxNotifications,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncInterval: syncInterval ?? this.syncInterval,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
}

// ========== State Notifiers ==========

/// StateNotifier لإدارة حالة التحديثات الفورية
class RealtimeStatusNotifier extends StateNotifier<RealtimeStatusState> {
  RealtimeStatusNotifier(this._realtimeService)
      : super(RealtimeStatusState.initial()) {
    _initialize();
  }

  final RealtimeUpdateService _realtimeService;
  Timer? _periodicUpdateTimer;

  void _initialize() {
    _updateStatus();
    _startPeriodicUpdate();
  }

  /// بدء التحديث الدوري للحالة
  void _startPeriodicUpdate() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _updateStatus();
    });
  }

  /// تحديث حالة التحديثات
  void _updateStatus() {
    state = state.copyWith(
      isOnline: _realtimeService.isOnline,
      isListening: _realtimeService.isListening,
      lastUpdateTime: _realtimeService.lastUpdateTime,
      productCallbackCount: _realtimeService.productCallbackCount,
      inventoryCallbackCount: _realtimeService.inventoryCallbackCount,
      connectionCallbackCount: _realtimeService.connectionCallbackCount,
    );
  }

  /// بدء التحديثات الفورية
  Future<void> startRealtimeUpdates() async {
    state = state.copyWith(isLoading: true);
    try {
      await _realtimeService.startRealtimeUpdates();
      _updateStatus();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في بدء التحديثات: $e',
      );
    }
  }

  /// إيقاف التحديثات الفورية
  Future<void> stopRealtimeUpdates() async {
    state = state.copyWith(isLoading: true);
    try {
      await _realtimeService.stopRealtimeUpdates();
      _updateStatus();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في إيقاف التحديثات: $e',
      );
    }
  }

  /// إعادة تشغيل التحديثات الفورية
  Future<void> restartRealtimeUpdates() async {
    state = state.copyWith(isLoading: true);
    try {
      await _realtimeService.stopRealtimeUpdates();
      await Future<void>.delayed(const Duration(seconds: 1));
      await _realtimeService.startRealtimeUpdates();
      _updateStatus();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في إعادة تشغيل التحديثات: $e',
      );
    }
  }

  /// تحديث شامل للنظام
  Future<void> performFullRefresh() async {
    state = state.copyWith(isLoading: true);
    try {
      await _realtimeService.stopRealtimeUpdates();
      await Future<void>.delayed(const Duration(seconds: 1));
      await _realtimeService.startRealtimeUpdates();
      _updateStatus();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في التحديث الشامل: $e',
      );
    }
  }

  /// فحص صحة الاتصال
  void performHealthCheck() {
    _updateStatus();
  }

  /// مسح جميع Callbacks
  void clearAllCallbacks() {
    // إزالة جميع callbacks
    _realtimeService.removeConnectionStatusCallback(_updateStatus);
    _updateStatus();
  }

  /// تشخيص التحديثات الفورية
  Future<void> performDiagnosis() async {
    try {
      final Map<String, dynamic> diagnosis =
          await RealtimeDebugService.performFullDiagnosis();
      RealtimeDebugService.printDiagnosisReport(diagnosis);
    } catch (e) {
      state = state.copyWith(error: 'خطأ في التشخيص: $e');
    }
  }

  /// اختبار التحديث الفوري
  Future<void> testRealtimeUpdate() async {
    try {
      final bool success = await RealtimeDebugService.testRealtimeUpdate();
      if (!success) {
        state = state.copyWith(error: 'فشل في اختبار التحديث الفوري');
      }
    } catch (e) {
      state = state.copyWith(error: 'خطأ في اختبار التحديث: $e');
    }
  }

  @override
  void dispose() {
    _periodicUpdateTimer?.cancel();
    super.dispose();
  }
}

/// StateNotifier لإدارة إعدادات التحديثات الفورية
class RealtimeSettingsNotifier extends StateNotifier<RealtimeSettingsState> {
  RealtimeSettingsNotifier(this._settingsService)
      : super(RealtimeSettingsState.initial()) {
    _loadSettings();
  }

  final RealtimeSettingsService _settingsService;

  /// تحميل الإعدادات
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final RealtimeSettings settings = _settingsService.currentSettings;
      state = state.copyWith(
        notificationsEnabled: settings.enableNotifications,
        soundsEnabled: settings.enableSounds,
        vibrationEnabled: settings.enableVibration,
        priority: 'medium', // قيمة افتراضية
        maxNotifications: settings.maxLogSize,
        autoSyncEnabled: settings.autoStart,
        syncInterval: settings.syncInterval,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحميل الإعدادات: $e',
      );
    }
  }

  /// تحديث إعداد الإشعارات
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      // تحديث بسيط للحالة
      state = state.copyWith(
        notificationsEnabled: enabled,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحديث الإشعارات: $e',
      );
    }
  }

  /// تحديث إعداد الأصوات
  Future<void> setSoundsEnabled(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(
        soundsEnabled: enabled,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحديث الأصوات: $e',
      );
    }
  }

  /// تحديث إعداد الاهتزاز
  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(
        vibrationEnabled: enabled,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحديث الاهتزاز: $e',
      );
    }
  }

  /// تحديث المزامنة التلقائية
  Future<void> setAutoSyncEnabled(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(
        autoSyncEnabled: enabled,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحديث المزامنة التلقائية: $e',
      );
    }
  }

  /// تحديث فترة المزامنة
  Future<void> setSyncInterval(Duration interval) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(
        syncInterval: interval,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحديث فترة المزامنة: $e',
      );
    }
  }
}

// ========== Providers ==========

/// Provider لحالة التحديثات الفورية
final StateNotifierProvider<RealtimeStatusNotifier, RealtimeStatusState> realtimeStatusProvider =
    StateNotifierProvider<RealtimeStatusNotifier, RealtimeStatusState>((StateNotifierProviderRef<RealtimeStatusNotifier, RealtimeStatusState> ref) {
  final RealtimeUpdateService realtimeService = ref.watch(realtimeUpdateServiceProvider);
  return RealtimeStatusNotifier(realtimeService);
});

/// Provider لإعدادات التحديثات الفورية
final StateNotifierProvider<RealtimeSettingsNotifier, RealtimeSettingsState> realtimeSettingsProvider =
    StateNotifierProvider<RealtimeSettingsNotifier, RealtimeSettingsState>(
        (StateNotifierProviderRef<RealtimeSettingsNotifier, RealtimeSettingsState> ref) {
  final RealtimeSettingsService settingsService = ref.watch(realtimeSettingsServiceProvider);
  return RealtimeSettingsNotifier(settingsService);
});

// ========== Stream Providers ==========

/// Provider للجلسات النشطة
final StreamProvider<List<ActiveSession>> activeSessionsStreamProvider = StreamProvider<List<ActiveSession>>((StreamProviderRef<List<ActiveSession>> ref) {
  final PresenceService presenceService = ref.watch(presenceServiceProvider);
  return presenceService.getActiveSessionsStream();
});

/// Provider لسجل التحديثات
final StreamProvider<UpdateLog> updateLogStreamProvider = StreamProvider<UpdateLog>((StreamProviderRef<UpdateLog> ref) {
  final RealtimeUpdateService realtimeService = ref.watch(realtimeUpdateServiceProvider);
  return realtimeService.updateLogStream;
});

/// Provider لحالة الاتصال
final StreamProvider<bool> connectivityStatusProvider = StreamProvider<bool>((StreamProviderRef<bool> ref) => ConnectivityService.connectionStream);

// ========== Computed Providers ==========

/// Provider لعدد الجلسات النشطة
final Provider<int> activeSessionsCountProvider = Provider<int>((ProviderRef<int> ref) {
  final AsyncValue<List<ActiveSession>> sessionsAsync = ref.watch(activeSessionsStreamProvider);
  return sessionsAsync.when(
    data: (List<ActiveSession> sessions) => sessions.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider لعدد جلسات Windows
final Provider<int> windowsSessionsCountProvider = Provider<int>((ProviderRef<int> ref) {
  final AsyncValue<List<ActiveSession>> sessionsAsync = ref.watch(activeSessionsStreamProvider);
  return sessionsAsync.when(
    data: (List<ActiveSession> sessions) => sessions
        .where((ActiveSession session) => session.platform.toLowerCase().contains('windows'))
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider لعدد جلسات الموبايل
final Provider<int> mobileSessionsCountProvider = Provider<int>((ProviderRef<int> ref) {
  final AsyncValue<List<ActiveSession>> sessionsAsync = ref.watch(activeSessionsStreamProvider);
  return sessionsAsync.when(
    data: (List<ActiveSession> sessions) => sessions
        .where((ActiveSession session) =>
            session.platform.toLowerCase().contains('android') ||
            session.platform.toLowerCase().contains('ios'))
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider لإحصائيات التحديثات
final Provider<Map<String, dynamic>> updateStatsProvider = Provider<Map<String, dynamic>>((ProviderRef<Map<String, dynamic>> ref) {
  // final realtimeService = ref.watch(realtimeUpdateServiceProvider);
  return <String, dynamic>{
    'successCount': 0,
    'failureCount': 0,
    'responseTimes': <Duration>[],
  };
});

/// Provider للجلسة الحالية
final Provider<ActiveSession?> currentSessionProvider = Provider<ActiveSession?>((ProviderRef<ActiveSession?> ref) {
  final AsyncValue<List<ActiveSession>> sessionsAsync = ref.watch(activeSessionsStreamProvider);
  return sessionsAsync.when(
    data: (List<ActiveSession> sessions) {
      final String currentPlatform = _getCurrentPlatform();
      try {
        return sessions.firstWhere(
          (ActiveSession session) => session.platform == currentPlatform,
        );
      } catch (e) {
        return sessions.isNotEmpty ? sessions.first : null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// الحصول على المنصة الحالية
String _getCurrentPlatform() {
  if (kIsWeb) return 'Web';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'macOS';
  return 'Unknown';
}
