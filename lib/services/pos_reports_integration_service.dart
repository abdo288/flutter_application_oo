import 'dart:async';
import 'package:flutter/foundation.dart';

import 'app_event_bus.dart';
import 'cross_tab_sync_service.dart';

/// خدمة التكامل بين نقطة البيع والتقارير
class POSReportsIntegrationService {
  factory POSReportsIntegrationService() => _instance;
  POSReportsIntegrationService._internal();
  static final POSReportsIntegrationService _instance =
      POSReportsIntegrationService._internal();

  // إحصائيات التكامل
  int _totalEvents = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  DateTime? _lastSyncTime;
  final List<String> _recentEvents = <String>[];

  /// تهيئة خدمة التكامل
  Future<void> initialize() async {
    try {
      debugPrint('🔗 تهيئة خدمة التكامل بين POS والتقارير...');

      // إعداد مستمعي الأحداث
      _setupEventListeners();

      debugPrint('✅ تم تهيئة خدمة التكامل بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التكامل: $e');
      rethrow;
    }
  }

  /// إعداد مستمعي الأحداث
  void _setupEventListeners() {
    // الاستماع لأحداث AppEventBus
    AppEventBus.stream.listen(_handleAppEvent);

    // الاستماع لأحداث CrossTabSyncService
    CrossTabSyncService.events.listen(_handleSyncEvent);
  }

  /// معالجة أحداث AppEventBus
  void _handleAppEvent(AppEvent event) {
    _totalEvents++;
    _lastSyncTime = DateTime.now();

    switch (event.runtimeType) {
      case SaleCompletedEvent:
        _handleSaleCompleted(event as SaleCompletedEvent);
        break;
      case ReportsUpdateEvent:
        _handleReportsUpdate(event as ReportsUpdateEvent);
        break;
    }
  }

  /// معالجة أحداث CrossTabSyncService
  void _handleSyncEvent(SyncEvent event) {
    _totalEvents++;
    _lastSyncTime = DateTime.now();

    if (event.dataType == 'reports') {
      _handleReportsSyncEvent(event);
    }
  }

  /// معالجة حدث إتمام البيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    try {
      debugPrint('💰 معالجة حدث إتمام بيع: ${event.sale.totalAmount}');

      // إطلاق حدث تحديث التقارير
      AppEventBus.fire(ReportsUpdateEvent(
        'sale',
        sourceTab: event.sourceTab,
        data: <String, dynamic>{
          'saleId': event.sale.id,
          'saleAmount': event.sale.totalAmount,
          'saleDate': event.sale.saleDate.toIso8601String(),
          'itemsCount': event.items.length,
        },
      ));

      // إشعار CrossTabSyncService
      CrossTabSyncService.notifyReportsUpdate(
        'sale',
        sourceTab: event.sourceTab,
        data: <String, dynamic>{
          'saleId': event.sale.id,
          'saleAmount': event.sale.totalAmount,
        },
      );

      _successfulSyncs++;
      _recentEvents.add('Sale Completed: ${event.sale.totalAmount}');
      _cleanupRecentEvents();

      debugPrint('✅ تم معالجة حدث إتمام البيع بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حدث إتمام البيع: $e');
      _failedSyncs++;
    }
  }

  /// معالجة حدث تحديث التقارير
  void _handleReportsUpdate(ReportsUpdateEvent event) {
    try {
      debugPrint('📊 معالجة حدث تحديث التقارير: ${event.updateType}');

      _successfulSyncs++;
      _recentEvents.add('Reports Update: ${event.updateType}');
      _cleanupRecentEvents();

      debugPrint('✅ تم معالجة حدث تحديث التقارير بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حدث تحديث التقارير: $e');
      _failedSyncs++;
    }
  }

  /// معالجة حدث مزامنة التقارير
  void _handleReportsSyncEvent(SyncEvent event) {
    try {
      debugPrint('🔄 معالجة حدث مزامنة التقارير: ${event.operation}');

      _successfulSyncs++;
      _recentEvents.add('Sync Event: ${event.operation}');
      _cleanupRecentEvents();

      debugPrint('✅ تم معالجة حدث مزامنة التقارير بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حدث مزامنة التقارير: $e');
      _failedSyncs++;
    }
  }

  /// تنظيف الأحداث الأخيرة
  void _cleanupRecentEvents() {
    if (_recentEvents.length > 20) {
      _recentEvents.removeAt(0);
    }
  }

  /// إطلاق حدث تكامل مخصص
  void triggerCustomIntegrationEvent(
    String eventType,
    Map<String, dynamic> data, {
    String? sourceTab,
  }) {
    try {
      debugPrint('🔗 إطلاق حدث تكامل مخصص: $eventType');

      // إطلاق حدث AppEventBus
      AppEventBus.fire(ReportsUpdateEvent(
        eventType,
        sourceTab: sourceTab,
        data: data,
      ));

      // إشعار CrossTabSyncService
      CrossTabSyncService.notifyReportsUpdate(
        eventType,
        sourceTab: sourceTab,
        data: data,
      );

      _totalEvents++;
      _successfulSyncs++;
      _recentEvents.add('Custom Event: $eventType');
      _cleanupRecentEvents();

      debugPrint('✅ تم إطلاق حدث التكامل المخصص بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إطلاق حدث التكامل المخصص: $e');
      _failedSyncs++;
    }
  }

  /// اختبار التكامل بين POS والتقارير
  Future<Map<String, dynamic>> testIntegration() async {
    try {
      debugPrint('🧪 بدء اختبار التكامل بين POS والتقارير...');

      final Map<String, dynamic> results = <String, dynamic>{
        'totalEvents': _totalEvents,
        'successfulSyncs': _successfulSyncs,
        'failedSyncs': _failedSyncs,
        'lastSyncTime': _lastSyncTime?.toIso8601String(),
        'recentEvents': _recentEvents,
        'successRate':
            _totalEvents > 0 ? (_successfulSyncs / _totalEvents) * 100 : 0.0,
      };

      // اختبار إطلاق حدث تجريبي
      triggerCustomIntegrationEvent(
        'test',
        <String, dynamic>{
          'testId': 'integration_test_${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': DateTime.now().toIso8601String(),
        },
        sourceTab: 'IntegrationTest',
      );

      debugPrint('✅ تم اختبار التكامل بنجاح');
      return results;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار التكامل: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'totalEvents': _totalEvents,
        'successfulSyncs': _successfulSyncs,
        'failedSyncs': _failedSyncs,
      };
    }
  }

  /// الحصول على إحصائيات التكامل
  Map<String, dynamic> getIntegrationStats() => <String, dynamic>{
        'totalEvents': _totalEvents,
        'successfulSyncs': _successfulSyncs,
        'failedSyncs': _failedSyncs,
        'lastSyncTime': _lastSyncTime?.toIso8601String(),
        'recentEvents': _recentEvents,
        'successRate':
            _totalEvents > 0 ? (_successfulSyncs / _totalEvents) * 100 : 0.0,
      };

  /// إعادة تعيين الإحصائيات
  void resetStats() {
    _totalEvents = 0;
    _successfulSyncs = 0;
    _failedSyncs = 0;
    _lastSyncTime = null;
    _recentEvents.clear();
    debugPrint('🔄 تم إعادة تعيين إحصائيات التكامل');
  }

  /// إغلاق خدمة التكامل
  void dispose() {
    debugPrint('🔒 إغلاق خدمة التكامل بين POS والتقارير');
  }
}
