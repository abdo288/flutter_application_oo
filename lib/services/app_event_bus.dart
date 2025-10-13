import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../models/cart_item.dart';

/// Event Bus للتواصل بين التبويبات
class AppEventBus {
  static final _controller = StreamController<AppEvent>.broadcast();
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
  final Product product;
  final String? sourceTab;

  ProductAddedEvent(this.product, {this.sourceTab});

  @override
  String toString() => 'ProductAddedEvent: ${product.name}';
}

/// حدث تحديث منتج
class ProductUpdatedEvent extends AppEvent {
  final Product product;
  final String? sourceTab;

  ProductUpdatedEvent(this.product, {this.sourceTab});

  @override
  String toString() => 'ProductUpdatedEvent: ${product.name}';
}

/// حدث حذف منتج
class ProductDeletedEvent extends AppEvent {
  final String productId;
  final String productName;
  final String? sourceTab;

  ProductDeletedEvent(this.productId, this.productName, {this.sourceTab});

  @override
  String toString() => 'ProductDeletedEvent: $productName';
}

/// حدث تحديث المخزون
class InventoryUpdatedEvent extends AppEvent {
  final String itemId;
  final String itemName;
  final int oldQuantity;
  final int newQuantity;
  final String? sourceTab;

  InventoryUpdatedEvent(
    this.itemId,
    this.itemName,
    this.oldQuantity,
    this.newQuantity, {
    this.sourceTab,
  });

  @override
  String toString() =>
      'InventoryUpdatedEvent: $itemName ($oldQuantity → $newQuantity)';
}

/// حدث إضافة عنصر مخزون جديد
class InventoryItemAddedEvent extends AppEvent {
  final InventoryItem item;
  final String? sourceTab;

  InventoryItemAddedEvent(this.item, {this.sourceTab});

  @override
  String toString() => 'InventoryItemAddedEvent: ${item.name}';
}

/// حدث إتمام بيع
class SaleCompletedEvent extends AppEvent {
  final Sale sale;
  final List<CartItem> items;
  final String? sourceTab;

  SaleCompletedEvent(this.sale, this.items, {this.sourceTab});

  @override
  String toString() => 'SaleCompletedEvent: ${sale.totalAmount}';
}

/// حدث بدء المزامنة
class SyncStartedEvent extends AppEvent {
  final String syncType;
  final int totalItems;

  SyncStartedEvent(this.syncType, this.totalItems);

  @override
  String toString() => 'SyncStartedEvent: $syncType ($totalItems items)';
}

/// حدث انتهاء المزامنة
class SyncCompletedEvent extends AppEvent {
  final String syncType;
  final int syncedItems;
  final bool success;
  final String? error;

  SyncCompletedEvent(
    this.syncType,
    this.syncedItems, {
    this.success = true,
    this.error,
  });

  @override
  String toString() => 'SyncCompletedEvent: $syncType ($syncedItems items)';
}

/// حدث تنبيه مخزون منخفض
class LowStockAlertEvent extends AppEvent {
  final String itemId;
  final String itemName;
  final int currentQuantity;
  final int minimumQuantity;

  LowStockAlertEvent(
    this.itemId,
    this.itemName,
    this.currentQuantity,
    this.minimumQuantity,
  );

  @override
  String toString() =>
      'LowStockAlertEvent: $itemName ($currentQuantity/$minimumQuantity)';
}

/// حدث تغيير التبويب
class TabChangedEvent extends AppEvent {
  final int fromTab;
  final int toTab;
  final Map<String, dynamic>? data;

  TabChangedEvent(this.fromTab, this.toTab, {this.data});

  @override
  String toString() => 'TabChangedEvent: $fromTab → $toTab';
}

/// حدث تحديث الإحصائيات
class StatsUpdatedEvent extends AppEvent {
  final Map<String, dynamic> stats;
  final String? sourceTab;

  StatsUpdatedEvent(this.stats, {this.sourceTab});

  @override
  String toString() => 'StatsUpdatedEvent: ${stats.keys.join(', ')}';
}

/// حدث خطأ عام
class AppErrorEvent extends AppEvent {
  final String error;
  final String? sourceTab;
  final String? stackTrace;

  AppErrorEvent(this.error, {this.sourceTab, this.stackTrace});

  @override
  String toString() => 'AppErrorEvent: $error';
}

/// حدث إشعار المستخدم
class UserNotificationEvent extends AppEvent {
  final String title;
  final String message;
  final NotificationType type;
  final String? action;

  UserNotificationEvent(
    this.title,
    this.message,
    this.type, {
    this.action,
  });

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
  final String dataType;
  final int itemCount;
  final String? sourceTab;

  LocalDataUpdatedEvent(this.dataType, this.itemCount, {this.sourceTab});

  @override
  String toString() => 'LocalDataUpdatedEvent: $dataType ($itemCount items)';
}

/// حدث اتصال/انقطاع الشبكة
class ConnectivityChangedEvent extends AppEvent {
  final bool isOnline;
  final String? connectionType;

  ConnectivityChangedEvent(this.isOnline, {this.connectionType});

  @override
  String toString() =>
      'ConnectivityChangedEvent: ${isOnline ? 'Online' : 'Offline'}';
}

/// حدث تحديث الفلاتر
class FilterChangedEvent extends AppEvent {
  final String tabName;
  final Map<String, dynamic> filters;
  final String? sourceTab;

  FilterChangedEvent(this.tabName, this.filters, {this.sourceTab});

  @override
  String toString() => 'FilterChangedEvent: $tabName';
}

/// حدث البحث
class SearchPerformedEvent extends AppEvent {
  final String tabName;
  final String query;
  final int resultCount;
  final String? sourceTab;

  SearchPerformedEvent(
    this.tabName,
    this.query,
    this.resultCount, {
    this.sourceTab,
  });

  @override
  String toString() => 'SearchPerformedEvent: $tabName ($resultCount results)';
}

/// حدث إعادة تعيين البيانات
class DataResetEvent extends AppEvent {
  final String dataType;
  final String? sourceTab;

  DataResetEvent(this.dataType, {this.sourceTab});

  @override
  String toString() => 'DataResetEvent: $dataType';
}

/// حدث تحديث الإعدادات
class SettingsUpdatedEvent extends AppEvent {
  final String settingKey;
  final dynamic oldValue;
  final dynamic newValue;
  final String? sourceTab;

  SettingsUpdatedEvent(
    this.settingKey,
    this.oldValue,
    this.newValue, {
    this.sourceTab,
  });

  @override
  String toString() => 'SettingsUpdatedEvent: $settingKey';
}

/// حدث النسخ الاحتياطي
class BackupEvent extends AppEvent {
  final String backupType;
  final bool success;
  final String? filePath;
  final String? error;

  BackupEvent(
    this.backupType,
    this.success, {
    this.filePath,
    this.error,
  });

  @override
  String toString() =>
      'BackupEvent: $backupType (${success ? 'Success' : 'Failed'})';
}

/// حدث استعادة البيانات
class RestoreEvent extends AppEvent {
  final String restoreType;
  final bool success;
  final String? filePath;
  final String? error;

  RestoreEvent(
    this.restoreType,
    this.success, {
    this.filePath,
    this.error,
  });

  @override
  String toString() =>
      'RestoreEvent: $restoreType (${success ? 'Success' : 'Failed'})';
}
