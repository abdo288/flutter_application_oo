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
class CrossTabSyncService {
  CrossTabSyncService._();
  static CrossTabSyncService? _instance;
  static CrossTabSyncService get instance => _instance ??= CrossTabSyncService._();

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

  // ========== إدارة الأحداث ==========

  /// إشعار التبويبات الأخرى بتغيير البيانات
  static void notifyDataChanged(
    String dataType,
    String operation,
    String id, {
    Map<String, dynamic>? data,
  }) {
    try {
      final SyncEvent event = SyncEvent(
        dataType: dataType,
        operation: operation,
        id: id,
        data: data,
      );

      _eventController.add(event);
      
      // تحديث الإحصائيات
      instance._eventCount++;
      instance._lastEventTime = DateTime.now();
      instance._recentEvents.add(event);
      
      // الاحتفاظ بآخر 50 حدث فقط
      if (instance._recentEvents.length > 50) {
        instance._recentEvents.removeAt(0);
      }

      debugPrint('🔄 CrossTab: تم إشعار التبويبات بتغيير $dataType.$operation:$id');
    } catch (e) {
      debugPrint('❌ خطأ في إشعار التبويبات: $e');
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
  static Stream<SyncEvent> get events => _eventController.stream;

  /// Stream لحالة المزامنة
  static Stream<Map<String, dynamic>> get statusUpdates => _statusController.stream;

  // ========== إدارة الحالة ==========

  /// الحصول على إحصائيات الخدمة
  Map<String, dynamic> getStats() => {
      'eventCount': _eventCount,
      'lastEventTime': _lastEventTime?.toIso8601String(),
      'recentEventsCount': _recentEvents.length,
      'isActive': _eventController.hasListener,
    };

  /// الحصول على الأحداث الأخيرة
  List<SyncEvent> getRecentEvents({int limit = 10}) {
    final int startIndex = _recentEvents.length - limit;
    return startIndex >= 0 
        ? _recentEvents.sublist(startIndex)
        : _recentEvents;
  }

  /// تنظيف الأحداث القديمة
  void cleanupOldEvents({Duration olderThan = const Duration(hours: 1)}) {
    final DateTime cutoff = DateTime.now().subtract(olderThan);
    _recentEvents.removeWhere((SyncEvent event) => event.timestamp.isBefore(cutoff));
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
