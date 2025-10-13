# Windows Specific Implementation

## نظرة عامة

تم تطوير معالجة خاصة لـWindows لتحسين الأداء والموثوقية، حيث أن Windows له قيود مختلفة عن المنصات الأخرى في التعامل مع Firestore snapshots.

## المشاكل في Windows

### 1. مشاكل Firestore Snapshots
- عدم استقرار snapshots على Windows
- تأخير في استقبال التحديثات
- استهلاك عالي للموارد
- مشاكل في الاتصال المباشر

### 2. مشاكل الأداء
- استهلاك عالي للذاكرة
- بطء في معالجة البيانات
- مشاكل في الشبكة

## الحلول المطبقة

### 1. Windows Sync Adapter

```dart
class WindowsSyncAdapter {
  // مزامنة دورية بدلاً من snapshots
  Timer? _periodicSyncTimer;
  int _syncIntervalSeconds = 30;
  
  // إحصائيات الأداء
  int _totalSyncs = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  
  // بدء المزامنة الدورية
  Future<void> startPeriodicSync() async {
    if (!Platform.isWindows) return;
    
    _periodicSyncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => _performSync(),
    );
  }
}
```

### 2. تحسينات قاعدة البيانات

```dart
// في drift_database.dart
if (Platform.isWindows) {
  return NativeDatabase.createInBackground(
    file,
    setup: (Database database) {
      // إعدادات محسنة لـWindows
      database.execute('PRAGMA journal_mode = WAL;');
      database.execute('PRAGMA synchronous = NORMAL;');
      database.execute('PRAGMA cache_size = 2000;'); // زيادة الكاش
      database.execute('PRAGMA temp_store = MEMORY;');
      database.execute('PRAGMA mmap_size = 268435456;'); // 256MB
      database.execute('PRAGMA optimize;');
      database.execute('PRAGMA auto_vacuum = INCREMENTAL;');
      database.execute('PRAGMA locking_mode = NORMAL;');
      database.execute('PRAGMA foreign_keys = ON;');
      database.execute('PRAGMA threads = 4;'); // استخدام 4 threads
      database.execute('PRAGMA wal_autocheckpoint = 1000;');
      database.execute('PRAGMA checkpoint_fullfsync = OFF;');
      database.execute('PRAGMA secure_delete = OFF;');
      database.execute('PRAGMA count_changes = OFF;');
      database.execute('PRAGMA recursive_triggers = ON;');
      database.execute('PRAGMA legacy_file_format = OFF;');
      database.execute('PRAGMA read_uncommitted = OFF;');
      database.execute('PRAGMA short_column_names = ON;');
      database.execute('PRAGMA full_column_names = OFF;');
      database.execute('PRAGMA empty_result_callbacks = OFF;');
      database.execute('PRAGMA auto_vacuum = INCREMENTAL;');
      database.execute('PRAGMA incremental_vacuum(10);');
      
      // تحسينات إضافية لـWindows
      database.execute('PRAGMA page_size = 4096;');
      database.execute('PRAGMA max_page_count = 1073741824;');
      database.execute('PRAGMA encoding = "UTF-8";');
      database.execute('PRAGMA case_sensitive_like = OFF;');
      database.execute('PRAGMA defer_foreign_keys = ON;');
      database.execute('PRAGMA query_only = OFF;');
      database.execute('PRAGMA quick_check;');
    },
  );
}
```

### 3. فهارس محسنة لـWindows

```dart
// في migration strategy
if (from < 4) {
  // تحسينات خاصة بـWindows
  try {
    // إنشاء فهارس محسنة للأداء
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_name_windows ON products_table(name)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_user_id_windows ON products_table(user_id)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_synced_windows ON products_table(is_synced)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_name_windows ON inventory_table(name)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_user_id_windows ON inventory_table(user_id)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_synced_windows ON inventory_table(is_synced)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_date_windows ON sales_table(sale_date)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_user_id_windows ON sales_table(user_id)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_synced_windows ON sales_table(is_synced)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_ops_timestamp_windows ON sync_operations_table(timestamp)');
    await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_ops_processed_windows ON sync_operations_table(is_processed)');
  } catch (e) {
    debugPrint('خطأ في إنشاء الفهارس: $e');
  }
}
```

## الميزات الخاصة بـWindows

### 1. مزامنة دورية ذكية

```dart
Future<void> _performSync() async {
  if (!_isRunning) return;

  final DateTime syncStartTime = DateTime.now();
  _totalSyncs++;

  try {
    // التحقق من الاتصال
    if (!await ConnectivityService.isConnected) {
      debugPrint('⚠️ لا يوجد اتصال - تخطي المزامنة');
      return;
    }

    // إرسال حدث بدء المزامنة
    _eventBus.emitSync(SyncEvent.started(
      operation: 'windows_periodic_sync',
      source: 'WindowsSyncAdapter',
      data: {
        'syncNumber': _totalSyncs,
        'interval': _syncIntervalSeconds,
      },
    ));

    // تنفيذ المزامنة
    await _repository.syncFromFirestore();

    // تحديث الإحصائيات
    final Duration syncDuration = DateTime.now().difference(syncStartTime);
    _totalSyncTime += syncDuration;
    _successfulSyncs++;
    _currentRetries = 0;
    _lastSyncTime = DateTime.now();

    debugPrint('✅ تمت مزامنة Windows بنجاح في ${syncDuration.inMilliseconds}ms');

    // إرسال حدث اكتمال المزامنة
    _eventBus.emitSync(SyncEvent.completed(
      operation: 'windows_periodic_sync',
      source: 'WindowsSyncAdapter',
      data: {
        'syncNumber': _totalSyncs,
        'duration': syncDuration.inMilliseconds,
        'successRate': successRate,
      },
    ));

  } catch (e) {
    _failedSyncs++;
    _currentRetries++;

    debugPrint('❌ فشل في مزامنة Windows: $e');

    // إرسال حدث فشل المزامنة
    _eventBus.emitSync(SyncEvent.failed(
      operation: 'windows_periodic_sync',
      errorMessage: e.toString(),
      source: 'WindowsSyncAdapter',
      data: {
        'syncNumber': _totalSyncs,
        'retries': _currentRetries,
        'maxRetries': _maxRetries,
      },
    ));

    // إذا تجاوزنا الحد الأقصى من المحاولات، توقف مؤقتاً
    if (_currentRetries >= _maxRetries) {
      debugPrint('⚠️ تم الوصول للحد الأقصى من المحاولات - توقف مؤقت');
      await _handleMaxRetriesReached();
    }
  }
}
```

### 2. معالجة الأخطاء المتقدمة

```dart
Future<void> _handleMaxRetriesReached() async {
  debugPrint('⏸️ توقف مؤقت بسبب فشل متكرر - انتظار 5 دقائق');
  
  // توقف مؤقت لمدة 5 دقائق
  await Future.delayed(const Duration(minutes: 5));
  
  // إعادة تعيين المحاولات
  _currentRetries = 0;
  debugPrint('🔄 إعادة تعيين المحاولات - استئناف المزامنة');
}
```

### 3. إحصائيات الأداء

```dart
Map<String, dynamic> getPerformanceReport() {
  final Duration uptime = _startTime != null 
      ? DateTime.now().difference(_startTime!)
      : Duration.zero;
  
  return {
    'isRunning': _isRunning,
    'isWindows': Platform.isWindows,
    'syncInterval': _syncIntervalSeconds,
    'totalSyncs': _totalSyncs,
    'successfulSyncs': _successfulSyncs,
    'failedSyncs': _failedSyncs,
    'successRate': successRate,
    'averageSyncTime': averageSyncTime.inMilliseconds,
    'lastSyncTime': _lastSyncTime?.toIso8601String(),
    'uptime': uptime.inSeconds,
    'currentRetries': _currentRetries,
    'maxRetries': _maxRetries,
  };
}
```

## التكوين والاستخدام

### 1. تهيئة Windows Sync Adapter

```dart
// في main_stream.dart
if (Platform.isWindows) {
  try {
    final WindowsSyncAdapter windowsAdapter = WindowsSyncAdapter();
    await windowsAdapter.startPeriodicSync();
    debugPrint('✅ تم تهيئة Windows Sync Adapter');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة Windows Sync Adapter: $e');
  }
}
```

### 2. تحديث فترة المزامنة

```dart
// تحديث فترة المزامنة
windowsAdapter.updateSyncInterval(60); // 60 ثانية

// الحصول على الإحصائيات
Map<String, dynamic> report = windowsAdapter.getPerformanceReport();
print('Success rate: ${report['successRate']}');
print('Average sync time: ${report['averageSyncTime']}ms');
```

### 3. مزامنة فورية

```dart
// تنفيذ مزامنة فورية
await windowsAdapter.performImmediateSync();

// إجبار مزامنة كاملة
await windowsAdapter.forceFullSync();
```

## تحسينات الأداء

### 1. إعدادات قاعدة البيانات
- **WAL Mode**: تحسين الأداء المتزامن
- **Cache Size**: زيادة حجم الكاش إلى 2000
- **Memory Mapping**: 256MB للذاكرة المباشرة
- **Threads**: استخدام 4 threads للمعالجة
- **Auto Vacuum**: تنظيف تلقائي للبيانات

### 2. فهارس محسنة
- فهارس على الأعمدة المستخدمة بكثرة
- فهارس مركبة للاستعلامات المعقدة
- فهارس خاصة بـWindows

### 3. مزامنة ذكية
- مزامنة دورية بدلاً من snapshots
- معالجة الأخطاء والاسترداد
- إحصائيات مفصلة للأداء

## استكشاف الأخطاء

### 1. مشاكل شائعة في Windows

#### مشاكل الاتصال
```dart
// فحص حالة الاتصال
if (!await ConnectivityService.isConnected) {
  debugPrint('⚠️ لا يوجد اتصال - تخطي المزامنة');
  return;
}
```

#### مشاكل الأداء
```dart
// فحص إحصائيات الأداء
Map<String, dynamic> report = windowsAdapter.getPerformanceReport();
if (report['successRate'] < 0.8) {
  debugPrint('⚠️ معدل نجاح المزامنة منخفض: ${report['successRate']}');
}
```

#### مشاكل الذاكرة
```dart
// فحص استخدام الذاكرة
Map<String, dynamic> metrics = eventBus.getPerformanceMetrics();
if (metrics['totalEvents'] > 10000) {
  debugPrint('⚠️ عدد كبير من الأحداث - تنظيف التاريخ');
  eventBus.clearHistory();
}
```

### 2. أدوات التشخيص

```dart
// فحص حالة Windows Sync Adapter
print('Windows Sync Adapter running: ${windowsAdapter.isRunning}');
print('Last sync time: ${windowsAdapter.lastSyncTime}');
print('Sync interval: ${windowsAdapter.syncIntervalSeconds}s');

// فحص إحصائيات الأداء
Map<String, dynamic> report = windowsAdapter.getPerformanceReport();
print('Total syncs: ${report['totalSyncs']}');
print('Success rate: ${report['successRate']}');
print('Average sync time: ${report['averageSyncTime']}ms');

// فحص الأخطاء الحديثة
List<String> recentErrors = windowsAdapter.recentErrors;
for (String error in recentErrors.take(5)) {
  print('Recent error: $error');
}
```

### 3. حل المشاكل

```dart
// إعادة تعيين الإحصائيات
windowsAdapter.resetStatistics();

// إعادة تشغيل المزامنة
await windowsAdapter.stopPeriodicSync();
await windowsAdapter.startPeriodicSync();

// تنظيف الموارد
await windowsAdapter.dispose();
```

## أفضل الممارسات لـWindows

### 1. إدارة الموارد
- راقب استخدام الذاكرة
- نظف الموارد بانتظام
- استخدم فترات مزامنة مناسبة

### 2. معالجة الأخطاء
- استخدم retry logic ذكي
- سجل الأخطاء مع السياق
- تعامل مع فشل الاتصال

### 3. تحسين الأداء
- استخدم فهارس مناسبة
- قلل من عدد الاستعلامات
- استخدم مزامنة مجمعة

### 4. مراقبة الأداء
- تتبع إحصائيات المزامنة
- راقب معدل النجاح
- حل المشاكل بسرعة

