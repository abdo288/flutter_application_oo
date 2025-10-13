# Event Bus Guide

## نظرة عامة

Event Bus هو نظام مركزي لتنسيق التحديثات عبر التطبيق، يوفر طريقة موحدة لإرسال واستقبال الأحداث بين المكونات المختلفة.

## الميزات الرئيسية

- **بث الأحداث**: إرسال الأحداث إلى جميع المكونات المشتركة
- **تصفية الأحداث**: الاستماع لأنواع محددة من الأحداث
- **تتبع الأداء**: إحصائيات مفصلة عن الأحداث
- **معالجة الأخطاء**: معالجة متقدمة لأخطاء الأحداث
- **إدارة الذاكرة**: تنظيف تلقائي للموارد

## أنواع الأحداث

### 1. أحداث المنتجات (Product Events)

```dart
// إضافة منتج
eventBus.emitProduct(ProductEvent.added(
  productId: 'product_123',
  productName: 'منتج جديد',
  source: 'ProductProvider',
  data: {
    'wholesalePrice': 100.0,
    'retailPrice': 150.0,
  },
  isLocal: true,
));

// تحديث منتج
eventBus.emitProduct(ProductEvent.updated(
  productId: 'product_123',
  productName: 'منتج محدث',
  source: 'ProductProvider',
  data: {
    'retailPrice': 200.0,
  },
  isLocal: true,
));

// حذف منتج
eventBus.emitProduct(ProductEvent.deleted(
  productId: 'product_123',
  productName: 'منتج محذوف',
  source: 'ProductProvider',
  isLocal: true,
));
```

### 2. أحداث المخزون (Inventory Events)

```dart
// إضافة عنصر مخزون
eventBus.emitInventory(InventoryEvent.added(
  itemId: 'inventory_123',
  itemName: 'عنصر مخزون جديد',
  source: 'InventoryProvider',
  data: {
    'quantity': 10,
    'wholesalePrice': 50.0,
    'retailPrice': 75.0,
  },
  isLocal: true,
));

// تحديث عنصر مخزون
eventBus.emitInventory(InventoryEvent.updated(
  itemId: 'inventory_123',
  itemName: 'عنصر مخزون محدث',
  source: 'InventoryProvider',
  data: {
    'quantity': 5,
  },
  isLocal: true,
));

// حذف عنصر مخزون
eventBus.emitInventory(InventoryEvent.deleted(
  itemId: 'inventory_123',
  itemName: 'عنصر مخزون محذوف',
  source: 'InventoryProvider',
  isLocal: true,
));
```

### 3. أحداث السلة (Cart Events)

```dart
// تحديث السلة
eventBus.emitCart(CartEvent.updated(
  itemCount: 3,
  totalAmount: 450.0,
  source: 'CartProvider',
  data: {
    'action': 'updated',
    'itemName': 'منتج في السلة',
    'quantity': 2,
    'price': 150.0,
  },
  isLocal: true,
));
```

### 4. أحداث المزامنة (Sync Events)

```dart
// بدء المزامنة
eventBus.emitSync(SyncEvent.started(
  operation: 'full_sync',
  source: 'SyncManager',
  data: {
    'userId': 'user_123',
    'syncType': 'full',
  },
));

// اكتمال المزامنة
eventBus.emitSync(SyncEvent.completed(
  operation: 'full_sync',
  source: 'SyncManager',
  data: {
    'duration': 1500,
    'itemsSynced': 25,
  },
));

// فشل المزامنة
eventBus.emitSync(SyncEvent.failed(
  operation: 'full_sync',
  errorMessage: 'Connection timeout',
  source: 'SyncManager',
  data: {
    'retryCount': 3,
  },
));
```

## الاستماع للأحداث

### 1. الاستماع لجميع الأحداث

```dart
StreamSubscription<AppEvent> subscription = eventBus.eventStream.listen(
  (AppEvent event) {
    print('Received event: ${event.type.name} from ${event.source}');
    // معالجة الحدث
  },
  onError: (error) {
    print('Event error: $error');
  },
);

// تنظيف الاشتراك
subscription.cancel();
```

### 2. الاستماع لأحداث محددة

```dart
// أحداث المنتجات فقط
StreamSubscription<ProductEvent> productSubscription = 
    eventBus.productEventStream.listen(
  (ProductEvent event) {
    switch (event.type) {
      case AppEventType.productAdded:
        // معالجة إضافة منتج
        break;
      case AppEventType.productUpdated:
        // معالجة تحديث منتج
        break;
      case AppEventType.productDeleted:
        // معالجة حذف منتج
        break;
    }
  },
);

// أحداث المخزون فقط
StreamSubscription<InventoryEvent> inventorySubscription = 
    eventBus.inventoryEventStream.listen(
  (InventoryEvent event) {
    // معالجة أحداث المخزون
  },
);
```

### 3. الاستماع لأحداث محددة جداً

```dart
// أحداث إضافة المنتجات فقط
StreamSubscription<ProductEvent> addedProductsSubscription = 
    eventBus.productAddedStream.listen(
  (ProductEvent event) {
    print('New product added: ${event.productName}');
  },
);

// أحداث تحديث المنتجات فقط
StreamSubscription<ProductEvent> updatedProductsSubscription = 
    eventBus.productUpdatedStream.listen(
  (ProductEvent event) {
    print('Product updated: ${event.productName}');
  },
);

// أحداث حذف المنتجات فقط
StreamSubscription<ProductEvent> deletedProductsSubscription = 
    eventBus.productDeletedStream.listen(
  (ProductEvent event) {
    print('Product deleted: ${event.productName}');
  },
);
```

## استخدام في Providers

### 1. StreamProductProvider

```dart
class StreamProductProvider with ChangeNotifier {
  final AppEventBus _eventBus = AppEventBus();
  StreamSubscription<AppEvent>? _eventSubscription;

  Future<void> initialize() async {
    // الاشتراك في أحداث المنتجات
    _eventSubscription = _eventBus.productEventStream.listen(
      _onProductEvent,
      onError: (error) {
        debugPrint('❌ خطأ في Event Bus للمنتجات: $error');
      },
    );
  }

  void _onProductEvent(ProductEvent event) {
    // معالجة أحداث المنتجات
    if (event.isLocal) {
      // تحديث فوري للأحداث المحلية
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      // debounce للأحداث الخارجية
      _updateDebounceTimer?.cancel();
      _updateDebounceTimer = Timer(const Duration(milliseconds: 50), () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      });
    }
  }

  Future<String?> addProduct(Product product) async {
    // إضافة المنتج محلياً
    // ...

    // إرسال حدث عبر Event Bus
    _eventBus.emitProduct(ProductEvent.added(
      productId: productId,
      productName: product.name,
      source: 'StreamProductProvider',
      data: {
        'wholesalePrice': product.wholesalePrice,
        'retailPrice': product.retailPrice,
      },
      isLocal: true,
    ));

    // تحديث UI فوري
    _updateDebounceTimer?.cancel();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
```

### 2. CartProvider

```dart
class CartProvider with ChangeNotifier {
  final AppEventBus _eventBus = AppEventBus();
  StreamSubscription<AppEvent>? _eventSubscription;

  void initialize() {
    // الاشتراك في أحداث المنتجات والمخزون
    _eventSubscription = _eventBus.eventStream.listen(
      _onAppEvent,
      onError: (error) {
        debugPrint('❌ خطأ في Event Bus للسلة: $error');
      },
    );
  }

  void _onAppEvent(AppEvent event) {
    if (event is ProductEvent) {
      _onProductEvent(event);
    } else if (event is InventoryEvent) {
      _onInventoryEvent(event);
    }
  }

  void _onProductEvent(ProductEvent event) {
    switch (event.type) {
      case AppEventType.productUpdated:
        _updateProductInCart(event.productId, event.data);
        break;
      case AppEventType.productDeleted:
        _removeProductFromCart(event.productId);
        break;
    }
  }

  void _updateProductInCart(String? productId, Map<String, dynamic>? data) {
    if (productId == null || data == null) return;

    bool updated = false;
    for (int i = 0; i < _cart.length; i++) {
      if (_cart[i].productId == productId) {
        if (data.containsKey('retailPrice')) {
          final double newPrice = (data['retailPrice'] as num).toDouble();
          _cart[i] = _cart[i].copyWith(price: newPrice);
          updated = true;
        }
      }
    }

    if (updated) {
      notifyListeners();
    }
  }
}
```

## إحصائيات الأداء

### 1. الحصول على الإحصائيات

```dart
// إحصائيات Event Bus
Map<String, dynamic> metrics = eventBus.getPerformanceMetrics();
print('Total events: ${metrics['totalEvents']}');
print('Local events: ${metrics['localEvents']}');
print('Remote events: ${metrics['remoteEvents']}');
print('Events per second: ${metrics['eventsPerSecond']}');

// إحصائيات Windows Sync Adapter
Map<String, dynamic> windowsMetrics = windowsAdapter.getPerformanceReport();
print('Total syncs: ${windowsMetrics['totalSyncs']}');
print('Success rate: ${windowsMetrics['successRate']}');

// إحصائيات Sync Recovery
Map<String, dynamic> recoveryMetrics = recoveryService.getRecoveryReport();
print('Recovery attempts: ${recoveryMetrics['totalAttempts']}');
print('Success rate: ${recoveryMetrics['successRate']}');
```

### 2. مراقبة الأحداث

```dart
// الحصول على تاريخ الأحداث
List<AppEvent> recentEvents = eventBus.getEventHistory(limit: 10);

// الحصول على أحداث حسب النوع
List<AppEvent> productEvents = eventBus.getEventsByType(AppEventType.productAdded);

// الحصول على أحداث حسب المصدر
List<AppEvent> providerEvents = eventBus.getEventsBySource('StreamProductProvider');
```

## أفضل الممارسات

### 1. إدارة الاشتراكات
- دائماً قم بإلغاء الاشتراكات في `dispose()`
- استخدم `StreamSubscription` لتتبع الاشتراكات
- تجنب الاشتراكات المتعددة لنفس الحدث

### 2. معالجة الأخطاء
- استخدم `onError` في جميع الاشتراكات
- سجل الأخطاء مع السياق
- تعامل مع الأخطاء بشكل مناسب

### 3. تحسين الأداء
- استخدم `isLocal` للتمييز بين الأحداث المحلية والخارجية
- تجنب إرسال أحداث غير ضرورية
- استخدم debouncing للأحداث الخارجية

### 4. تنظيف الموارد
- قم بإلغاء جميع الاشتراكات
- امسح تاريخ الأحداث عند الحاجة
- راقب استخدام الذاكرة

## استكشاف الأخطاء

### 1. مشاكل شائعة
- **لا تصل الأحداث**: تحقق من الاشتراكات
- **أحداث مكررة**: تحقق من إلغاء الاشتراكات السابقة
- **أداء بطيء**: راجع عدد الأحداث وإحصائيات الأداء

### 2. أدوات التشخيص
```dart
// فحص حالة Event Bus
print('Event Bus initialized: ${eventBus.isInitialized}');
print('Total events: ${eventBus.getPerformanceMetrics()['totalEvents']}');

// فحص الاشتراكات النشطة
// (يحتاج إلى إضافة في Event Bus)

// فحص تاريخ الأحداث
List<AppEvent> events = eventBus.getEventHistory(limit: 5);
for (AppEvent event in events) {
  print('${event.timestamp}: ${event.type.name} from ${event.source}');
}
```

### 3. تنظيف المشاكل
```dart
// مسح تاريخ الأحداث
eventBus.clearHistory();

// إعادة تعيين الإحصائيات
// (يحتاج إلى إضافة في Event Bus)

// إعادة تهيئة Event Bus
await eventBus.dispose();
eventBus.initialize();
```

