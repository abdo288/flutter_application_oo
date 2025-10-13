import 'dart:async';
import 'package:logging/logging.dart';

/// خدمة تنسيق المزامنة لمنع التكرار وتحسين الأداء
class SyncCoordinationService {
  static final Logger _logger = Logger('SyncCoordinationService');

  // متغيرات التنسيق
  static bool _isInitializing = false;
  static bool _isFullSyncRunning = false;
  static bool _isDeltaSyncRunning = false;
  static DateTime? _lastFullSync;
  static DateTime? _lastDeltaSync;

  // قفل المزامنة
  static Timer? _syncThrottleTimer;

  // إعدادات المزامنة - تحسين لتقليل استهلاك الذاكرة
  static const Duration _minSyncInterval = Duration(minutes: 2);
  static const Duration _maxSyncInterval = Duration(minutes: 10);
  static const Duration _throttleDuration = Duration(minutes: 1);

  /// التحقق من إمكانية بدء مزامنة كاملة
  static bool canStartFullSync() {
    if (_isInitializing || _isFullSyncRunning) {
      _logger.warning('مزامنة كاملة قيد التشغيل بالفعل');
      return false;
    }

    if (_lastFullSync != null) {
      final Duration timeSinceLastSync =
          DateTime.now().difference(_lastFullSync!);
      if (timeSinceLastSync < _minSyncInterval) {
        _logger.warning(
            'مزامنة كاملة حديثة جداً، انتظر ${_minSyncInterval.inSeconds - timeSinceLastSync.inSeconds} ثانية');
        return false;
      }
    }

    return true;
  }

  /// التحقق من إمكانية بدء مزامنة تفاضلية
  static bool canStartDeltaSync() {
    if (_isInitializing || _isDeltaSyncRunning) {
      _logger.warning('مزامنة تفاضلية قيد التشغيل بالفعل');
      return false;
    }

    if (_lastDeltaSync != null) {
      final Duration timeSinceLastSync =
          DateTime.now().difference(_lastDeltaSync!);
      if (timeSinceLastSync < _throttleDuration) {
        _logger.warning(
            'مزامنة تفاضلية حديثة جداً، انتظر ${_throttleDuration.inSeconds - timeSinceLastSync.inSeconds} ثانية');
        return false;
      }
    }

    return true;
  }

  /// بدء مزامنة كاملة مع تنسيق
  static Future<bool> startFullSync(
      Future<void> Function() syncFunction) async {
    if (!canStartFullSync()) {
      return false;
    }

    try {
      _isFullSyncRunning = true;
      _lastFullSync = DateTime.now();

      _logger.info('بدء مزامنة كاملة');
      await syncFunction();
      _logger.info('تمت المزامنة الكاملة بنجاح');

      return true;
    } on Exception catch (e) {
      _logger.severe('فشل في المزامنة الكاملة: $e');
      return false;
    } finally {
      _isFullSyncRunning = false;
    }
  }

  /// بدء مزامنة تفاضلية مع تنسيق
  static Future<bool> startDeltaSync(
      Future<void> Function() syncFunction) async {
    if (!canStartDeltaSync()) {
      return false;
    }

    try {
      _isDeltaSyncRunning = true;
      _lastDeltaSync = DateTime.now();

      _logger.info('بدء مزامنة تفاضلية');
      await syncFunction();
      _logger.info('تمت المزامنة التفاضلية بنجاح');

      return true;
    } on Exception catch (e) {
      _logger.severe('فشل في المزامنة التفاضلية: $e');
      return false;
    } finally {
      _isDeltaSyncRunning = false;
    }
  }

  /// بدء التهيئة مع تنسيق
  static Future<bool> startInitialization(
      Future<void> Function() initFunction) async {
    if (_isInitializing) {
      _logger.warning('التهيئة قيد التشغيل بالفعل');
      return false;
    }

    try {
      _isInitializing = true;
      _logger.info('بدء تهيئة التطبيق');
      await initFunction();
      _logger.info('تمت التهيئة بنجاح');

      return true;
    } on Exception catch (e) {
      _logger.severe('فشل في التهيئة: $e');
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// إعادة تعيين حالة المزامنة
  static void resetSyncState() {
    _isInitializing = false;
    _isFullSyncRunning = false;
    _isDeltaSyncRunning = false;
    _lastFullSync = null;
    _lastDeltaSync = null;
    _syncThrottleTimer?.cancel();
    _syncThrottleTimer = null;

    _logger.info('تم إعادة تعيين حالة المزامنة');
  }

  /// الحصول على حالة المزامنة
  static Map<String, dynamic> getSyncState() => <String, dynamic>{
        'isInitializing': _isInitializing,
        'isFullSyncRunning': _isFullSyncRunning,
        'isDeltaSyncRunning': _isDeltaSyncRunning,
        'lastFullSync': _lastFullSync?.toIso8601String(),
        'lastDeltaSync': _lastDeltaSync?.toIso8601String(),
        'canStartFullSync': canStartFullSync(),
        'canStartDeltaSync': canStartDeltaSync(),
      };

  /// بدء مزامنة مع throttling
  static void scheduleThrottledSync(Future<void> Function() syncFunction) {
    _syncThrottleTimer?.cancel();
    // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
    scheduleMicrotask(() {
      _syncThrottleTimer = Timer(_throttleDuration, () async {
        await startDeltaSync(syncFunction);
      });
    });
  }

  /// إيقاف جميع عمليات المزامنة
  static void stopAllSync() {
    _syncThrottleTimer?.cancel();
    _syncThrottleTimer = null;
    resetSyncState();
    _logger.info('تم إيقاف جميع عمليات المزامنة');
  }

  /// التحقق من الحاجة لمزامنة كاملة
  static bool needsFullSync() {
    if (_lastFullSync == null) return true;

    final Duration timeSinceLastSync =
        DateTime.now().difference(_lastFullSync!);
    return timeSinceLastSync > _maxSyncInterval;
  }

  /// التحقق من الحاجة لمزامنة تفاضلية
  static bool needsDeltaSync() {
    if (_lastDeltaSync == null) return true;

    final Duration timeSinceLastSync =
        DateTime.now().difference(_lastDeltaSync!);
    return timeSinceLastSync > _throttleDuration;
  }
}
