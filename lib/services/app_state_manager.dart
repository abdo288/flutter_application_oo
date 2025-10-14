import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_event_bus.dart';

/// مدير الحالة المشتركة للتطبيق
class AppStateManager extends ChangeNotifier {
  // ========== متغيرات الحالة ==========

  /// حالة المزامنة
  bool _isSyncing = false;

  /// عدد العمليات المعلقة
  int _pendingOperations = 0;

  /// البيانات المشتركة
  final Map<String, dynamic> _sharedData = <String, dynamic>{};

  /// حالة الاتصال
  bool _isOnline = true;

  /// نوع الاتصال
  String? _connectionType;

  /// آخر خطأ
  String? _lastError;

  /// الإحصائيات المحلية
  final Map<String, dynamic> _localStats = <String, dynamic>{};

  /// الفلاتر النشطة
  final Map<String, dynamic> _activeFilters = <String, dynamic>{};

  /// عمليات النسخ الاحتياطي
  final List<BackupEvent> _backupHistory = <BackupEvent>[];

  /// عمليات الاستعادة
  final List<RestoreEvent> _restoreHistory = <RestoreEvent>[];

  /// Stream subscriptions
  StreamSubscription<AppEvent>? _eventSubscription;

  // ========== Getters ==========

  bool get isSyncing => _isSyncing;
  int get pendingOperations => _pendingOperations;
  bool get isOnline => _isOnline;
  String? get connectionType => _connectionType;
  String? get lastError => _lastError;
  Map<String, dynamic> get localStats => Map.unmodifiable(_localStats);
  Map<String, dynamic> get activeFilters => Map.unmodifiable(_activeFilters);
  List<BackupEvent> get backupHistory => List.unmodifiable(_backupHistory);
  List<RestoreEvent> get restoreHistory => List.unmodifiable(_restoreHistory);

  // ========== تهيئة وإغلاق ==========

  /// تهيئة AppStateManager
  void initialize() {
    debugPrint('🚀 تهيئة AppStateManager...');

    // الاستماع للأحداث
    _eventSubscription = AppEventBus.stream.listen(_handleEvent);

    // تهيئة الإحصائيات
    _initializeStats();

    debugPrint('✅ تم تهيئة AppStateManager بنجاح');
  }

  /// إغلاق AppStateManager
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // ========== إدارة المزامنة ==========

  /// بدء المزامنة
  void startSync(String syncType, int totalItems) {
    _isSyncing = true;
    _pendingOperations = totalItems;
    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(SyncStartedEvent(syncType, totalItems));

    debugPrint('🔄 بدء المزامنة: $syncType ($totalItems عنصر)');
  }

  /// تحديث تقدم المزامنة
  void updateSyncProgress(int completedItems) {
    _pendingOperations = _pendingOperations - completedItems;
    if (_pendingOperations < 0) _pendingOperations = 0;
    notifyListeners();

    debugPrint('📊 تقدم المزامنة: $completedItems عنصر مكتمل');
  }

  /// انتهاء المزامنة
  void endSync(String syncType, int syncedItems,
      {bool success = true, String? error}) {
    _isSyncing = false;
    _pendingOperations = 0;

    if (!success && error != null) {
      _lastError = error;
    }

    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(SyncCompletedEvent(syncType, syncedItems,
        success: success, error: error));

    debugPrint('✅ انتهاء المزامنة: $syncType (${success ? 'نجح' : 'فشل'})');
  }

  // ========== إدارة البيانات المشتركة ==========

  /// حفظ بيانات مشتركة
  void setSharedData(String key, dynamic value) {
    _sharedData[key] = value;
    notifyListeners();

    debugPrint('💾 حفظ بيانات مشتركة: $key = $value');
  }

  /// قراءة بيانات مشتركة
  T? getSharedData<T>(String key) {
    final value = _sharedData[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// حذف بيانات مشتركة
  void removeSharedData(String key) {
    _sharedData.remove(key);
    notifyListeners();

    debugPrint('🗑️ حذف بيانات مشتركة: $key');
  }

  /// مسح جميع البيانات المشتركة
  void clearSharedData() {
    _sharedData.clear();
    notifyListeners();

    debugPrint('🧹 مسح جميع البيانات المشتركة');
  }

  // ========== إدارة الاتصال ==========

  /// تحديث حالة الاتصال
  void updateConnectivity(bool isOnline, {String? connectionType}) {
    _isOnline = isOnline;
    _connectionType = connectionType;
    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(
        ConnectivityChangedEvent(isOnline, connectionType: connectionType));

    debugPrint('🌐 تحديث الاتصال: ${isOnline ? 'متصل' : 'غير متصل'}');
  }

  // ========== إدارة الإحصائيات ==========

  /// تحديث الإحصائيات المحلية
  void updateStats(Map<String, dynamic> stats) {
    _localStats.addAll(stats);
    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(StatsUpdatedEvent(stats));

    debugPrint('📊 تحديث الإحصائيات: ${stats.keys.join(', ')}');
  }

  /// الحصول على إحصائية محددة
  T? getStat<T>(String key) {
    final value = _localStats[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// مسح الإحصائيات
  void clearStats() {
    _localStats.clear();
    notifyListeners();

    debugPrint('🧹 مسح الإحصائيات');
  }

  // ========== إدارة الفلاتر ==========

  /// تعيين فلتر نشط
  void setActiveFilter(String tabName, Map<String, dynamic> filters) {
    _activeFilters[tabName] = filters;
    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(FilterChangedEvent(tabName, filters));

    debugPrint('🔍 تعيين فلتر نشط: $tabName');
  }

  /// الحصول على فلتر نشط
  Map<String, dynamic>? getActiveFilter(String tabName) {
    final filter = _activeFilters[tabName];
    if (filter is Map<String, dynamic>) {
      return filter;
    }
    return null;
  }

  /// مسح فلتر نشط
  void clearActiveFilter(String tabName) {
    _activeFilters.remove(tabName);
    notifyListeners();

    debugPrint('🧹 مسح فلتر نشط: $tabName');
  }

  /// مسح جميع الفلاتر
  void clearAllFilters() {
    _activeFilters.clear();
    notifyListeners();

    debugPrint('🧹 مسح جميع الفلاتر');
  }

  // ========== إدارة النسخ الاحتياطي ==========

  /// إضافة عملية نسخ احتياطي
  void addBackupEvent(BackupEvent event) {
    _backupHistory.add(event);
    if (_backupHistory.length > 50) {
      _backupHistory.removeAt(0); // إزالة أقدم عملية
    }
    notifyListeners();

    debugPrint('💾 إضافة عملية نسخ احتياطي: ${event.backupType}');
  }

  /// إضافة عملية استعادة
  void addRestoreEvent(RestoreEvent event) {
    _restoreHistory.add(event);
    if (_restoreHistory.length > 50) {
      _restoreHistory.removeAt(0); // إزالة أقدم عملية
    }
    notifyListeners();

    debugPrint('🔄 إضافة عملية استعادة: ${event.restoreType}');
  }

  // ========== إدارة الأخطاء ==========

  /// تعيين خطأ
  void setError(String error) {
    _lastError = error;
    notifyListeners();

    // إطلاق حدث
    AppEventBus.fire(AppErrorEvent(error));

    debugPrint('❌ تعيين خطأ: $error');
  }

  /// مسح الخطأ
  void clearError() {
    _lastError = null;
    notifyListeners();

    debugPrint('🧹 مسح الخطأ');
  }

  // ========== معالجة الأحداث ==========

  /// معالجة الأحداث الواردة
  void _handleEvent(AppEvent event) {
    switch (event.runtimeType) {
      case ProductAddedEvent:
        _handleProductAdded(event as ProductAddedEvent);
        break;
      case ProductUpdatedEvent:
        _handleProductUpdated(event as ProductUpdatedEvent);
        break;
      case ProductDeletedEvent:
        _handleProductDeleted(event as ProductDeletedEvent);
        break;
      case InventoryUpdatedEvent:
        _handleInventoryUpdated(event as InventoryUpdatedEvent);
        break;
      case SaleCompletedEvent:
        _handleSaleCompleted(event as SaleCompletedEvent);
        break;
      case LowStockAlertEvent:
        _handleLowStockAlert(event as LowStockAlertEvent);
        break;
      case StatsUpdatedEvent:
        _handleStatsUpdated(event as StatsUpdatedEvent);
        break;
      default:
        debugPrint('📨 حدث غير معالج: ${event.runtimeType}');
    }
  }

  /// معالجة إضافة منتج
  void _handleProductAdded(ProductAddedEvent event) {
    // تحديث الإحصائيات
    final int currentCount = _localStats['productCount'] as int? ?? 0;
    _localStats['productCount'] = currentCount + 1;

    // حفظ المنتج الأخير
    setSharedData('lastAddedProduct', event.product);

    debugPrint('📦 معالجة إضافة منتج: ${event.product.name}');
  }

  /// معالجة تحديث منتج
  void _handleProductUpdated(ProductUpdatedEvent event) {
    // حفظ المنتج المحدث
    setSharedData('lastUpdatedProduct', event.product);

    debugPrint('✏️ معالجة تحديث منتج: ${event.product.name}');
  }

  /// معالجة حذف منتج
  void _handleProductDeleted(ProductDeletedEvent event) {
    // تحديث الإحصائيات
    final int currentCount = _localStats['productCount'] as int? ?? 0;
    if (currentCount > 0) {
      _localStats['productCount'] = currentCount - 1;
    }

    debugPrint('🗑️ معالجة حذف منتج: ${event.productName}');
  }

  /// معالجة تحديث المخزون
  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    // حفظ التحديث الأخير
    setSharedData('lastInventoryUpdate', <String, Object>{
      'itemId': event.itemId,
      'itemName': event.itemName,
      'oldQuantity': event.oldQuantity,
      'newQuantity': event.newQuantity,
    });

    debugPrint('📦 معالجة تحديث المخزون: ${event.itemName}');
  }

  /// معالجة إتمام بيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    // تحديث الإحصائيات
    final int currentSales = _localStats['totalSales'] as int? ?? 0;
    final double currentRevenue = _localStats['totalRevenue'] as double? ?? 0.0;

    _localStats['totalSales'] = currentSales + 1;
    _localStats['totalRevenue'] =
        currentRevenue + (event.sale.totalAmount / 100.0);

    // حفظ البيع الأخير
    setSharedData('lastSale', event.sale);

    debugPrint('💰 معالجة إتمام بيع: ${event.sale.totalAmount}');
  }

  /// معالجة تنبيه مخزون منخفض
  void _handleLowStockAlert(LowStockAlertEvent event) {
    // حفظ التنبيه
    setSharedData('lastLowStockAlert', <String, Object>{
      'itemId': event.itemId,
      'itemName': event.itemName,
      'currentQuantity': event.currentQuantity,
      'minimumQuantity': event.minimumQuantity,
    });

    debugPrint('⚠️ معالجة تنبيه مخزون منخفض: ${event.itemName}');
  }

  /// معالجة تحديث الإحصائيات
  void _handleStatsUpdated(StatsUpdatedEvent event) {
    // دمج الإحصائيات الجديدة
    _localStats.addAll(event.stats);
    notifyListeners();

    debugPrint('📊 معالجة تحديث الإحصائيات');
  }

  // ========== طرق مساعدة ==========

  /// تهيئة الإحصائيات
  void _initializeStats() {
    _localStats.addAll(<String, dynamic>{
      'productCount': 0,
      'inventoryCount': 0,
      'totalSales': 0,
      'totalRevenue': 0.0,
      'lowStockItems': 0,
      'lastSyncTime': null,
      'appVersion': '1.0.0',
    });
  }

  /// الحصول على ملخص الحالة
  Map<String, dynamic> getStateSummary() => {
        'isSyncing': _isSyncing,
        'pendingOperations': _pendingOperations,
        'isOnline': _isOnline,
        'connectionType': _connectionType,
        'lastError': _lastError,
        'sharedDataKeys': _sharedData.keys.toList(),
        'activeFiltersKeys': _activeFilters.keys.toList(),
        'localStatsKeys': _localStats.keys.toList(),
        'backupHistoryCount': _backupHistory.length,
        'restoreHistoryCount': _restoreHistory.length,
      };

  /// إعادة تعيين الحالة
  void resetState() {
    _isSyncing = false;
    _pendingOperations = 0;
    _sharedData.clear();
    _activeFilters.clear();
    _localStats.clear();
    _backupHistory.clear();
    _restoreHistory.clear();
    _lastError = null;

    _initializeStats();
    notifyListeners();

    debugPrint('🔄 إعادة تعيين الحالة');
  }
}
