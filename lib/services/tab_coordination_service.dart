import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// خدمة تنسيق البيانات بين التبويبات
/// ✅ ضمان التناسق التام بين QuickSellTab و InventoryDisplayTab
class TabCoordinationService {
  factory TabCoordinationService() => _instance;
  TabCoordinationService._internal();
  static final TabCoordinationService _instance =
      TabCoordinationService._internal();

  final StreamController<TabCoordinationEvent> _coordinationController =
      StreamController<TabCoordinationEvent>.broadcast();

  Stream<TabCoordinationEvent> get coordinationStream =>
      _coordinationController.stream;

  /// إرسال حدث تنسيق
  void _fireCoordinationEvent(TabCoordinationEvent event) {
    if (!_coordinationController.isClosed) {
      _coordinationController.add(event);
      debugPrint('🔄 TabCoordination: ${event.runtimeType}');
    }
  }

  /// تنسيق إضافة منتج بين التبويبين
  void coordinateProductAddition({
    required Product product,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(ProductAdditionCoordinatedEvent(
      product: product,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق تحديث المخزون بين التبويبين
  void coordinateInventoryUpdate({
    required String itemId,
    required String itemName,
    required int oldQuantity,
    required int newQuantity,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryUpdateCoordinatedEvent(
      itemId: itemId,
      itemName: itemName,
      oldQuantity: oldQuantity,
      newQuantity: newQuantity,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق حذف عنصر مخزون بين التبويبين
  void coordinateInventoryDeletion({
    required String itemId,
    required String itemName,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(InventoryDeletionCoordinatedEvent(
      itemId: itemId,
      itemName: itemName,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق تحديث البحث والفلترة بين التبويبين
  void coordinateSearchUpdate({
    required String searchQuery,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(SearchUpdateCoordinatedEvent(
      searchQuery: searchQuery,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق تحديث الترتيب بين التبويبين
  void coordinateSortUpdate({
    required String sortBy,
    required bool sortAscending,
    required String sourceTab,
  }) {
    _fireCoordinationEvent(SortUpdateCoordinatedEvent(
      sortBy: sortBy,
      sortAscending: sortAscending,
      sourceTab: sourceTab,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق إعادة تحميل البيانات بين التبويبين
  void coordinateDataRefresh({
    required String sourceTab,
    String? reason,
  }) {
    _fireCoordinationEvent(DataRefreshCoordinatedEvent(
      sourceTab: sourceTab,
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  /// تنسيق معالجة الأخطاء بين التبويبين
  void coordinateErrorHandling({
    required String error,
    required String sourceTab,
    String? stackTrace,
  }) {
    _fireCoordinationEvent(ErrorHandlingCoordinatedEvent(
      error: error,
      sourceTab: sourceTab,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  /// إغلاق خدمة التنسيق
  void dispose() {
    _coordinationController.close();
  }
}

/// أحداث التنسيق بين التبويبات
abstract class TabCoordinationEvent {

  TabCoordinationEvent({
    required this.timestamp,
    required this.sourceTab,
  });
  final DateTime timestamp;
  final String sourceTab;
}

/// حدث تنسيق إضافة منتج
class ProductAdditionCoordinatedEvent extends TabCoordinationEvent {

  ProductAdditionCoordinatedEvent({
    required this.product,
    required super.sourceTab,
    required super.timestamp,
  });
  final Product product;
}

/// حدث تنسيق تحديث المخزون
class InventoryUpdateCoordinatedEvent extends TabCoordinationEvent {

  InventoryUpdateCoordinatedEvent({
    required this.itemId,
    required this.itemName,
    required this.oldQuantity,
    required this.newQuantity,
    required super.sourceTab,
    required super.timestamp,
  });
  final String itemId;
  final String itemName;
  final int oldQuantity;
  final int newQuantity;
}

/// حدث تنسيق حذف عنصر مخزون
class InventoryDeletionCoordinatedEvent extends TabCoordinationEvent {

  InventoryDeletionCoordinatedEvent({
    required this.itemId,
    required this.itemName,
    required super.sourceTab,
    required super.timestamp,
  });
  final String itemId;
  final String itemName;
}

/// حدث تنسيق تحديث البحث
class SearchUpdateCoordinatedEvent extends TabCoordinationEvent {

  SearchUpdateCoordinatedEvent({
    required this.searchQuery,
    required super.sourceTab,
    required super.timestamp,
  });
  final String searchQuery;
}

/// حدث تنسيق تحديث الترتيب
class SortUpdateCoordinatedEvent extends TabCoordinationEvent {

  SortUpdateCoordinatedEvent({
    required this.sortBy,
    required this.sortAscending,
    required super.sourceTab,
    required super.timestamp,
  });
  final String sortBy;
  final bool sortAscending;
}

/// حدث تنسيق إعادة تحميل البيانات
class DataRefreshCoordinatedEvent extends TabCoordinationEvent {

  DataRefreshCoordinatedEvent({
    required super.sourceTab,
    this.reason,
    required super.timestamp,
  });
  final String? reason;
}

/// حدث تنسيق معالجة الأخطاء
class ErrorHandlingCoordinatedEvent extends TabCoordinationEvent {

  ErrorHandlingCoordinatedEvent({
    required this.error,
    required super.sourceTab,
    this.stackTrace,
    required super.timestamp,
  });
  final String error;
  final String? stackTrace;
}
