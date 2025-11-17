import 'dart:async';
import 'package:flutter/foundation.dart';

/// نموذج حدث التزامن بين التبويبات
class SyncEvent {
  SyncEvent({
    required this.dataType,
    required this.operation,
    required this.id,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();
  final String dataType; // 'product', 'inventory', 'sale'
  final String operation; // 'add', 'update', 'delete'
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  @override
  String toString() => 'SyncEvent($dataType.$operation:$id)';
}

/// خدمة التزامن بين التبويبات للتحديثات الفورية
/// ✅ محسنة لدعم المزامنة بين التبويبات والنوافذ المتعددة
class CrossTabSyncService {
  CrossTabSyncService._();
  static CrossTabSyncService? _instance;
  static CrossTabSyncService get instance =>
      _instance ??= CrossTabSyncService._();

  // Stream controller للأحداث
  static final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();

  // Stream controller للحالة
  static final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // إحصائيات
  int _eventCount = 0;
  DateTime? _lastEventTime;
  final List<SyncEvent> _recentEvents = <SyncEvent>[];
  
  // ✅ تتبع المستمعين النشطين لضمان المزامنة
  int _activeListeners = 0;
  final Map<String, DateTime> _lastSyncByTab = <String, DateTime>{};

  // ========== إدارة الأحداث ==========

  /// إشعار التبويبات الأخرى بتغيير البيانات
  /// ✅ محسنة لضمان وصول الأحداث لجميع التبويبات والنوافذ
  static void notifyDataChanged(
    String dataType,
    String operation,
    String id, {
    Map<String, dynamic>? data,
    String? sourceTab,
  }) {
    try {
      final SyncEvent event = SyncEvent(
        dataType: dataType,
        operation: operation,
        id: id,
        data: <String, dynamic>{
          ...?data,
          'sourceTab': sourceTab,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // ✅ إرسال الحدث مع معلومات إضافية
      _eventController.add(event);

      // تحديث الإحصائيات
      instance._eventCount++;
      instance._lastEventTime = DateTime.now();
      instance._recentEvents.add(event);
      
      // ✅ تحديث آخر وقت مزامنة للتبويب المصدر
      if (sourceTab != null) {
        instance._lastSyncByTab[sourceTab] = DateTime.now();
      }

      // الاحتفاظ بآخر 50 حدث فقط
      if (instance._recentEvents.length > 50) {
        instance._recentEvents.removeAt(0);
      }

      // ✅ تسجيل عدد المستمعين النشطين
      final int listenerCount = instance._activeListeners;
      debugPrint(
          '🔄 CrossTab: تم إشعار $listenerCount مستمع بتغيير $dataType.$operation:$id (من: $sourceTab)');
    } catch (e) {
      debugPrint('❌ خطأ في إشعار التبويبات: $e');
    }
  }

  /// إشعار التبويبات بتحديث التقارير
  static void notifyReportsUpdate(
    String updateType, {
    String? sourceTab,
    Map<String, dynamic>? data,
  }) {
    try {
      final SyncEvent event = SyncEvent(
        dataType: 'reports',
        operation: 'update',
        id: 'reports_${DateTime.now().millisecondsSinceEpoch}',
        data: <String, dynamic>{
          'updateType': updateType,
          'sourceTab': sourceTab,
          ...?data,
        },
      );

      _eventController.add(event);
      debugPrint(
          '📊 CrossTab: تم إشعار التبويبات بتحديث التقارير: $updateType');
    } catch (e) {
      debugPrint('❌ خطأ في إشعار تحديث التقارير: $e');
    }
  }

  /// إشعار التبويبات بتحديث حالة المزامنة
  static void notifySyncStatus(Map<String, dynamic> status) {
    try {
      _statusController.add(status);
      debugPrint('📊 CrossTab: تم إشعار التبويبات بحالة المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في إشعار حالة المزامنة: $e');
    }
  }

  // ========== Streams ==========

  /// Stream للأحداث
  /// ✅ محسن لضمان وصول الأحداث لجميع المستمعين
  static Stream<SyncEvent> get events {
    // ✅ زيادة عدد المستمعين عند الاشتراك
    instance._activeListeners++;
    debugPrint('📡 CrossTab: مستمع جديد - إجمالي: ${instance._activeListeners}');
    
    return _eventController.stream.map((SyncEvent event) {
      // ✅ تحديث آخر وقت استقبال للتبويب
      if (event.data != null && event.data!['sourceTab'] != null) {
        final String? sourceTab = event.data!['sourceTab'] as String?;
        if (sourceTab != null) {
          instance._lastSyncByTab[sourceTab] = DateTime.now();
        }
      }
      return event;
    });
  }

  /// Stream لحالة المزامنة
  static Stream<Map<String, dynamic>> get statusUpdates =>
      _statusController.stream;
  
  /// ✅ تسجيل إلغاء الاشتراك
  static void unregisterListener() {
    if (instance._activeListeners > 0) {
      instance._activeListeners--;
      debugPrint('📡 CrossTab: إلغاء اشتراك - المتبقي: ${instance._activeListeners}');
    }
  }

  // ========== إدارة الحالة ==========

  /// الحصول على إحصائيات الخدمة
  /// ✅ محسنة لتشمل معلومات عن التبويبات النشطة
  Map<String, dynamic> getStats() => <String, dynamic>{
        'eventCount': _eventCount,
        'lastEventTime': _lastEventTime?.toIso8601String(),
        'recentEventsCount': _recentEvents.length,
        'isActive': _eventController.hasListener,
        'activeListeners': _activeListeners,
        'tabsWithRecentSync': _lastSyncByTab.length,
        'lastSyncByTab': _lastSyncByTab.map(
          (String key, DateTime value) => MapEntry(
            key,
            value.toIso8601String(),
          ),
        ),
      };

  /// الحصول على الأحداث الأخيرة
  List<SyncEvent> getRecentEvents({int limit = 10}) {
    final int startIndex = _recentEvents.length - limit;
    return startIndex >= 0 ? _recentEvents.sublist(startIndex) : _recentEvents;
  }

  /// تنظيف الأحداث القديمة
  void cleanupOldEvents({Duration olderThan = const Duration(hours: 1)}) {
    final DateTime cutoff = DateTime.now().subtract(olderThan);
    _recentEvents
        .removeWhere((SyncEvent event) => event.timestamp.isBefore(cutoff));
    debugPrint('🧹 تم تنظيف الأحداث القديمة');
  }

  // ========== إغلاق الخدمة ==========

  /// إغلاق الخدمة
  static void dispose() {
    _eventController.close();
    _statusController.close();
    debugPrint('🔒 تم إغلاق خدمة التزامن بين التبويبات');
  }

  // ========== دوال مساعدة ==========

  /// التحقق من وجود مستمعين
  bool get hasListeners => _eventController.hasListener;

  /// إعادة تعيين الإحصائيات
  void resetStats() {
    _eventCount = 0;
    _lastEventTime = null;
    _recentEvents.clear();
    debugPrint('🔄 تم إعادة تعيين إحصائيات خدمة التزامن');
  }
}
