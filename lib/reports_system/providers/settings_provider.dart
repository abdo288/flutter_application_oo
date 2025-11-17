import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

/// إعدادات نظام التقارير
@freezed
class ReportsSettingsState with _$ReportsSettingsState {
  const factory ReportsSettingsState({
    @Default(true) bool notificationsEnabled,
    @Default(true) bool autoSyncEnabled,
    @Default(false) bool darkModeEnabled,
    @Default('ar') String language,
    @Default(true) bool chartsEnabled,
    @Default(true) bool dataExportEnabled,
    @Default(30) int refreshIntervalMinutes,
    @Default(100) int maxReportsPerPage,
  }) = _ReportsSettingsState;
}

/// Provider لإعدادات التقارير
@riverpod
class ReportsSettings extends _$ReportsSettings {
  @override
  ReportsSettingsState build() => const ReportsSettingsState();

  /// تبديل حالة الإشعارات
  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  /// تبديل المزامنة التلقائية
  void toggleAutoSync() {
    state = state.copyWith(autoSyncEnabled: !state.autoSyncEnabled);
  }

  /// تبديل الوضع الليلي
  void toggleDarkMode() {
    state = state.copyWith(darkModeEnabled: !state.darkModeEnabled);
  }

  /// تغيير اللغة
  void changeLanguage(String language) {
    state = state.copyWith(language: language);
  }

  /// تبديل الرسوم البيانية
  void toggleCharts() {
    state = state.copyWith(chartsEnabled: !state.chartsEnabled);
  }

  /// تبديل تصدير البيانات
  void toggleDataExport() {
    state = state.copyWith(dataExportEnabled: !state.dataExportEnabled);
  }

  /// تحديث فترة التحديث
  void updateRefreshInterval(int minutes) {
    state = state.copyWith(refreshIntervalMinutes: minutes);
  }

  /// تحديث عدد التقارير في الصفحة
  void updateMaxReportsPerPage(int count) {
    state = state.copyWith(maxReportsPerPage: count);
  }

  /// إعادة تعيين الإعدادات للقيم الافتراضية
  void resetToDefaults() {
    state = const ReportsSettingsState();
  }
}

/// Provider للوصول السريع لإعدادات معينة
final Provider<bool> notificationsEnabledProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(reportsSettingsProvider).notificationsEnabled);

final Provider<bool> autoSyncEnabledProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(reportsSettingsProvider).autoSyncEnabled);

final Provider<bool> darkModeEnabledProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(reportsSettingsProvider).darkModeEnabled);

final Provider<String> languageProvider = Provider<String>((ProviderRef<String> ref) => ref.watch(reportsSettingsProvider).language);
