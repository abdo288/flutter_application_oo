import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cleanup/models/cleanup_result.dart';
import '../services/connectivity_service.dart';
import '../services/data_cleanup_service.dart';
import '../services/inventory_alert_service.dart';
import '../services/local_notification_service.dart';

/// حالة تبويب الإعدادات
class SettingsState {

  const SettingsState({
    this.notificationsEnabled = true,
    this.lowStockAlertsEnabled = true,
    this.dailyRemindersEnabled = true,
    this.weeklyRemindersEnabled = true,
    this.isOnline = true,
    this.isConnectionExpanded = false,
    this.isLanguageExpanded = false,
    this.isNotificationsExpanded = false,
    this.isRemindersExpanded = false,
    this.isActionsExpanded = false,
    this.isAppInfoExpanded = false,
    this.isAppearanceExpanded = false,
    this.isUserMgmtExpanded = false,
    this.isLoading = false,
    this.errorMessage,
  });
  // الإشعارات
  final bool notificationsEnabled;
  final bool lowStockAlertsEnabled;

  // التذكيرات
  final bool dailyRemindersEnabled;
  final bool weeklyRemindersEnabled;

  // الاتصال
  final bool isOnline;

  // حالات التوسع للبطاقات (8 بطاقات)
  final bool isConnectionExpanded;
  final bool isLanguageExpanded;
  final bool isNotificationsExpanded;
  final bool isRemindersExpanded;
  final bool isActionsExpanded;
  final bool isAppInfoExpanded;
  final bool isAppearanceExpanded;
  final bool isUserMgmtExpanded;

  // التحميل والخطأ
  final bool isLoading;
  final String? errorMessage;

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? lowStockAlertsEnabled,
    bool? dailyRemindersEnabled,
    bool? weeklyRemindersEnabled,
    bool? isOnline,
    bool? isConnectionExpanded,
    bool? isLanguageExpanded,
    bool? isNotificationsExpanded,
    bool? isRemindersExpanded,
    bool? isActionsExpanded,
    bool? isAppInfoExpanded,
    bool? isAppearanceExpanded,
    bool? isUserMgmtExpanded,
    bool? isLoading,
    String? errorMessage,
  }) => SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowStockAlertsEnabled:
          lowStockAlertsEnabled ?? this.lowStockAlertsEnabled,
      dailyRemindersEnabled:
          dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      weeklyRemindersEnabled:
          weeklyRemindersEnabled ?? this.weeklyRemindersEnabled,
      isOnline: isOnline ?? this.isOnline,
      isConnectionExpanded: isConnectionExpanded ?? this.isConnectionExpanded,
      isLanguageExpanded: isLanguageExpanded ?? this.isLanguageExpanded,
      isNotificationsExpanded:
          isNotificationsExpanded ?? this.isNotificationsExpanded,
      isRemindersExpanded: isRemindersExpanded ?? this.isRemindersExpanded,
      isActionsExpanded: isActionsExpanded ?? this.isActionsExpanded,
      isAppInfoExpanded: isAppInfoExpanded ?? this.isAppInfoExpanded,
      isAppearanceExpanded: isAppearanceExpanded ?? this.isAppearanceExpanded,
      isUserMgmtExpanded: isUserMgmtExpanded ?? this.isUserMgmtExpanded,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// مدير حالة الإعدادات
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.ref) : super(const SettingsState()) {
    _setupConnectivityListener();
  }

  final Ref ref;

  /// إعداد مستمع حالة الاتصال
  void _setupConnectivityListener() {
    state = state.copyWith(isOnline: ConnectivityService.isOnline);
    ConnectivityService.addConnectivityListener(_onConnectivityChanged);
  }

  /// معالج تغيير حالة الاتصال
  void _onConnectivityChanged(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  /// تحميل الإعدادات من SharedPreferences
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      state = state.copyWith(
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        dailyRemindersEnabled: prefs.getBool('dailyRemindersEnabled') ?? true,
        weeklyRemindersEnabled: prefs.getBool('weeklyRemindersEnabled') ?? true,
        lowStockAlertsEnabled: prefs.getBool('lowStockAlertsEnabled') ?? true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تحميل الإعدادات: $e',
      );
      debugPrint('خطأ في تحميل الإعدادات: $e');
    }
  }

  /// تبديل الإشعارات
  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);

      if (!value) {
        await LocalNotificationService.cancelAllNotifications();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطأ في حفظ إعدادات الإشعارات: $e');
      debugPrint('خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }

  /// تبديل تنبيهات المخزون المنخفض
  Future<void> toggleLowStockAlerts(bool value) async {
    state = state.copyWith(lowStockAlertsEnabled: value);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lowStockAlertsEnabled', value);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'خطأ في حفظ إعدادات تنبيهات المخزون: $e');
      debugPrint('خطأ في حفظ إعدادات تنبيهات المخزون: $e');
    }
  }

  /// تبديل التذكيرات اليومية
  Future<void> toggleDailyReminders(bool value) async {
    state = state.copyWith(dailyRemindersEnabled: value);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dailyRemindersEnabled', value);

      if (value) {
        await LocalNotificationService.setupDailyReminders();
      } else {
        await LocalNotificationService.cancelScheduledNotifications();
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'خطأ في حفظ إعدادات التذكيرات اليومية: $e');
      debugPrint('خطأ في حفظ إعدادات التذكيرات اليومية: $e');
    }
  }

  /// تبديل التذكيرات الأسبوعية
  Future<void> toggleWeeklyReminders(bool value) async {
    state = state.copyWith(weeklyRemindersEnabled: value);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('weeklyRemindersEnabled', value);

      if (value) {
        await LocalNotificationService.setupWeeklyReminders();
      } else {
        await LocalNotificationService.cancelScheduledNotifications();
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'خطأ في حفظ إعدادات التذكيرات الأسبوعية: $e');
      debugPrint('خطأ في حفظ إعدادات التذكيرات الأسبوعية: $e');
    }
  }

  /// تبديل حالة توسع البطاقة
  void toggleExpansion(String cardKey) {
    switch (cardKey) {
      case 'connection':
        state =
            state.copyWith(isConnectionExpanded: !state.isConnectionExpanded);
        break;
      case 'language':
        state = state.copyWith(isLanguageExpanded: !state.isLanguageExpanded);
        break;
      case 'notifications':
        state = state.copyWith(
            isNotificationsExpanded: !state.isNotificationsExpanded);
        break;
      case 'reminders':
        state = state.copyWith(isRemindersExpanded: !state.isRemindersExpanded);
        break;
      case 'actions':
        state = state.copyWith(isActionsExpanded: !state.isActionsExpanded);
        break;
      case 'appInfo':
        state = state.copyWith(isAppInfoExpanded: !state.isAppInfoExpanded);
        break;
      case 'appearance':
        state =
            state.copyWith(isAppearanceExpanded: !state.isAppearanceExpanded);
        break;
      case 'userMgmt':
        state = state.copyWith(isUserMgmtExpanded: !state.isUserMgmtExpanded);
        break;
    }
  }

  /// تنظيف البيانات
  Future<void> performCleanup() async {
    state = state.copyWith(isLoading: true);

    try {
      // تنظيف التنبيهات القديمة
      await InventoryAlertService.cleanupOldAlerts();

      // تنظيف البيانات المحلية الأساسية
      final DataCleanupService cleanupService = DataCleanupService();
      final CleanupResult result = await cleanupService.performFullCleanup(
        
      );

      if (result.success) {
        debugPrint('✅ تم تنظيف البيانات المحلية بنجاح');
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'خطأ في تنظيف البيانات: ${result.message}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تنظيف البيانات: $e',
      );
      debugPrint('خطأ في تنظيف البيانات: $e');
    }
  }

  /// إعادة تعيين الإعدادات
  Future<void> resetSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // إعادة تعيين جميع الإعدادات للقيم الافتراضية
      await prefs.setBool('notificationsEnabled', true);
      await prefs.setBool('dailyRemindersEnabled', true);
      await prefs.setBool('weeklyRemindersEnabled', true);
      await prefs.setBool('lowStockAlertsEnabled', true);

      // إعادة تحميل الإعدادات
      await loadSettings();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في إعادة تعيين الإعدادات: $e',
      );
      debugPrint('خطأ في إعادة تعيين الإعدادات: $e');
    }
  }

  /// تحديث حالة الاتصال
  void updateConnectionStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    ConnectivityService.removeConnectivityListener(_onConnectivityChanged);
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة الإعدادات
final AutoDisposeStateNotifierProvider<SettingsNotifier, SettingsState> settingsNotifierProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Provider للتحقق من حالة التحميل
final AutoDisposeProvider<bool> settingsLoadingProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.isLoading;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider لرسالة الخطأ
final AutoDisposeProvider<String?> settingsErrorProvider = Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.errorMessage;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider لحالة الاتصال
final AutoDisposeProvider<bool> connectionStatusProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.isOnline;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider للإشعارات
final AutoDisposeProvider<bool> notificationsEnabledProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.notificationsEnabled;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider لتنبيهات المخزون المنخفض
final AutoDisposeProvider<bool> lowStockAlertsEnabledProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.lowStockAlertsEnabled;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider للتذكيرات اليومية
final AutoDisposeProvider<bool> dailyRemindersEnabledProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.dailyRemindersEnabled;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider للتذكيرات الأسبوعية
final AutoDisposeProvider<bool> weeklyRemindersEnabledProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return state.weeklyRemindersEnabled;
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);

/// Provider لحالة توسع البطاقات
final AutoDisposeProvider<Map<String, bool>> cardExpansionProvider = Provider.autoDispose<Map<String, bool>>(
  (AutoDisposeProviderRef<Map<String, bool>> ref) {
    final SettingsState state = ref.watch(settingsNotifierProvider);
    return <String, bool>{
      'connection': state.isConnectionExpanded,
      'language': state.isLanguageExpanded,
      'notifications': state.isNotificationsExpanded,
      'reminders': state.isRemindersExpanded,
      'actions': state.isActionsExpanded,
      'appInfo': state.isAppInfoExpanded,
      'appearance': state.isAppearanceExpanded,
      'userMgmt': state.isUserMgmtExpanded,
    };
  },
  dependencies: <ProviderOrFamily>[settingsNotifierProvider],
);
