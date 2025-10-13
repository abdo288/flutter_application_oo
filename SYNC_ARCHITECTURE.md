# Sync Architecture Documentation

## نظرة عامة

تم تطوير نظام مزامنة شامل ومتقدم لتطبيق Flutter يحل مشاكل التحديثات الفورية وتبادل البيانات بين التبويبات والمكونات المختلفة.

## المكونات الرئيسية

### 1. Event Bus Architecture (`lib/services/app_event_bus.dart`)

**الغرض**: نظام مركزي لتنسيق جميع التحديثات عبر التطبيق

**الميزات**:
- بث الأحداث بين المكونات المختلفة
- دعم أنواع مختلفة من الأحداث (منتجات، مخزون، سلة، مزامنة)
- تتبع الأداء والإحصائيات
- معالجة الأخطاء المتقدمة

**أنواع الأحداث**:
```dart
enum AppEventType {
  // Product events
  productAdded, productUpdated, productDeleted, productSynced,
  
  // Inventory events
  inventoryAdded, inventoryUpdated, inventoryDeleted, inventorySynced,
  
  // Cart events
  cartUpdated, cartItemAdded, cartItemRemoved, cartItemUpdated,
  
  // Sync events
  syncStarted, syncCompleted, syncFailed, syncProgress,
  
  // UI events
  tabChanged, tabUpdated, uiRefreshed,
}
```

### 2. Unified Sync Manager (`lib/services/unified_sync_manager.dart`)

**الغرض**: مدير المزامنة الموحد الذي يحل محل جميع خدمات المزامنة المتضاربة

**الميزات**:
- مزامنة ثنائية الاتجاه مع Firestore
- معالجة العمليات المعلقة
- إدارة الاتصال والتوقيت
- منع المزامنة المتزامنة

**الاستخدام**:
```dart
final UnifiedSyncManager syncManager = UnifiedSyncManager();
await syncManager.initialize('user_id');
await syncManager.performImmediateSync();
```

### 3. Windows Sync Adapter (`lib/services/windows_sync_adapter.dart`)

**الغرض**: معالجة خاصة لـWindows باستخدام periodic sync بدلاً من Firestore snapshots

**الميزات**:
- مزامنة دورية محسنة لـWindows
- إحصائيات الأداء
- معالجة الأخطاء والاسترداد
- تنسيق مع Event Bus

**الاستخدام**:
```dart
final WindowsSyncAdapter adapter = WindowsSyncAdapter();
await adapter.startPeriodicSync();
```

### 4. Sync Recovery Service (`lib/services/sync_recovery_service.dart`)

**الغرض**: معالجة الأخطاء والاسترداد التلقائي للمزامنة

**الميزات**:
- اكتشاف العمليات المعلقة
- إعادة المحاولة الذكية
- فحص سلامة البيانات
- تقارير الاسترداد

### 5. Stream Providers المحسنة

#### StreamProductProvider
- إزالة debouncing من العمليات المحلية
- تحديثات فورية عبر Event Bus
- معالجة الأخطاء المحسنة

#### StreamInventoryProvider
- نفس التحسينات مثل StreamProductProvider
- معالجة خاصة لعمليات الحذف

#### CartProvider
- الاشتراك في أحداث المنتجات والمخزون
- تحديث تلقائي للأسعار والكميات
- إزالة المنتجات المحذوفة تلقائياً

#### PosProductProvider
- الاشتراك في أحداث المنتجات
- مزامنة مع قاعدة البيانات المحلية
- بث أحداث عند التحديث

## تدفق البيانات

### 1. إضافة منتج جديد

```
User Action → StreamProductProvider → UnifiedRepository → Event Bus → CartProvider
                                                      → PosProductProvider
                                                      → Other Tabs
```

### 2. تحديث منتج موجود

```
User Action → StreamProductProvider → UnifiedRepository → Event Bus → CartProvider (update price)
                                                      → Other Tabs (immediate update)
```

### 3. حذف منتج

```
User Action → StreamProductProvider → UnifiedRepository → Event Bus → CartProvider (remove item)
                                                      → Other Tabs (immediate removal)
```

### 4. مزامنة مع Firestore

```
Local Change → UnifiedRepository → Sync Queue → UnifiedSyncManager → Firestore
                                                      ↓
                                              Event Bus → UI Updates
```

## معالجة الأخطاء

### 1. أخطاء الاتصال
- اكتشاف تلقائي لفقدان الاتصال
- حفظ العمليات محلياً
- مزامنة عند استعادة الاتصال

### 2. أخطاء المزامنة
- إعادة المحاولة مع exponential backoff
- تسجيل الأخطاء مع السياق
- استرداد تلقائي للعمليات المعلقة

### 3. أخطاء البيانات
- التحقق من سلامة البيانات
- تنظيف البيانات التالفة
- استرداد من النسخ الاحتياطية

## الأداء والتحسينات

### 1. تحديثات فورية
- إزالة debouncing من العمليات المحلية
- استخدام `SchedulerBinding.instance.addPostFrameCallback()`
- تحديثات UI فورية (< 50ms)

### 2. مزامنة محسنة
- معالجة العمليات المعلقة فوراً
- مزامنة مجمعة للعمليات المتعددة
- تحسين استهلاك الشبكة

### 3. إدارة الذاكرة
- تنظيف الموارد تلقائياً
- إدارة دورة حياة الاشتراكات
- تحسين استهلاك الذاكرة

## الاختبارات

### 1. Integration Tests
- `integration_test/sync_test.dart`: اختبارات المزامنة الأساسية
- `integration_test/cross_tab_test.dart`: اختبارات التحديثات بين التبويبات
- `integration_test/firestore_sync_test.dart`: اختبارات المزامنة مع Firestore

### 2. Manual Testing Checklist
- [ ] إضافة منتج في تبويب واحد والتحقق من ظهوره في التبويبات الأخرى
- [ ] تحديث سعر منتج والتحقق من تحديث السلة تلقائياً
- [ ] حذف منتج والتحقق من إزالته من السلة
- [ ] اختبار المزامنة مع Firestore (online/offline)
- [ ] اختبار Windows vs Mobile/Web
- [ ] اختبار معالجة الأخطاء والاسترداد

## الاستخدام

### 1. تهيئة النظام
```dart
// في main.dart
await initializeCoreServices();

// في initializeCoreServices()
final AppEventBus eventBus = AppEventBus();
eventBus.initialize();

final UnifiedSyncManager syncManager = UnifiedSyncManager();
await syncManager.initialize('user_id');

if (Platform.isWindows) {
  final WindowsSyncAdapter adapter = WindowsSyncAdapter();
  await adapter.startPeriodicSync();
}

final SyncRecoveryService recovery = SyncRecoveryService();
await recovery.startRecoveryService();
```

### 2. استخدام Event Bus
```dart
// إرسال حدث
eventBus.emitProduct(ProductEvent.added(
  productId: 'product_123',
  productName: 'منتج جديد',
  source: 'MyComponent',
  isLocal: true,
));

// الاستماع للأحداث
eventBus.productEventStream.listen((event) {
  // معالجة الحدث
});
```

### 3. استخدام Providers
```dart
// تهيئة Providers
final productProvider = StreamProductProvider();
await productProvider.initialize();

final cartProvider = CartProvider();
cartProvider.initialize();

// العمليات
await productProvider.addProduct(product);
cartProvider.addItem(cartItem);
```

## استكشاف الأخطاء

### 1. مشاكل المزامنة
- تحقق من حالة الاتصال
- فحص العمليات المعلقة
- مراجعة سجلات الأخطاء

### 2. مشاكل التحديثات
- تحقق من Event Bus
- فحص Providers
- مراجعة UI rebuilds

### 3. مشاكل الأداء
- مراجعة إحصائيات Event Bus
- فحص استخدام الذاكرة
- تحسين الاستعلامات

## التطوير المستقبلي

### 1. تحسينات مقترحة
- WebSocket للاتصال المباشر
- ضغط البيانات للمزامنة
- مزامنة جزئية ذكية

### 2. ميزات جديدة
- مزامنة في الوقت الفعلي
- حل النزاعات التلقائي
- نسخ احتياطية تلقائية

### 3. تحسينات الأداء
- تحسين استهلاك البطارية
- تحسين استهلاك البيانات
- تحسين سرعة المزامنة

