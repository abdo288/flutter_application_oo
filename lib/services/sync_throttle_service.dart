import 'dart:async';
import 'package:flutter/foundation.dart';

/// خدمة منع المزامنة المتكررة (Throttling)
/// تمنع استدعاء عمليات المزامنة بشكل متكرر في فترة زمنية قصيرة
class SyncThrottleService {
  factory SyncThrottleService() => _instance;
  SyncThrottleService._internal();
  static final SyncThrottleService _instance = SyncThrottleService._internal();

  // مؤقتات المزامنة لكل نوع
  final Map<String, DateTime> _lastSyncTimes = <String, DateTime>{};
  final Map<String, Timer?> _activeTimers = <String, Timer?>{};

  // الحد الأدنى للوقت بين المزامنات (بالثواني)
  static const Map<String, int> _syncIntervals = <String, int>{
    'full_sync': 30, // 30 ثانية للمزامنة الكاملة
    'products_sync': 15, // 15 ثانية لمزامنة المنتجات
    'inventory_sync': 15, // 15 ثانية لمزامنة المخزون
    'dashboard_refresh': 10, // 10 ثواني لتحديث لوحة التحكم
    'auto_refresh': 60, // دقيقة واحدة للتحديث التلقائي
  };

  /// التحقق من إمكانية المزامنة
  bool canSync(String syncType) {
    final DateTime now = DateTime.now();
    final DateTime? lastSync = _lastSyncTimes[syncType];

    if (lastSync == null) {
      return true;
    }

    final int intervalSeconds = _syncIntervals[syncType] ?? 30;
    final Duration timeSinceLastSync = now.difference(lastSync);

    return timeSinceLastSync.inSeconds >= intervalSeconds;
  }

  /// تسجيل وقت المزامنة
  void recordSync(String syncType) {
    _lastSyncTimes[syncType] = DateTime.now();
    debugPrint('🕒 تم تسجيل مزامنة $syncType في ${DateTime.now()}');
  }

  /// جدولة مزامنة مؤجلة
  Future<void> scheduleSync(
      String syncType, Future<void> Function() syncFunction) async {
    // إلغاء المؤقت السابق إذا كان موجوداً
    _activeTimers[syncType]?.cancel();

    if (canSync(syncType)) {
      // تنفيذ المزامنة فوراً
      await _executeSync(syncType, syncFunction);
    } else {
      // جدولة المزامنة للوقت المناسب
      final DateTime? lastSync = _lastSyncTimes[syncType];
      final int intervalSeconds = _syncIntervals[syncType] ?? 30;

      if (lastSync != null) {
        final DateTime nextSyncTime =
            lastSync.add(Duration(seconds: intervalSeconds));
        final Duration delay = nextSyncTime.difference(DateTime.now());

        if (delay.inMilliseconds > 0) {
          debugPrint('⏰ جدولة مزامنة $syncType بعد ${delay.inSeconds} ثانية');
          // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
          scheduleMicrotask(() {
            _activeTimers[syncType] = Timer(delay, () async {
              await _executeSync(syncType, syncFunction);
            });
          });
        }
      }
    }
  }

  /// تنفيذ المزامنة مع الحماية
  Future<void> _executeSync(
      String syncType, Future<void> Function() syncFunction) async {
    try {
      debugPrint('🔄 بدء مزامنة $syncType');
      await syncFunction();
      recordSync(syncType);
      debugPrint('✅ تمت مزامنة $syncType بنجاح');
    } catch (e) {
      debugPrint('❌ فشل في مزامنة $syncType: $e');
      // إعادة جدولة المزامنة بعد فترة أطول في حالة الفشل
      scheduleMicrotask(() {
        _activeTimers[syncType] = Timer(const Duration(minutes: 2), () async {
          await _executeSync(syncType, syncFunction);
        });
      });
    }
  }

  /// إلغاء جميع المؤقتات
  void cancelAllTimers() {
    for (final Timer? timer in _activeTimers.values) {
      timer?.cancel();
    }
    _activeTimers.clear();
    debugPrint('🛑 تم إلغاء جميع مؤقتات المزامنة');
  }

  /// إلغاء مؤقت محدد
  void cancelTimer(String syncType) {
    _activeTimers[syncType]?.cancel();
    _activeTimers.remove(syncType);
    debugPrint('🛑 تم إلغاء مؤقت مزامنة $syncType');
  }

  /// الحصول على إحصائيات المزامنة
  Map<String, dynamic> getSyncStats() {
    final Map<String, dynamic> stats = <String, dynamic>{};

    for (final String syncType in _syncIntervals.keys) {
      final DateTime? lastSync = _lastSyncTimes[syncType];
      final bool canSyncNow = canSync(syncType);
      final bool hasActiveTimer = _activeTimers[syncType] != null;

      stats[syncType] = <String, dynamic>{
        'lastSync': lastSync?.toIso8601String(),
        'canSyncNow': canSyncNow,
        'hasActiveTimer': hasActiveTimer,
        'intervalSeconds': _syncIntervals[syncType],
      };
    }

    return stats;
  }

  /// إعادة تعيين جميع المؤقتات
  void reset() {
    cancelAllTimers();
    _lastSyncTimes.clear();
    debugPrint('🔄 تم إعادة تعيين خدمة Throttling');
  }
}
