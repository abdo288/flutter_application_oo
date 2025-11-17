import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import 'app_event_bus.dart';
import 'tab_coordination_service.dart';

/// خدمة تنسيق متقدمة بين تبويب نموذج المنتج وتبويب المخزون
/// ✅ ضمان التناسق التام والوظائف المتقدمة
class InventoryTabCoordinationService {
  factory InventoryTabCoordinationService() => _instance;
  InventoryTabCoordinationService._internal();
  static final InventoryTabCoordinationService _instance =
      InventoryTabCoordinationService._internal();

  final StreamController<InventoryCoordinationEvent> _coordinationController =
      StreamController<InventoryCoordinationEvent>.broadcast();

  Stream<InventoryCoordinationEvent> get coordinationStream =>
      _coordinationController.stream;

  Timer? _syncTimer;
  bool _isSyncing = false;
  final List<InventoryCoordinationEvent> _pendingEvents = <InventoryCoordinationEvent>[];

  /// بدء مراقبة التنسيق
  void startCoordination() {
    debugPrint('🔄 بدء تنسيق تبويبات المخزون...');

    // فحص التنسيق كل 5 ثوان
    _syncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performSyncCheck(),
    );
  }

  /// إيقاف مراقبة التنسيق
  void stopCoordination() {
    debugPrint('⏹️ إيقاف تنسيق تبويبات المخزون');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// فحص التنسيق
  Future<void> _performSyncCheck() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      // معالجة الأحداث المعلقة
      if (_pendingEvents.isNotEmpty) {
        debugPrint('🔄 معالجة ${_pendingEvents.length} حدث معلق');
        for (final InventoryCoordinationEvent event in _pendingEvents) {
          await _processCoordinationEvent(event);
        }
        _pendingEvents.clear();
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص التنسيق: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// معالجة حدث التنسيق
  Future<void> _processCoordinationEvent(
      InventoryCoordinationEvent event) async {
    try {
      switch (event.runtimeType) {
        case InventoryDataSyncEvent:
          await _handleDataSync(event as InventoryDataSyncEvent);
          break;
        case InventoryFilterSyncEvent:
          await _handleFilterSync(event as InventoryFilterSyncEvent);
          break;
        case InventorySortSyncEvent:
          await _handleSortSync(event as InventorySortSyncEvent);
          break;
        case InventoryErrorSyncEvent:
          await _handleErrorSync(event as InventoryErrorSyncEvent);
          break;
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حدث التنسيق: $e');
    }
  }

  /// معالجة مزامنة البيانات
  Future<void> _handleDataSync(InventoryDataSyncEvent event) async {
    debugPrint('🔄 مزامنة بيانات المخزون: ${event.operation}');

    // إرسال حدث AppEventBus للتحديث الفوري
    switch (event.operation) {
      case 'add':
        AppEventBus.fire(InventoryItemAddedEvent(
          event.inventoryItem!,
          sourceTab: event.sourceTab,
        ));
        break;
      case 'update':
        AppEventBus.fire(InventoryUpdatedEvent(
          event.inventoryItem!.id!,
          event.inventoryItem!.name,
          event.oldQuantity ?? 0,
          event.inventoryItem!.quantity,
          sourceTab: event.sourceTab,
        ));
        break;
      case 'delete':
        AppEventBus.fire(InventoryItemDeletedEvent(
          event.inventoryItem!.id!,
          event.inventoryItem!.name,
          sourceTab: event.sourceTab,
        ));
        break;
    }
  }

  /// معالجة مزامنة الفلترة
  Future<void> _handleFilterSync(InventoryFilterSyncEvent event) async {
    debugPrint('🔄 مزامنة فلترة المخزون: ${event.searchQuery}');

    // تنسيق البحث بين التبويبين
    TabCoordinationService().coordinateSearchUpdate(
      searchQuery: event.searchQuery,
      sourceTab: event.sourceTab,
    );
  }

  /// معالجة مزامنة الترتيب
  Future<void> _handleSortSync(InventorySortSyncEvent event) async {
    debugPrint('🔄 مزامنة ترتيب المخزون: ${event.sortBy}');

    // تنسيق الترتيب بين التبويبين
    TabCoordinationService().coordinateSortUpdate(
      sortBy: event.sortBy,
      sortAscending: event.sortAscending,
      sourceTab: event.sourceTab,
    );
  }

  /// معالجة مزامنة الأخطاء
  Future<void> _handleErrorSync(InventoryErrorSyncEvent event) async {
    debugPrint('🔄 مزامنة خطأ المخزون: ${event.error}');

    // تنسيق معالجة الأخطاء بين التبويبين
    TabCoordinationService().coordinateErrorHandling(
      error: event.error,
      sourceTab: event.sourceTab,
      stackTrace: event.stackTrace,
    );
  }

  /// إرسال حدث تنسيق
  void _fireCoordinationEvent(InventoryCoordinationEvent event) {
    if (!_coordinationController.isClosed) {
      _coordinationController.add(event);
      debugPrint('🔄 InventoryCoordination: ${event.runtimeType}');
    }
  }

  /// تنسيق إضافة عنصر مخزون
  void coordinateInventoryAddition({
    required InventoryItem item,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryDataSyncEvent(
      operation: 'add',
      inventoryItem: item,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق تحديث عنصر مخزون
  void coordinateInventoryUpdate({
    required InventoryItem item,
    required int oldQuantity,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryDataSyncEvent(
      operation: 'update',
      inventoryItem: item,
      oldQuantity: oldQuantity,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق حذف عنصر مخزون
  void coordinateInventoryDeletion({
    required InventoryItem item,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryDataSyncEvent(
      operation: 'delete',
      inventoryItem: item,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق البحث
  void coordinateSearch({
    required String searchQuery,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryFilterSyncEvent(
      searchQuery: searchQuery,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق الترتيب
  void coordinateSorting({
    required String sortBy,
    required bool sortAscending,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventorySortSyncEvent(
      sortBy: sortBy,
      sortAscending: sortAscending,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق الخطأ
  void coordinateError({
    required String error,
    required String sourceTab,
    String? stackTrace,
  }) {
    _fireCoordinationEvent(InventoryErrorSyncEvent(
      error: error,
      sourceTab: sourceTab,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  /// إغلاق الخدمة
  void dispose() {
    stopCoordination();
    _coordinationController.close();
  }
}

/// أحداث التنسيق بين تبويبات المخزون
abstract class InventoryCoordinationEvent {

  InventoryCoordinationEvent({
    required this.timestamp,
    required this.sourceTab,
  });
  final DateTime timestamp;
  final String sourceTab;
}

/// حدث مزامنة بيانات المخزون
class InventoryDataSyncEvent extends InventoryCoordinationEvent {

  InventoryDataSyncEvent({
    required this.operation,
    this.inventoryItem,
    this.oldQuantity,
    required super.sourceTab,
    required super.timestamp,
  });
  final String operation; // 'add', 'update', 'delete'
  final InventoryItem? inventoryItem;
  final int? oldQuantity;
}

/// حدث مزامنة فلترة المخزون
class InventoryFilterSyncEvent extends InventoryCoordinationEvent {

  InventoryFilterSyncEvent({
    required this.searchQuery,
    required super.sourceTab,
    required super.timestamp,
  });
  final String searchQuery;
}

/// حدث مزامنة ترتيب المخزون
class InventorySortSyncEvent extends InventoryCoordinationEvent {

  InventorySortSyncEvent({
    required this.sortBy,
    required this.sortAscending,
    required super.sourceTab,
    required super.timestamp,
  });
  final String sortBy;
  final bool sortAscending;
}

/// حدث مزامنة خطأ المخزون
class InventoryErrorSyncEvent extends InventoryCoordinationEvent {

  InventoryErrorSyncEvent({
    required this.error,
    this.stackTrace,
    required super.sourceTab,
    required super.timestamp,
  });
  final String error;
  final String? stackTrace;
}
