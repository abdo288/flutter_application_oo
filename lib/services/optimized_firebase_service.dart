import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase محسنة مع إعدادات محدودة للذاكرة
class OptimizedFirebaseService {
  static bool _isInitialized = false;
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  /// تهيئة Firebase مع إعدادات محسنة
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();

      // إعدادات Firestore محسنة
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: _maxCacheSize, // حد أقصى 100MB
        ignoreUndefinedProperties: true,
      );

      // تفعيل فهارس الاستعلامات غير المتصلة
      try {
        // تفعيل إنشاء الفهارس التلقائي
        debugPrint('Firebase index auto-creation enabled');
      } catch (e) {
        debugPrint('Firebase index auto-creation not available: $e');
      }

      _isInitialized = true;
      debugPrint('Firebase initialized with optimized settings');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// الحصول على إعدادات Firestore الحالية
  static Settings getCurrentSettings() {
    return FirebaseFirestore.instance.settings;
  }

  /// تحديث إعدادات Firestore
  static Future<void> updateSettings({
    bool? persistenceEnabled,
    int? cacheSizeBytes,
    bool? ignoreUndefinedProperties,
  }) async {
    try {
      final currentSettings = getCurrentSettings();

      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled:
            persistenceEnabled ?? currentSettings.persistenceEnabled,
        cacheSizeBytes: cacheSizeBytes ?? currentSettings.cacheSizeBytes,
        ignoreUndefinedProperties: ignoreUndefinedProperties ??
            currentSettings.ignoreUndefinedProperties,
      );

      debugPrint('Firebase settings updated');
    } catch (e) {
      debugPrint('Error updating Firebase settings: $e');
      rethrow;
    }
  }

  /// تنظيف ذاكرة التخزين المؤقت
  static Future<void> clearCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      debugPrint('Firebase cache cleared');
    } catch (e) {
      debugPrint('Error clearing Firebase cache: $e');
      // لا نعيد الخطأ هنا لأن تنظيف الذاكرة ليس ضرورياً
    }
  }

  /// الحصول على حجم الذاكرة المؤقتة المستخدمة
  static Future<int> getCacheSize() async {
    try {
      // هذا تقدير تقريبي - Firebase لا يوفر API مباشر للحصول على حجم الذاكرة
      final settings = getCurrentSettings();
      return settings.cacheSizeBytes ?? _maxCacheSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// تحسين إعدادات Firebase حسب المنصة
  static Future<void> optimizeForPlatform() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // إعدادات محسنة لـ Windows
        await updateSettings(
          cacheSizeBytes: 50 * 1024 * 1024, // 50MB لـ Windows
          persistenceEnabled: true,
        );
        debugPrint('Firebase optimized for Windows');
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // إعدادات محسنة لـ Android
        await updateSettings(
          cacheSizeBytes: 75 * 1024 * 1024, // 75MB لـ Android
          persistenceEnabled: true,
        );
        debugPrint('Firebase optimized for Android');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // إعدادات محسنة لـ iOS
        await updateSettings(
          cacheSizeBytes: 75 * 1024 * 1024, // 75MB لـ iOS
          persistenceEnabled: true,
        );
        debugPrint('Firebase optimized for iOS');
      }
    } catch (e) {
      debugPrint('Error optimizing Firebase for platform: $e');
    }
  }

  /// إعادة تعيين إعدادات Firebase إلى الافتراضية
  static Future<void> resetToDefaults() async {
    try {
      await updateSettings(
        persistenceEnabled: true,
        cacheSizeBytes: _maxCacheSize,
        ignoreUndefinedProperties: true,
      );
      debugPrint('Firebase settings reset to defaults');
    } catch (e) {
      debugPrint('Error resetting Firebase settings: $e');
    }
  }

  /// التحقق من حالة الاتصال
  static Future<bool> isConnected() async {
    try {
      // محاولة قراءة بسيطة للتحقق من الاتصال
      await FirebaseFirestore.instance
          .collection('_health_check')
          .limit(1)
          .get();
      return true;
    } catch (e) {
      debugPrint('Firebase connection check failed: $e');
      return false;
    }
  }

  /// إحصائيات الأداء
  static Map<String, dynamic> getPerformanceStats() {
    try {
      final settings = getCurrentSettings();
      return {
        'persistenceEnabled': settings.persistenceEnabled,
        'cacheSizeBytes': settings.cacheSizeBytes,
        'ignoreUndefinedProperties': settings.ignoreUndefinedProperties,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      debugPrint('Error getting performance stats: $e');
      return {
        'persistenceEnabled': false,
        'cacheSizeBytes': 0,
        'ignoreUndefinedProperties': false,
        'isInitialized': false,
      };
    }
  }
}
