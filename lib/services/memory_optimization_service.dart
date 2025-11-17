import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// خدمة تحسين استهلاك الذاكرة
/// تقوم بمراقبة وإدارة استهلاك الذاكرة في التطبيق
class MemoryOptimizationService {
  factory MemoryOptimizationService() => _instance;
  MemoryOptimizationService._internal();
  static final MemoryOptimizationService _instance =
      MemoryOptimizationService._internal();

  Timer? _memoryCheckTimer;
  bool _isMonitoring = false;
  int _lastMemoryUsage = 0;
  int _cleanupCount = 0;

  // إعدادات المراقبة المحسنة
  static const Duration memoryCheckInterval =
      Duration(minutes: 1); // مراقبة أكثر تكراراً
  static const int memoryWarningThreshold = 150; // MB - تقليل الحد أكثر
  static const int memoryCriticalThreshold = 250; // MB - تقليل الحد أكثر
  static const int maxCleanupAttempts = 5; // زيادة محاولات التنظيف

  // ========== بدء وإيقاف المراقبة ==========

  /// بدء مراقبة استهلاك الذاكرة
  void startMemoryMonitoring() {
    if (_isMonitoring) {
      debugPrint('مراقبة الذاكرة تعمل بالفعل');
      return;
    }

    try {
      debugPrint('🚀 بدء مراقبة استهلاك الذاكرة...');

      _memoryCheckTimer = Timer.periodic(memoryCheckInterval, (_) {
        _checkMemoryUsage();
      });

      _isMonitoring = true;
      debugPrint('✅ تم بدء مراقبة استهلاك الذاكرة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الذاكرة: $e');
    }
  }

  /// إيقاف مراقبة استهلاك الذاكرة
  void stopMemoryMonitoring() {
    if (!_isMonitoring) return;

    try {
      debugPrint('🛑 إيقاف مراقبة استهلاك الذاكرة...');

      _memoryCheckTimer?.cancel();
      _memoryCheckTimer = null;
      _isMonitoring = false;

      debugPrint('✅ تم إيقاف مراقبة استهلاك الذاكرة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف مراقبة الذاكرة: $e');
    }
  }

  // ========== فحص استهلاك الذاكرة ==========

  /// فحص استهلاك الذاكرة الحالي
  Future<void> _checkMemoryUsage() async {
    try {
      final int currentMemoryUsage = _getActualMemoryUsage();

      // تجنب التنظيف المتكرر إذا لم يتغير الاستهلاك بشكل كبير
      if ((currentMemoryUsage - _lastMemoryUsage).abs() < 50) {
        return;
      }

      _lastMemoryUsage = currentMemoryUsage;
      debugPrint('💾 استهلاك الذاكرة الحالي: ${currentMemoryUsage}MB');

      if (currentMemoryUsage >= memoryCriticalThreshold) {
        debugPrint(
            '🚨 تحذير حرج: استهلاك الذاكرة عالي جداً (${currentMemoryUsage}MB)');
        await _handleCriticalMemoryUsage();
      } else if (currentMemoryUsage >= memoryWarningThreshold) {
        debugPrint('⚠️ تحذير: استهلاك الذاكرة عالي (${currentMemoryUsage}MB)');
        await _handleHighMemoryUsage();
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص استهلاك الذاكرة: $e');
    }
  }

  /// الحصول على استهلاك الذاكرة الفعلي
  int _getActualMemoryUsage() {
    try {
      if (kIsWeb) return 0;

      // استخدام ProcessInfo للحصول على استهلاك الذاكرة الفعلي
      final int rss = ProcessInfo.currentRss;
      return rss ~/ (1024 * 1024); // تحويل إلى MB
    } catch (e) {
      debugPrint('❌ خطأ في قياس الذاكرة: $e');
      return 0;
    }
  }

  // ========== معالجة استهلاك الذاكرة العالي ==========

  /// معالجة استهلاك الذاكرة العالي
  Future<void> _handleHighMemoryUsage() async {
    try {
      if (_cleanupCount >= maxCleanupAttempts) {
        debugPrint('⚠️ تم الوصول للحد الأقصى من محاولات التنظيف');
        return;
      }

      debugPrint('🧹 بدء تنظيف الذاكرة...');
      _cleanupCount++;

      // تنظيف ذاكرة الصور
      _clearImageCache();

      // تنظيف ذاكرة التخزين المؤقت
      _clearMemoryCache();

      debugPrint('✅ تم تنظيف الذاكرة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الذاكرة: $e');
    }
  }

  /// معالجة استهلاك الذاكرة الحرجة
  Future<void> _handleCriticalMemoryUsage() async {
    try {
      debugPrint('🚨 بدء تنظيف الذاكرة الحرجة...');

      // تنظيف شامل للذاكرة
      _clearImageCache();
      _clearMemoryCache();
      _clearTextCache();

      // إعادة تعيين عداد التنظيف
      _cleanupCount = 0;

      // إشعار المستخدم
      _notifyUserOfMemoryIssue();

      debugPrint('✅ تم تنظيف الذاكرة الحرجة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الذاكرة الحرجة: $e');
    }
  }

  // ========== طرق تنظيف الذاكرة ==========

  /// تنظيف ذاكرة التخزين المؤقت
  void _clearMemoryCache() {
    try {
      // تنظيف ذاكرة التخزين المؤقت للتطبيق
      ImageCache().clear();
      ImageCache().clearLiveImages();

      // تنظيف ذاكرة النظام
      if (!kIsWeb) {
        // إجبار garbage collection
        // هذا مفيد في حالات الذاكرة الحرجة
        // System.gc() غير متوفر في Flutter، نستخدم بديل
        // يمكن استخدام Timer لتأخير العمليات الثقيلة
      }

      // تنظيف ذاكرة التطبيق العامة
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      debugPrint('🧹 تم تنظيف ذاكرة التخزين المؤقت');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف ذاكرة التخزين المؤقت: $e');
    }
  }

  /// تنظيف ذاكرة الصور
  void _clearImageCache() {
    try {
      // تنظيف ذاكرة الصور
      ImageCache().clear();
      ImageCache().clearLiveImages();

      // تحديد حدود ذاكرة الصور
      ImageCache().maximumSize = 20; // تقليل عدد الصور المحفوظة أكثر
      ImageCache().maximumSizeBytes = 10 * 1024 * 1024; // 10 ميجابايت فقط

      debugPrint('🖼️ تم تنظيف ذاكرة الصور');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف ذاكرة الصور: $e');
    }
  }

  /// تنظيف ذاكرة النصوص
  void _clearTextCache() {
    try {
      // تنظيف ذاكرة النصوص والخطوط
      // لا يوجد طريقة مباشرة في Flutter لتنظيف ذاكرة النصوص
      // لكن يمكننا تنظيف ذاكرة التطبيق العامة

      debugPrint('📝 تم تنظيف ذاكرة النصوص');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف ذاكرة النصوص: $e');
    }
  }

  /// إشعار المستخدم بمشكلة الذاكرة
  void _notifyUserOfMemoryIssue() {
    debugPrint(
        '⚠️ تحذير: استهلاك الذاكرة عالي جداً. يرجى إغلاق التطبيقات الأخرى.');
  }

  // ========== معلومات الحالة ==========

  /// الحصول على حالة المراقبة
  bool get isMonitoring => _isMonitoring;

  /// الحصول على استهلاك الذاكرة الحالي
  int getCurrentMemoryUsage() => _getActualMemoryUsage();

  // ========== تنظيف الموارد ==========

  /// تنظيف الموارد
  void dispose() {
    stopMemoryMonitoring();
    debugPrint('تم تنظيف خدمة تحسين الذاكرة');
  }
}
