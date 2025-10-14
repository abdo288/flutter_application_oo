import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../models/cart_item.dart';

/// Event Bus للتواصل بين التبويبات
class AppEventBus {
  static final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();
  static Stream<AppEvent> get stream => _controller.stream;

  /// إطلاق حدث جديد
  static void fire(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
      debugPrint('🔥 Event fired: ${event.runtimeType}');
    }
  }

  /// إغلاق Event Bus
  static void dispose() {
    _controller.close();
  }
}

/// الأحداث الأساسية
abstract class AppEvent {
  final DateTime timestamp = DateTime.now();
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}

/// حدث إضافة منتج جديد
class ProductAddedEvent extends AppEvent {

  ProductAddedEvent(this.product, {this.sourceTab});
  final Product product;
  final String? sourceTab;

  @override
  String toString() => 'ProductAddedEvent: ${product.name}';
}

/// حدث تحديث منتج
class ProductUpdatedEvent extends AppEvent {

  ProductUpdatedEvent(this.product, {this.sourceTab});
  final Product product;
  final String? sourceTab;

  @override
  String toString() => 'ProductUpdatedEvent: ${product.name}';
}

/// حدث حذف منتج
class ProductDeletedEvent extends AppEvent {

  ProductDeletedEvent(this.productId, this.productName, {this.sourceTab});
  final String productId;
  final String productName;
  final String? sourceTab;

  @override
  String toString() => 'ProductDeletedEvent: $productName';
}

/// حدث تحديث المخزون
class InventoryUpdatedEvent extends AppEvent {

  InventoryUpdatedEvent(
    this.itemId,
    this.itemName,
    this.oldQuantity,
    this.newQuantity, {
    this.sourceTab,
  });
  final String itemId;
  final String itemName;
  final int oldQuantity;
  final int newQuantity;
  final String? sourceTab;

  @override
  String toString() =>
      'InventoryUpdatedEvent: $itemName ($oldQuantity → $newQuantity)';
}

/// حدث إضافة عنصر مخزون جديد
class InventoryItemAddedEvent extends AppEvent {

  InventoryItemAddedEvent(this.item, {this.sourceTab});
  final InventoryItem item;
  final String? sourceTab;

  @override
  String toString() => 'InventoryItemAddedEvent: ${item.name}';
}

/// حدث إتمام بيع
class SaleCompletedEvent extends AppEvent {

  SaleCompletedEvent(this.sale, this.items, {this.sourceTab});
  final Sale sale;
  final List<CartItem> items;
  final String? sourceTab;

  @override
  String toString() => 'SaleCompletedEvent: ${sale.totalAmount}';
}

/// حدث بدء المزامنة
class SyncStartedEvent extends AppEvent {

  SyncStartedEvent(this.syncType, this.totalItems);
  final String syncType;
  final int totalItems;

  @override
  String toString() => 'SyncStartedEvent: $syncType ($totalItems items)';
}

/// حدث انتهاء المزامنة
class SyncCompletedEvent extends AppEvent {

  SyncCompletedEvent(
    this.syncType,
    this.syncedItems, {
    this.success = true,
    this.error,
  });
  final String syncType;
  final int syncedItems;
  final bool success;
  final String? error;

  @override
  String toString() => 'SyncCompletedEvent: $syncType ($syncedItems items)';
}

/// حدث تنبيه مخزون منخفض
class LowStockAlertEvent extends AppEvent {

  LowStockAlertEvent(
    this.itemId,
    this.itemName,
    this.currentQuantity,
    this.minimumQuantity,
  );
  final String itemId;
  final String itemName;
  final int currentQuantity;
  final int minimumQuantity;

  @override
  String toString() =>
      'LowStockAlertEvent: $itemName ($currentQuantity/$minimumQuantity)';
}

/// حدث تغيير التبويب
class TabChangedEvent extends AppEvent {

  TabChangedEvent(this.fromTab, this.toTab, {this.data});
  final int fromTab;
  final int toTab;
  final Map<String, dynamic>? data;

  @override
  String toString() => 'TabChangedEvent: $fromTab → $toTab';
}

/// حدث تحديث الإحصائيات
class StatsUpdatedEvent extends AppEvent {

  StatsUpdatedEvent(this.stats, {this.sourceTab});
  final Map<String, dynamic> stats;
  final String? sourceTab;

  @override
  String toString() => 'StatsUpdatedEvent: ${stats.keys.join(', ')}';
}

/// حدث خطأ عام
class AppErrorEvent extends AppEvent {

  AppErrorEvent(this.error, {this.sourceTab, this.stackTrace});
  final String error;
  final String? sourceTab;
  final String? stackTrace;

  @override
  String toString() => 'AppErrorEvent: $error';
}

/// حدث إشعار المستخدم
class UserNotificationEvent extends AppEvent {

  UserNotificationEvent(
    this.title,
    this.message,
    this.type, {
    this.action,
  });
  final String title;
  final String message;
  final NotificationType type;
  final String? action;

  @override
  String toString() => 'UserNotificationEvent: $title';
}

/// أنواع الإشعارات
enum NotificationType {
  success,
  warning,
  error,
  info,
}

/// حدث تحديث البيانات المحلية
class LocalDataUpdatedEvent extends AppEvent {

  LocalDataUpdatedEvent(this.dataType, this.itemCount, {this.sourceTab});
  final String dataType;
  final int itemCount;
  final String? sourceTab;

  @override
  String toString() => 'LocalDataUpdatedEvent: $dataType ($itemCount items)';
}

/// حدث اتصال/انقطاع الشبكة
class ConnectivityChangedEvent extends AppEvent {

  ConnectivityChangedEvent(this.isOnline, {this.connectionType});
  final bool isOnline;
  final String? connectionType;

  @override
  String toString() =>
      'ConnectivityChangedEvent: ${isOnline ? 'Online' : 'Offline'}';
}

/// حدث تحديث الفلاتر
class FilterChangedEvent extends AppEvent {

  FilterChangedEvent(this.tabName, this.filters, {this.sourceTab});
  final String tabName;
  final Map<String, dynamic> filters;
  final String? sourceTab;

  @override
  String toString() => 'FilterChangedEvent: $tabName';
}

/// حدث البحث
class SearchPerformedEvent extends AppEvent {

  SearchPerformedEvent(
    this.tabName,
    this.query,
    this.resultCount, {
    this.sourceTab,
  });
  final String tabName;
  final String query;
  final int resultCount;
  final String? sourceTab;

  @override
  String toString() => 'SearchPerformedEvent: $tabName ($resultCount results)';
}

/// حدث إعادة تعيين البيانات
class DataResetEvent extends AppEvent {

  DataResetEvent(this.dataType, {this.sourceTab});
  final String dataType;
  final String? sourceTab;

  @override
  String toString() => 'DataResetEvent: $dataType';
}

/// حدث تحديث الإعدادات
class SettingsUpdatedEvent extends AppEvent {

  SettingsUpdatedEvent(
    this.settingKey,
    this.oldValue,
    this.newValue, {
    this.sourceTab,
  });
  final String settingKey;
  final dynamic oldValue;
  final dynamic newValue;
  final String? sourceTab;

  @override
  String toString() => 'SettingsUpdatedEvent: $settingKey';
}

/// حدث النسخ الاحتياطي
class BackupEvent extends AppEvent {

  BackupEvent(
    this.backupType,
    this.success, {
    this.filePath,
    this.error,
  });
  final String backupType;
  final bool success;
  final String? filePath;
  final String? error;

  @override
  String toString() =>
      'BackupEvent: $backupType (${success ? 'Success' : 'Failed'})';
}

/// حدث استعادة البيانات
class RestoreEvent extends AppEvent {

  RestoreEvent(
    this.restoreType,
    this.success, {
    this.filePath,
    this.error,
  });
  final String restoreType;
  final bool success;
  final String? filePath;
  final String? error;

  @override
  String toString() =>
      'RestoreEvent: $restoreType (${success ? 'Success' : 'Failed'})';
}
