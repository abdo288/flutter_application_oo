import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'cache_service.dart';
import 'memory_management_service.dart';

/// خدمة مراقبة الأداء
class PerformanceService {
  static final Logger _logger = Logger('PerformanceService');

  // Performance metrics
  static final Map<String, DateTime> _operationStartTimes =
      <String, DateTime>{};
  static final Map<String, Duration> _operationDurations = <String, Duration>{};
  static final Map<String, int> _operationCounts = <String, int>{};
  static final Map<String, Duration> _operationTotalTime = <String, Duration>{};

  // Memory tracking
  static int _initialMemoryUsage = 0;
  static int _peakMemoryUsage = 0;
  static Timer? _memoryMonitoringTimer;

  // Network metrics
  static int _networkRequestCount = 0;
  static int _networkErrorCount = 0;
  static Duration _totalNetworkTime = Duration.zero;

  /// بدء مراقبة عملية
  static void startOperation(String operationName) {
    try {
      _operationStartTimes[operationName] = DateTime.now();
      _logger.fine('بدء مراقبة العملية: $operationName');
    } on Exception catch (e) {
      _logger.warning('خطأ في بدء مراقبة العملية $operationName: $e');
    }
  }

  /// انتهاء مراقبة عملية
  static void endOperation(String operationName) {
    try {
      final DateTime? startTime = _operationStartTimes.remove(operationName);
      if (startTime == null) {
        _logger
            .warning('لم يتم العثور على وقت البداية للعملية: $operationName');
        return;
      }

      final Duration duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;

      // تحديث إحصائيات العملية
      _operationCounts[operationName] =
          (_operationCounts[operationName] ?? 0) + 1;
      _operationTotalTime[operationName] =
          (_operationTotalTime[operationName] ?? Duration.zero) + duration;

      _logger.fine(
          'انتهاء العملية $operationName في ${duration.inMilliseconds}ms');

      // تحذير للعمليات البطيئة
      if (duration.inMilliseconds > 5000) {
        _logger.warning(
            'عملية بطيئة: $operationName استغرقت ${duration.inSeconds}s');
      }
    } on Exception catch (e) {
      _logger.warning('خطأ في انتهاء مراقبة العملية $operationName: $e');
    }
  }

  /// قياس الذاكرة المستخدمة
  static int getCurrentMemoryUsage() {
    try {
      if (kIsWeb) {
        // على الويب لا يمكن قياس الذاكرة بدقة
        return 0;
      }

      final int info = ProcessInfo.currentRss;
      final int currentMemory = info ~/ (1024 * 1024); // Convert to MB

      if (currentMemory > _peakMemoryUsage) {
        _peakMemoryUsage = currentMemory;
      }

      return currentMemory;
    } on Exception catch (e) {
      _logger.warning('خطأ في قياس استخدام الذاكرة: $e');
      return 0;
    }
  }

  /// بدء مراقبة الذاكرة
  static void startMemoryMonitoring() {
    try {
      _initialMemoryUsage = getCurrentMemoryUsage();
      _peakMemoryUsage = _initialMemoryUsage;

      _memoryMonitoringTimer?.cancel();
      _memoryMonitoringTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _monitorMemoryUsage(),
      );

      _logger.info(
          'بدء مراقبة الذاكرة - الاستخدام الأولي: ${_initialMemoryUsage}MB');
    } on Exception catch (e) {
      _logger.warning('خطأ في بدء مراقبة الذاكرة: $e');
    }
  }

  /// إيقاف مراقبة الذاكرة
  static void stopMemoryMonitoring() {
    try {
      _memoryMonitoringTimer?.cancel();
      _memoryMonitoringTimer = null;
      _logger.info('تم إيقاف مراقبة الذاكرة');
    } on Exception catch (e) {
      _logger.warning('خطأ في إيقاف مراقبة الذاكرة: $e');
    }
  }

  /// مراقبة دورية للذاكرة
  static void _monitorMemoryUsage() {
    try {
      final int currentMemory = getCurrentMemoryUsage();

      // تحذير عند استخدام ذاكرة عالية
      if (currentMemory > 500) {
        // أكثر من 500MB
        _logger.warning('استخدام ذاكرة عالي: ${currentMemory}MB');

        // تشغيل تنظيف الكاش
        CacheService.performPeriodicCleanup();

        // استدعاء خدمة إدارة الذاكرة المحسنة
        MemoryManagementService.performMemoryCleanup();
      }
    } on Exception catch (e) {
      _logger.warning('خطأ في المراقبة الدورية للذاكرة: $e');
    }
  }

  /// تسجيل طلب شبكة
  static void recordNetworkRequest(Duration duration, {bool hasError = false}) {
    try {
      _networkRequestCount++;
      _totalNetworkTime += duration;

      if (hasError) {
        _networkErrorCount++;
      }

      // تحذير للطلبات البطيئة
      if (duration.inSeconds > 10) {
        _logger.warning('طلب شبكة بطيء استغرق ${duration.inSeconds}s');
      }
    } on Exception catch (e) {
      _logger.warning('خطأ في تسجيل طلب الشبكة: $e');
    }
  }

  /// الحصول على تقرير شامل للأداء
  static Map<String, dynamic> getPerformanceReport() {
    try {
      final int currentMemory = getCurrentMemoryUsage();
      final int memoryIncrease = currentMemory - _initialMemoryUsage;

      // حساب متوسط أوقات العمليات
      final Map<String, double> avgOperationTimes = <String, double>{};
      _operationCounts.forEach((String operation, int count) {
        final Duration totalTime =
            _operationTotalTime[operation] ?? Duration.zero;
        avgOperationTimes[operation] = totalTime.inMilliseconds / count;
      });

      // معدل نجاح الشبكة
      final double networkSuccessRate = _networkRequestCount > 0
          ? ((_networkRequestCount - _networkErrorCount) /
              _networkRequestCount *
              100)
          : 100.0;

      // متوسط وقت الشبكة
      final double avgNetworkTime = _networkRequestCount > 0
          ? _totalNetworkTime.inMilliseconds / _networkRequestCount
          : 0.0;

      return <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'memory': <String, Object>{
          'current': currentMemory,
          'initial': _initialMemoryUsage,
          'peak': _peakMemoryUsage,
          'increase': memoryIncrease,
          'increasePercent': _initialMemoryUsage > 0
              ? (memoryIncrease / _initialMemoryUsage * 100).toStringAsFixed(1)
              : '0.0',
        },
        'operations': <String, Object>{
          'counts': Map<String, int>.from(_operationCounts),
          'lastDurations': _operationDurations.map(
            (String key, Duration value) => MapEntry(key, value.inMilliseconds),
          ),
          'averageDurations': avgOperationTimes,
          'totalOperations': _operationCounts.values
              .fold<int>(0, (int sum, int count) => sum + count),
        },
        'network': <String, Object>{
          'requestCount': _networkRequestCount,
          'errorCount': _networkErrorCount,
          'successRate': networkSuccessRate.toStringAsFixed(1),
          'averageTime': avgNetworkTime.toStringAsFixed(1),
          'totalTime': _totalNetworkTime.inMilliseconds,
        },
        'cache': CacheService.getCacheStats(),
      };
    } on Exception catch (e) {
      _logger.severe('خطأ في إنشاء تقرير الأداء: $e');
      return <String, dynamic>{'error': 'فشل في إنشاء تقرير الأداء'};
    }
  }

  /// طباعة تقرير الأداء في وحدة التحكم
  static void printPerformanceReport() {
    try {
      final Map<String, dynamic> report = getPerformanceReport();

      debugPrint('═══════════════════════════════════════');
      debugPrint('         تقرير أداء التطبيق');
      debugPrint('═══════════════════════════════════════');

      final Map<String, dynamic> memory =
          report['memory'] as Map<String, dynamic>;
      debugPrint('الذاكرة:');
      debugPrint('  الحالية: ${memory['current']}MB');
      debugPrint('  الذروة: ${memory['peak']}MB');
      debugPrint(
          '  الزيادة: ${memory['increase']}MB (${memory['increasePercent']}%)');

      final Map<String, dynamic> operations =
          report['operations'] as Map<String, dynamic>;
      debugPrint('\nالعمليات:');
      debugPrint('  إجمالي العمليات: ${operations['totalOperations']}');

      final Map<String, double> avgDurations =
          operations['averageDurations'] as Map<String, double>;
      if (avgDurations.isNotEmpty) {
        debugPrint('  متوسط الأوقات:');
        avgDurations.forEach((String operation, double avgTime) {
          debugPrint('    $operation: ${avgTime.toStringAsFixed(1)}ms');
        });
      }

      final Map<String, dynamic> network =
          report['network'] as Map<String, dynamic>;
      debugPrint('\nالشبكة:');
      debugPrint('  عدد الطلبات: ${network['requestCount']}');
      debugPrint('  معدل النجاح: ${network['successRate']}%');
      debugPrint('  متوسط الوقت: ${network['averageTime']}ms');

      final Map<String, dynamic> cache =
          report['cache'] as Map<String, dynamic>;
      debugPrint('\nالتخزين المؤقت:');
      debugPrint('  معدل النجاح: ${cache['hitRatio']}%');
      debugPrint('  حجم المنتجات: ${cache['productCacheSize']}');
      debugPrint('  حجم المخزون: ${cache['inventoryCacheSize']}');

      debugPrint('═══════════════════════════════════════');
    } on Exception catch (e) {
      _logger.severe('خطأ في طباعة تقرير الأداء: $e');
    }
  }

  /// إعادة تعيين جميع المقاييس
  static void resetMetrics() {
    try {
      _operationStartTimes.clear();
      _operationDurations.clear();
      _operationCounts.clear();
      _operationTotalTime.clear();

      _networkRequestCount = 0;
      _networkErrorCount = 0;
      _totalNetworkTime = Duration.zero;

      _initialMemoryUsage = getCurrentMemoryUsage();
      _peakMemoryUsage = _initialMemoryUsage;

      CacheService.resetCacheStats();

      _logger.info('تم إعادة تعيين جميع مقاييس الأداء');
    } on Exception catch (e) {
      _logger.warning('خطأ في إعادة تعيين المقاييس: $e');
    }
  }

  /// تهيئة خدمة الأداء
  static void initialize() {
    try {
      resetMetrics();
      startMemoryMonitoring();
      CacheService.startPeriodicCleanup();

      _logger.info('تم تهيئة خدمة مراقبة الأداء');
    } on Exception catch (e) {
      _logger.severe('خطأ في تهيئة خدمة الأداء: $e');
    }
  }

  /// إنهاء خدمة الأداء
  static void dispose() {
    try {
      stopMemoryMonitoring();
      CacheService.stopPeriodicCleanup();

      _logger.info('تم إنهاء خدمة مراقبة الأداء');
    } on Exception catch (e) {
      _logger.warning('خطأ في إنهاء خدمة الأداء: $e');
    }
  }
}

/// فئة مساعدة لقياس أوقات العمليات
class PerformanceTimer {
  PerformanceTimer(this.operationName) {
    PerformanceService.startOperation(operationName);
  }
  final String operationName;

  void stop() {
    PerformanceService.endOperation(operationName);
  }
}

/// Mixin لتسهيل مراقبة الأداء في الـ widgets
mixin PerformanceMixin {
  PerformanceTimer startPerformanceTimer(String operationName) =>
      PerformanceTimer(operationName);
}
