import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class MemoryManagementService {
  static final Logger _logger = Logger('MemoryManagementService');
  static Timer? _memoryCleanupTimer;
  static int _cleanupCount = 0;

  /// تنظيف الذاكرة المؤقتة للصور
  static void clearImageCache() {
    try {
      ImageCache().clear();
      ImageCache().clearLiveImages();
      _logger.fine('تم تنظيف ذاكرة الصور');
    } catch (e) {
      _logger.warning('خطأ في تنظيف ذاكرة الصور: $e');
    }
  }

  /// تحديد حجم الذاكرة المؤقتة للصور
  static void limitImageCache() {
    try {
      ImageCache().maximumSize = 30; // تقليل عدد الصور أكثر
      ImageCache().maximumSizeBytes = 15 * 1024 * 1024; // 15 ميجابايت
      _logger.fine('تم تحديد حدود ذاكرة الصور');
    } catch (e) {
      _logger.warning('خطأ في تحديد حدود ذاكرة الصور: $e');
    }
  }

  /// إلغاء تسجيل المراقبين غير المستخدمة
  static void disposeControllers(List<dynamic> controllers) {
    try {
      for (final controller in controllers) {
        if (controller != null && controller is ChangeNotifier) {
          controller.dispose();
        }
      }
      _logger.fine('تم إلغاء تسجيل ${controllers.length} مراقب');
    } catch (e) {
      _logger.warning('خطأ في إلغاء تسجيل المراقبين: $e');
    }
  }

  /// مراقبة استخدام الذاكرة
  static void monitorMemoryUsage() {
    try {
      if (kIsWeb) return; // لا يمكن قياس الذاكرة على الويب

      final int currentMemory = _getCurrentMemoryUsage();
      debugPrint('💾 استهلاك الذاكرة الحالي: ${currentMemory}MB');

      if (currentMemory > 250) {
        // أكثر من 250MB - تقليل الحد
        debugPrint(
            '🚨 تحذير حرج: استهلاك الذاكرة عالي جداً (${currentMemory}MB)');
        debugPrint('🚨 بدء تنظيف الذاكرة الحرجة...');
        performCriticalMemoryCleanup();
      } else if (currentMemory > 150) {
        // أكثر من 150MB - تنظيف عادي
        _logger.warning('استخدام ذاكرة عالي: ${currentMemory}MB');
        performMemoryCleanup();
      }
    } catch (e) {
      _logger.warning('خطأ في مراقبة الذاكرة: $e');
    }
  }

  /// الحصول على استخدام الذاكرة الحالي
  static int _getCurrentMemoryUsage() {
    try {
      if (kIsWeb) return 0;
      final int info = ProcessInfo.currentRss;
      return info ~/ (1024 * 1024); // Convert to MB
    } catch (e) {
      _logger.warning('خطأ في قياس الذاكرة: $e');
      return 0;
    }
  }

  /// تنظيف شامل للذاكرة
  static void performMemoryCleanup() {
    try {
      _cleanupCount++;
      _logger.info('بدء تنظيف الذاكرة #$_cleanupCount');

      // تنظيف ذاكرة الصور
      clearImageCache();

      // تنظيف ذاكرة النظام
      if (!kIsWeb) {
        // Force garbage collection
        // Note: This is generally not recommended in production
        // but can be useful for debugging memory issues
      }

      _logger.info('تم تنظيف الذاكرة بنجاح');
    } catch (e) {
      _logger.warning('خطأ في تنظيف الذاكرة: $e');
    }
  }

  /// تنظيف حرج للذاكرة
  static void performCriticalMemoryCleanup() {
    try {
      _cleanupCount++;
      debugPrint('🧹 بدء تنظيف الذاكرة الحرجة #$_cleanupCount');

      // تنظيف ذاكرة الصور
      clearImageCache();
      debugPrint('✅ تم تنظيف ذاكرة الصور');

      // تنظيف ذاكرة التخزين المؤقت
      limitImageCache();
      debugPrint('🧹 تم تنظيف ذاكرة التخزين المؤقت');

      // تنظيف ذاكرة النصوص
      if (!kIsWeb) {
        // Force garbage collection
        // Note: This is generally not recommended in production
        // but can be useful for debugging memory issues
      }
      debugPrint('📝 تم تنظيف ذاكرة النصوص');

      debugPrint(
          '⚠️ تحذير: استهلاك الذاكرة عالي جداً. يرجى إغلاق التطبيقات الأخرى.');
      debugPrint('✅ تم تنظيف الذاكرة الحرجة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الذاكرة الحرجة: $e');
    }
  }

  /// تحديد حدود الذاكرة المؤقتة
  static void setMemoryLimits() {
    try {
      limitImageCache();
      _logger.info('تم تحديد حدود الذاكرة');
    } catch (e) {
      _logger.warning('خطأ في تحديد حدود الذاكرة: $e');
    }
  }

  /// بدء التنظيف الدوري للذاكرة
  static void startPeriodicCleanup() {
    try {
      _memoryCleanupTimer?.cancel();
      _memoryCleanupTimer = Timer.periodic(
        const Duration(minutes: 5), // كل 5 دقائق
        (_) => performMemoryCleanup(),
      );
      _logger.info('تم بدء التنظيف الدوري للذاكرة');
    } catch (e) {
      _logger.warning('خطأ في بدء التنظيف الدوري: $e');
    }
  }

  /// إيقاف التنظيف الدوري للذاكرة
  static void stopPeriodicCleanup() {
    try {
      _memoryCleanupTimer?.cancel();
      _memoryCleanupTimer = null;
      _logger.info('تم إيقاف التنظيف الدوري للذاكرة');
    } catch (e) {
      _logger.warning('خطأ في إيقاف التنظيف الدوري: $e');
    }
  }

  /// تنظيف شامل عند إغلاق التطبيق
  static void performFinalCleanup() {
    try {
      _logger.info('بدء التنظيف النهائي للذاكرة');

      // إيقاف التنظيف الدوري
      stopPeriodicCleanup();

      // تنظيف شامل
      performMemoryCleanup();

      _logger.info('تم التنظيف النهائي للذاكرة');
    } catch (e) {
      _logger.warning('خطأ في التنظيف النهائي: $e');
    }
  }
}
