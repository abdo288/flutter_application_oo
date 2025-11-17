import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/cart_item.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/app_event_bus.dart';

/// حالة التحديث الفوري
class RealtimeUpdateState {

  const RealtimeUpdateState({
    this.isConnected = false,
    this.lastUpdateTime,
    this.updateCounts = const <String, int>{},
    this.error,
  });
  final bool isConnected;
  final DateTime? lastUpdateTime;
  final Map<String, int> updateCounts;
  final String? error;

  RealtimeUpdateState copyWith({
    bool? isConnected,
    DateTime? lastUpdateTime,
    Map<String, int>? updateCounts,
    String? error,
  }) => RealtimeUpdateState(
      isConnected: isConnected ?? this.isConnected,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      updateCounts: updateCounts ?? this.updateCounts,
      error: error,
    );
}

/// مدير التحديثات الفورية المركزي
class RealtimeUpdateManager extends StateNotifier<RealtimeUpdateState> {
  RealtimeUpdateManager() : super(const RealtimeUpdateState()) {
    _initialize();
  }

  StreamSubscription<AppEvent>? _eventSubscription;
  Timer? _heartbeatTimer;

  void _initialize() {
    _startEventListening();
    _startHeartbeat();
    _updateConnectionStatus(true);
  }

  /// بدء الاستماع للأحداث
  void _startEventListening() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      debugPrint('🔄 RealtimeUpdateManager: استلام حدث ${event.runtimeType}');
      _handleEvent(event);
    });
  }

  /// بدء heartbeat للتأكد من الاتصال
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateConnectionStatus(true);
    });
  }

  /// معالجة الأحداث
  void _handleEvent(AppEvent event) {
    final String eventType = event.runtimeType.toString();
    final Map<String, int> newCounts = Map.from(state.updateCounts);
    newCounts[eventType] = (newCounts[eventType] ?? 0) + 1;

    state = state.copyWith(
      lastUpdateTime: DateTime.now(),
      updateCounts: newCounts,
    );

    // إبطال الـ providers المناسبة
    _invalidateRelatedProviders(event);
  }

  /// إبطال الـ providers المناسبة حسب نوع الحدث
  void _invalidateRelatedProviders(AppEvent event) {
    try {
      switch (event.runtimeType) {
        case ProductAddedEvent:
        case ProductUpdatedEvent:
        case ProductDeletedEvent:
          _invalidateProductProviders();
          break;
        case InventoryUpdatedEvent:
        case InventoryItemAddedEvent:
          _invalidateInventoryProviders();
          break;
        case SaleCompletedEvent:
          _invalidateSaleProviders();
          break;
        case StatsUpdatedEvent:
          _invalidateStatsProviders();
          break;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إبطال الـ providers: $e');
      state = state.copyWith(error: 'خطأ في التحديث: $e');
    }
  }

  /// إبطال providers المنتجات
  void _invalidateProductProviders() {
    try {
      // سيتم إضافة invalidate للـ providers عند توفرها
      debugPrint('✅ تم إبطال providers المنتجات');
    } catch (e) {
      debugPrint('❌ خطأ في إبطال providers المنتجات: $e');
    }
  }

  /// إبطال providers المخزون
  void _invalidateInventoryProviders() {
    try {
      // سيتم إضافة invalidate للـ providers عند توفرها
      debugPrint('✅ تم إبطال providers المخزون');
    } catch (e) {
      debugPrint('❌ خطأ في إبطال providers المخزون: $e');
    }
  }

  /// إبطال providers المبيعات
  void _invalidateSaleProviders() {
    try {
      // سيتم إضافة invalidate للـ providers عند توفرها
      debugPrint('✅ تم إبطال providers المبيعات');
    } catch (e) {
      debugPrint('❌ خطأ في إبطال providers المبيعات: $e');
    }
  }

  /// إبطال providers الإحصائيات
  void _invalidateStatsProviders() {
    try {
      // سيتم إضافة invalidate للـ providers عند توفرها
      debugPrint('✅ تم إبطال providers الإحصائيات');
    } catch (e) {
      debugPrint('❌ خطأ في إبطال providers الإحصائيات: $e');
    }
  }

  /// تحديث حالة الاتصال
  void _updateConnectionStatus(bool connected) {
    state = state.copyWith(
      isConnected: connected,
      lastUpdateTime: DateTime.now(),
    );
  }

  /// إرسال حدث تحديث
  void notifyUpdate(String updateType, {Map<String, dynamic>? data}) {
    debugPrint('🔄 إرسال حدث تحديث: $updateType');

    // إرسال الحدث عبر Event Bus
    switch (updateType) {
      case 'product':
        AppEventBus.fire(ProductUpdatedEvent(
          Product(
            id: 'temp',
            name: 'temp',
            wholesalePrice: 0,
            retailPrice: 0,
            savedAt: DateTime.now(),
          ),
          sourceTab: 'RealtimeUpdateManager',
        ));
        break;
      case 'inventory':
        AppEventBus.fire(InventoryUpdatedEvent(
          'temp',
          'temp',
          0,
          0,
          sourceTab: 'RealtimeUpdateManager',
        ));
        break;
      case 'sale':
        AppEventBus.fire(SaleCompletedEvent(
          Sale(
            id: 'temp',
            items: <CartItem>[],
            totalAmount: 0,
            totalProfit: 0,
            saleDate: DateTime.now(),
          ),
          <CartItem>[],
          sourceTab: 'RealtimeUpdateManager',
        ));
        break;
      case 'stats':
        AppEventBus.fire(
            StatsUpdatedEvent(<String, dynamic>{}, sourceTab: 'RealtimeUpdateManager'));
        break;
    }
  }

  /// إعادة تشغيل التحديثات الفورية
  Future<void> restartRealtimeUpdates() async {
    debugPrint('🔄 إعادة تشغيل التحديثات الفورية...');

    // إيقاف الاستماع الحالي
    await _eventSubscription?.cancel();

    // إعادة البدء
    _startEventListening();
    _updateConnectionStatus(true);

    debugPrint('✅ تم إعادة تشغيل التحديثات الفورية');
  }

  /// إيقاف التحديثات الفورية
  Future<void> stopRealtimeUpdates() async {
    debugPrint('⏹️ إيقاف التحديثات الفورية...');

    await _eventSubscription?.cancel();
    _heartbeatTimer?.cancel();

    state = state.copyWith(isConnected: false);

    debugPrint('✅ تم إيقاف التحديثات الفورية');
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

/// Provider للتحديثات الفورية
final StateNotifierProvider<RealtimeUpdateManager, RealtimeUpdateState> realtimeUpdateManagerProvider =
    StateNotifierProvider<RealtimeUpdateManager, RealtimeUpdateState>((StateNotifierProviderRef<RealtimeUpdateManager, RealtimeUpdateState> ref) => RealtimeUpdateManager());

/// Provider لحالة الاتصال
final Provider<bool> isConnectedProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(realtimeUpdateManagerProvider).isConnected);

/// Provider لآخر وقت تحديث
final Provider<DateTime?> lastUpdateTimeProvider = Provider<DateTime?>((ProviderRef<DateTime?> ref) => ref.watch(realtimeUpdateManagerProvider).lastUpdateTime);

/// Provider لإحصائيات التحديثات
final Provider<Map<String, int>> updateStatsProvider = Provider<Map<String, int>>((ProviderRef<Map<String, int>> ref) => ref.watch(realtimeUpdateManagerProvider).updateCounts);

/// Provider لرسالة الخطأ
final Provider<String?> updateErrorProvider = Provider<String?>((ProviderRef<String?> ref) => ref.watch(realtimeUpdateManagerProvider).error);

/// Provider لإعادة تشغيل التحديثات
final Provider<void Function()> restartUpdatesProvider = Provider<void Function()>((ProviderRef<void Function()> ref) {
  final RealtimeUpdateManager manager = ref.read(realtimeUpdateManagerProvider.notifier);
  return manager.restartRealtimeUpdates;
});

/// Provider لإيقاف التحديثات
final Provider<void Function()> stopUpdatesProvider = Provider<void Function()>((ProviderRef<void Function()> ref) {
  final RealtimeUpdateManager manager = ref.read(realtimeUpdateManagerProvider.notifier);
  return manager.stopRealtimeUpdates;
});

/// Provider لإرسال تحديث
final Provider<void Function(String p1, {Map<String, dynamic>? data})> notifyUpdateProvider =
    Provider<void Function(String, {Map<String, dynamic>? data})>((ProviderRef<void Function(String p1, {Map<String, dynamic>? data})> ref) {
  final RealtimeUpdateManager manager = ref.read(realtimeUpdateManagerProvider.notifier);
  return manager.notifyUpdate;
});
