import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/realtime_settings.dart';

/// خدمة إدارة إعدادات التحديثات الفورية
class RealtimeSettingsService {
  RealtimeSettingsService._();
  static RealtimeSettingsService? _instance;
  static RealtimeSettingsService get instance =>
      _instance ??= RealtimeSettingsService._();

  static const String _settingsKey = 'realtime_settings';
  static const String _lastUpdateKey = 'last_settings_update';

  SharedPreferences? _prefs;
  RealtimeSettings _currentSettings = RealtimeSettings.defaultSettings;
  final StreamController<RealtimeSettings> _settingsController =
      StreamController<RealtimeSettings>.broadcast();

  /// Stream للإعدادات
  Stream<RealtimeSettings> get settingsStream => _settingsController.stream;

  /// الإعدادات الحالية
  RealtimeSettings get currentSettings => _currentSettings;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      debugPrint('✅ تم تهيئة خدمة إعدادات التحديثات الفورية');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإعدادات: $e');
      rethrow;
    }
  }

  /// تحميل الإعدادات من التخزين المحلي
  Future<void> _loadSettings() async {
    try {
      final String? settingsJson = _prefs?.getString(_settingsKey);

      if (settingsJson != null) {
        _currentSettings = RealtimeSettings.fromJson(settingsJson);
        debugPrint('📋 تم تحميل الإعدادات المحفوظة');
      } else {
        _currentSettings = RealtimeSettings.defaultSettings;
        await _saveSettings();
        debugPrint('📋 تم إنشاء الإعدادات الافتراضية');
      }

      _settingsController.add(_currentSettings);
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإعدادات: $e');
      _currentSettings = RealtimeSettings.defaultSettings;
      _settingsController.add(_currentSettings);
    }
  }

  /// حفظ الإعدادات
  Future<void> _saveSettings() async {
    try {
      final String settingsJson = _currentSettings.toJson();
      await _prefs?.setString(_settingsKey, settingsJson);
      await _prefs?.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('💾 تم حفظ الإعدادات');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإعدادات: $e');
      rethrow;
    }
  }

  /// تحديث الإعدادات
  Future<void> updateSettings(RealtimeSettings newSettings) async {
    try {
      if (!newSettings.isValid) {
        throw ArgumentError('الإعدادات غير صالحة');
      }

      _currentSettings = newSettings;
      await _saveSettings();
      _settingsController.add(_currentSettings);

      debugPrint('🔄 تم تحديث الإعدادات: ${newSettings.toString()}');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإعدادات: $e');
      rethrow;
    }
  }

  /// تحديث إعداد محدد
  Future<void> updateSetting<T>(String key, T value) async {
    try {
      RealtimeSettings newSettings = _currentSettings;

      switch (key) {
        case 'syncInterval':
          if (value is Duration) {
            newSettings = newSettings.copyWith(syncInterval: value);
          }
          break;
        case 'enableNotifications':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableNotifications: value);
          }
          break;
        case 'enableSounds':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableSounds: value);
          }
          break;
        case 'enableVibration':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableVibration: value);
          }
          break;
        case 'maxLogSize':
          if (value is int) {
            newSettings = newSettings.copyWith(maxLogSize: value);
          }
          break;
        case 'autoStart':
          if (value is bool) {
            newSettings = newSettings.copyWith(autoStart: value);
          }
          break;
        case 'enableDebugMode':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableDebugMode: value);
          }
          break;
        case 'healthCheckInterval':
          if (value is Duration) {
            newSettings = newSettings.copyWith(healthCheckInterval: value);
          }
          break;
        case 'updateTimeout':
          if (value is Duration) {
            newSettings = newSettings.copyWith(updateTimeout: value);
          }
          break;
        case 'enableBatching':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableBatching: value);
          }
          break;
        case 'batchSize':
          if (value is int) {
            newSettings = newSettings.copyWith(batchSize: value);
          }
          break;
        case 'enableCaching':
          if (value is bool) {
            newSettings = newSettings.copyWith(enableCaching: value);
          }
          break;
        case 'cacheTimeout':
          if (value is Duration) {
            newSettings = newSettings.copyWith(cacheTimeout: value);
          }
          break;
        default:
          throw ArgumentError('مفتاح الإعداد غير معروف: $key');
      }

      await updateSettings(newSettings);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإعداد $key: $e');
      rethrow;
    }
  }

  /// إعادة تعيين الإعدادات للافتراضية
  Future<void> resetToDefaults() async {
    try {
      _currentSettings = RealtimeSettings.defaultSettings;
      await _saveSettings();
      _settingsController.add(_currentSettings);
      debugPrint('🔄 تم إعادة تعيين الإعدادات للافتراضية');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين الإعدادات: $e');
      rethrow;
    }
  }

  /// تطبيق إعدادات محسّنة للأداء
  Future<void> applyPerformanceSettings() async {
    try {
      final RealtimeSettings performanceSettings =
          _currentSettings.performanceOptimized;
      await updateSettings(performanceSettings);
      debugPrint('⚡ تم تطبيق إعدادات الأداء المحسّنة');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق إعدادات الأداء: $e');
      rethrow;
    }
  }

  /// تطبيق إعدادات توفير البطارية
  Future<void> applyBatteryOptimizedSettings() async {
    try {
      final RealtimeSettings batterySettings =
          _currentSettings.batteryOptimized;
      await updateSettings(batterySettings);
      debugPrint('🔋 تم تطبيق إعدادات توفير البطارية');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق إعدادات البطارية: $e');
      rethrow;
    }
  }

  /// تطبيق إعدادات وضع التطوير
  Future<void> applyDevelopmentSettings() async {
    try {
      final RealtimeSettings devSettings = _currentSettings.developmentMode;
      await updateSettings(devSettings);
      debugPrint('🛠️ تم تطبيق إعدادات وضع التطوير');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق إعدادات التطوير: $e');
      rethrow;
    }
  }

  /// الحصول على آخر وقت تحديث
  DateTime? get lastUpdateTime {
    final String? lastUpdate = _prefs?.getString(_lastUpdateKey);
    if (lastUpdate != null) {
      try {
        return DateTime.parse(lastUpdate);
      } catch (e) {
        debugPrint('❌ خطأ في تحليل وقت آخر تحديث: $e');
        return null;
      }
    }
    return null;
  }

  /// التحقق من وجود إعدادات محفوظة
  bool get hasSavedSettings => _prefs?.getString(_settingsKey) != null;

  /// تصدير الإعدادات
  Map<String, dynamic> exportSettings() => _currentSettings.toMap();

  /// استيراد الإعدادات
  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      final RealtimeSettings importedSettings =
          RealtimeSettings.fromMap(settingsMap);
      await updateSettings(importedSettings);
      debugPrint('📥 تم استيراد الإعدادات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في استيراد الإعدادات: $e');
      rethrow;
    }
  }

  /// مسح جميع الإعدادات
  Future<void> clearAllSettings() async {
    try {
      await _prefs?.remove(_settingsKey);
      await _prefs?.remove(_lastUpdateKey);
      _currentSettings = RealtimeSettings.defaultSettings;
      _settingsController.add(_currentSettings);
      debugPrint('🗑️ تم مسح جميع الإعدادات');
    } catch (e) {
      debugPrint('❌ خطأ في مسح الإعدادات: $e');
      rethrow;
    }
  }

  /// الحصول على إحصائيات الإعدادات
  Map<String, dynamic> getSettingsStats() => {
      'hasSettings': hasSavedSettings,
      'lastUpdate': lastUpdateTime?.toIso8601String(),
      'currentSettings': _currentSettings.toMap(),
      'isValid': _currentSettings.isValid,
    };

  /// تنظيف الموارد
  Future<void> dispose() async {
    await _settingsController.close();
    debugPrint('🧹 تم تنظيف خدمة إعدادات التحديثات الفورية');
  }
}
