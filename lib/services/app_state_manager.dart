import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_event_bus.dart';
import 'data_consistency_service.dart';

/// حالة التطبيق
@immutable
class AppState {
  const AppState({
    this.isSyncing = false,
    this.pendingOperations = 0,
    this.isOnline = true,
    this.connectionType,
    this.lastError,
    this.localStats = const <String, dynamic>{},
    this.activeFilters = const <String, dynamic>{},
    this.backupHistory = const <BackupEvent>[],
    this.restoreHistory = const <RestoreEvent>[],
  });

  final bool isSyncing;
  final int pendingOperations;
  final bool isOnline;
  final String? connectionType;
  final String? lastError;
  final Map<String, dynamic> localStats;
  final Map<String, dynamic> activeFilters;
  final List<BackupEvent> backupHistory;
  final List<RestoreEvent> restoreHistory;

  AppState copyWith({
    bool? isSyncing,
    int? pendingOperations,
    bool? isOnline,
    String? connectionType,
    String? lastError,
    Map<String, dynamic>? localStats,
    Map<String, dynamic>? activeFilters,
    List<BackupEvent>? backupHistory,
    List<RestoreEvent>? restoreHistory,
  }) =>
      AppState(
        isSyncing: isSyncing ?? this.isSyncing,
        pendingOperations: pendingOperations ?? this.pendingOperations,
        isOnline: isOnline ?? this.isOnline,
        connectionType: connectionType ?? this.connectionType,
        lastError: lastError ?? this.lastError,
        localStats: localStats ?? this.localStats,
        activeFilters: activeFilters ?? this.activeFilters,
        backupHistory: backupHistory ?? this.backupHistory,
        restoreHistory: restoreHistory ?? this.restoreHistory,
      );
}

/// مدير الحالة المشتركة للتطبيق
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _initialize();
  }

  /// Stream subscriptions
  StreamSubscription<AppEvent>? _eventSubscription;

  // ========== تهيئة وإغلاق ==========

  /// تهيئة AppStateNotifier
  void _initialize() {
    debugPrint('🚀 تهيئة AppStateNotifier...');

    // الاستماع للأحداث
    _eventSubscription = AppEventBus.stream.listen(_handleEvent);

    // تهيئة الإحصائيات
    _initializeStats();

    debugPrint('✅ تم تهيئة AppStateNotifier بنجاح');
  }

  /// إغلاق AppStateNotifier
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // ========== إدارة المزامنة ==========

  /// بدء المزامنة
  void startSync(String syncType, int totalItems) {
    state = state.copyWith(
      isSyncing: true,
      pendingOperations: totalItems,
    );

    // إطلاق حدث
    AppEventBus.fire(SyncStartedEvent(syncType, totalItems));

    debugPrint('🔄 بدء المزامنة: $syncType ($totalItems عنصر)');
  }

  /// تحديث تقدم المزامنة
  void updateSyncProgress(int completedItems) {
    final int newPendingOperations = state.pendingOperations - completedItems;
    state = state.copyWith(
      pendingOperations: newPendingOperations < 0 ? 0 : newPendingOperations,
    );

    debugPrint('📊 تقدم المزامنة: $completedItems عنصر مكتمل');
  }

  /// انتهاء المزامنة
  void endSync(String syncType, int syncedItems,
      {bool success = true, String? error}) {
    state = state.copyWith(
      isSyncing: false,
      pendingOperations: 0,
      lastError: (!success && error != null) ? error : state.lastError,
    );

    // إطلاق حدث
    AppEventBus.fire(SyncCompletedEvent(syncType, syncedItems,
        success: success, error: error));

    debugPrint('✅ انتهاء المزامنة: $syncType (${success ? 'نجح' : 'فشل'})');
  }

  // ========== إدارة البيانات المشتركة ==========

  /// حفظ بيانات مشتركة
  void setSharedData(String key, value) {
    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats[key] = value;
    state = state.copyWith(localStats: newLocalStats);

    debugPrint('💾 حفظ بيانات مشتركة: $key = $value');
  }

  /// قراءة بيانات مشتركة
  T? getSharedData<T>(String key) {
    final value = state.localStats[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// حذف بيانات مشتركة
  void removeSharedData(String key) {
    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats.remove(key);
    state = state.copyWith(localStats: newLocalStats);

    debugPrint('🗑️ حذف بيانات مشتركة: $key');
  }

  /// مسح جميع البيانات المشتركة
  void clearSharedData() {
    state = state.copyWith(localStats: <String, dynamic>{});

    debugPrint('🧹 مسح جميع البيانات المشتركة');
  }

  // ========== إدارة الاتصال ==========

  /// تحديث حالة الاتصال
  void updateConnectivity(bool isOnline, {String? connectionType}) {
    state = state.copyWith(
      isOnline: isOnline,
      connectionType: connectionType,
    );

    // إطلاق حدث
    AppEventBus.fire(
        ConnectivityChangedEvent(isOnline, connectionType: connectionType));

    debugPrint('🌐 تحديث الاتصال: ${isOnline ? 'متصل' : 'غير متصل'}');
  }

  // ========== إدارة الإحصائيات ==========

  /// تحديث الإحصائيات المحلية
  void updateStats(Map<String, dynamic> stats) {
    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats.addAll(stats);
    state = state.copyWith(localStats: newLocalStats);

    // إطلاق حدث
    AppEventBus.fire(StatsUpdatedEvent(stats));

    debugPrint('📊 تحديث الإحصائيات: ${stats.keys.join(', ')}');
  }

  /// الحصول على إحصائية محددة
  T? getStat<T>(String key) {
    final value = state.localStats[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// مسح الإحصائيات
  void clearStats() {
    state = state.copyWith(localStats: <String, dynamic>{});

    debugPrint('🧹 مسح الإحصائيات');
  }

  // ========== إدارة الفلاتر ==========

  /// تعيين فلتر نشط
  void setActiveFilter(String tabName, Map<String, dynamic> filters) {
    final Map<String, dynamic> newActiveFilters =
        Map<String, dynamic>.from(state.activeFilters);
    newActiveFilters[tabName] = filters;
    state = state.copyWith(activeFilters: newActiveFilters);

    // إطلاق حدث
    AppEventBus.fire(FilterChangedEvent(tabName, filters));

    debugPrint('🔍 تعيين فلتر نشط: $tabName');
  }

  /// الحصول على فلتر نشط
  Map<String, dynamic>? getActiveFilter(String tabName) {
    final filter = state.activeFilters[tabName];
    if (filter is Map<String, dynamic>) {
      return filter;
    }
    return null;
  }

  /// مسح فلتر نشط
  void clearActiveFilter(String tabName) {
    final Map<String, dynamic> newActiveFilters =
        Map<String, dynamic>.from(state.activeFilters);
    newActiveFilters.remove(tabName);
    state = state.copyWith(activeFilters: newActiveFilters);

    debugPrint('🧹 مسح فلتر نشط: $tabName');
  }

  /// مسح جميع الفلاتر
  void clearAllFilters() {
    state = state.copyWith(activeFilters: <String, dynamic>{});

    debugPrint('🧹 مسح جميع الفلاتر');
  }

  // ========== إدارة النسخ الاحتياطي ==========

  /// إضافة عملية نسخ احتياطي
  void addBackupEvent(BackupEvent event) {
    final List<BackupEvent> newBackupHistory =
        List<BackupEvent>.from(state.backupHistory);
    newBackupHistory.add(event);
    if (newBackupHistory.length > 50) {
      newBackupHistory.removeAt(0); // إزالة أقدم عملية
    }
    state = state.copyWith(backupHistory: newBackupHistory);

    debugPrint('💾 إضافة عملية نسخ احتياطي: ${event.backupType}');
  }

  /// إضافة عملية استعادة
  void addRestoreEvent(RestoreEvent event) {
    final List<RestoreEvent> newRestoreHistory =
        List<RestoreEvent>.from(state.restoreHistory);
    newRestoreHistory.add(event);
    if (newRestoreHistory.length > 50) {
      newRestoreHistory.removeAt(0); // إزالة أقدم عملية
    }
    state = state.copyWith(restoreHistory: newRestoreHistory);

    debugPrint('🔄 إضافة عملية استعادة: ${event.restoreType}');
  }

  // ========== إدارة الأخطاء ==========

  /// تعيين خطأ
  void setError(String error) {
    state = state.copyWith(lastError: error);

    // إطلاق حدث
    AppEventBus.fire(AppErrorEvent(error));

    debugPrint('❌ تعيين خطأ: $error');
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith();

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
    final int currentCount = state.localStats['productCount'] as int? ?? 0;
    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats['productCount'] = currentCount + 1;
    state = state.copyWith(localStats: newLocalStats);

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
    final int currentCount = state.localStats['productCount'] as int? ?? 0;
    if (currentCount > 0) {
      final Map<String, dynamic> newLocalStats =
          Map<String, dynamic>.from(state.localStats);
      newLocalStats['productCount'] = currentCount - 1;
      state = state.copyWith(localStats: newLocalStats);
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
    final int currentSales = state.localStats['totalSales'] as int? ?? 0;
    final double currentRevenue =
        state.localStats['totalRevenue'] as double? ?? 0.0;

    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats['totalSales'] = currentSales + 1;
    newLocalStats['totalRevenue'] =
        currentRevenue + (event.sale.totalAmount / 100.0);
    state = state.copyWith(localStats: newLocalStats);

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
    final Map<String, dynamic> newLocalStats =
        Map<String, dynamic>.from(state.localStats);
    newLocalStats.addAll(event.stats);
    state = state.copyWith(localStats: newLocalStats);

    debugPrint('📊 معالجة تحديث الإحصائيات');
  }

  // ========== طرق مساعدة ==========

  /// تهيئة الإحصائيات
  void _initializeStats() {
    state = state.copyWith(localStats: <String, dynamic>{
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
  Map<String, dynamic> getStateSummary() => <String, dynamic>{
        'isSyncing': state.isSyncing,
        'pendingOperations': state.pendingOperations,
        'isOnline': state.isOnline,
        'connectionType': state.connectionType,
        'lastError': state.lastError,
        'sharedDataKeys': state.localStats.keys.toList(),
        'activeFiltersKeys': state.activeFilters.keys.toList(),
        'localStatsKeys': state.localStats.keys.toList(),
        'backupHistoryCount': state.backupHistory.length,
        'restoreHistoryCount': state.restoreHistory.length,
      };

  /// إعادة تعيين الحالة
  void resetState() {
    state = const AppState();
    _initializeStats();

    debugPrint('🔄 إعادة تعيين الحالة');
  }

  /// بدء مراقبة تناسق البيانات
  /// ✅ إصلاح: ضمان التناسق بين التبويبين
  void startDataConsistencyMonitoring() {
    debugPrint('🔄 بدء مراقبة تناسق البيانات بين التبويبين');
    DataConsistencyService().startConsistencyMonitoring();
  }

  /// إيقاف مراقبة تناسق البيانات
  void stopDataConsistencyMonitoring() {
    debugPrint('⏹️ إيقاف مراقبة تناسق البيانات');
    DataConsistencyService().stopConsistencyMonitoring();
  }

  /// إجبار إعادة تحميل البيانات
  Future<void> forceDataRefresh() async {
    debugPrint('🔄 إجبار إعادة تحميل البيانات من AppStateManager');
    await DataConsistencyService().forceDataRefresh();
  }
}

// ========== Riverpod Providers ==========

/// Provider للـ AppStateNotifier
final StateNotifierProvider<AppStateNotifier, AppState>
    appStateNotifierProvider =
    StateNotifierProvider<AppStateNotifier, AppState>(
        (StateNotifierProviderRef<AppStateNotifier, AppState> ref) =>
            AppStateNotifier());

/// Provider لحالة المزامنة
final Provider<bool> isSyncingProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(appStateNotifierProvider).isSyncing);

/// Provider لحالة الاتصال
final Provider<bool> isOnlineProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(appStateNotifierProvider).isOnline);

/// Provider للعمليات المعلقة
final Provider<int> pendingOperationsProvider = Provider<int>(
    (ProviderRef<int> ref) =>
        ref.watch(appStateNotifierProvider).pendingOperations);

/// Provider لنوع الاتصال
final Provider<String?> connectionTypeProvider = Provider<String?>(
    (ProviderRef<String?> ref) =>
        ref.watch(appStateNotifierProvider).connectionType);

/// Provider لملخص الحالة
final Provider<Map<String, dynamic>> stateSummaryProvider =
    Provider<Map<String, dynamic>>((ProviderRef<Map<String, dynamic>> ref) =>
        ref.watch(appStateNotifierProvider.notifier).getStateSummary());
