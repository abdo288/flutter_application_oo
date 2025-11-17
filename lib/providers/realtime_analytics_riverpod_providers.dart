import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../services/app_event_bus.dart';
import '../services/unified_sales_repository.dart';

/// حالة التحليلات في الوقت الفعلي
class RealtimeAnalyticsState {
  const RealtimeAnalyticsState({
    this.sales = const <Sale>[],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
    this.analytics,
    this.trendAnalysis,
  });

  final List<Sale> sales;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? trendAnalysis;

  RealtimeAnalyticsState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? trendAnalysis,
  }) =>
      RealtimeAnalyticsState(
        sales: sales ?? this.sales,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        analytics: analytics ?? this.analytics,
        trendAnalysis: trendAnalysis ?? this.trendAnalysis,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtimeAnalyticsState &&
          runtimeType == other.runtimeType &&
          sales == other.sales &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          lastUpdated == other.lastUpdated &&
          analytics == other.analytics &&
          trendAnalysis == other.trendAnalysis;

  @override
  int get hashCode =>
      sales.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      lastUpdated.hashCode ^
      analytics.hashCode ^
      trendAnalysis.hashCode;
}

/// Notifier للتحليلات في الوقت الفعلي
class RealtimeAnalyticsNotifier extends StateNotifier<RealtimeAnalyticsState> {
  RealtimeAnalyticsNotifier(this._repository)
      : super(const RealtimeAnalyticsState()) {
    _setupEventListeners();
  }

  final UnifiedSalesRepository _repository;
  StreamSubscription<List<Sale>>? _salesSubscription;
  StreamSubscription<AppEvent>? _eventSubscription;

  /// إعداد الاستماع للأحداث
  void _setupEventListeners() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
      }
    });
  }

  /// معالجة حدث إتمام البيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint(
        '📊 RealtimeAnalytics: استلام حدث إتمام بيع - ${event.sale.totalAmount}');

    // إعادة تحميل البيانات فوراً
    _refreshAnalytics();
  }

  /// بدء مراقبة المبيعات في الوقت الفعلي
  void startRealtimeMonitoring({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) {
    // إلغاء الاشتراك السابق
    _salesSubscription?.cancel();

    state = state.copyWith(isLoading: true);

    // بدء مراقبة المبيعات
    _salesSubscription = _repository
        .watchSales(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    )
        .listen(
      (List<Sale> sales) {
        debugPrint('📊 تم تحديث المبيعات: ${sales.length} عملية بيع');
        _processSalesUpdate(sales);
      },
      onError: (Object error) {
        debugPrint('❌ خطأ في مراقبة المبيعات: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  /// معالجة تحديث المبيعات
  Future<void> _processSalesUpdate(List<Sale> sales) async {
    try {
      state = state.copyWith(
        sales: sales,
        lastUpdated: DateTime.now(),
        isLoading: false,
      );

      // حساب التحليلات في background
      await _calculateAnalytics(sales);
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث المبيعات: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// حساب التحليلات
  Future<void> _calculateAnalytics(List<Sale> sales) async {
    try {
      // حساب التحليلات الأساسية
      final Map<String, dynamic> analytics =
          await _repository.calculateSalesAnalytics(sales: sales);

      // حساب تحليل الاتجاهات
      final Map<String, dynamic> trendAnalysis =
          await _repository.calculateTrendAnalysis(sales: sales);

      state = state.copyWith(
        analytics: analytics,
        trendAnalysis: trendAnalysis,
      );

      debugPrint('✅ تم حساب التحليلات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حساب التحليلات: $e');
      // لا نحدث state في حالة الخطأ للحفاظ على البيانات السابقة
    }
  }

  /// تحديث البيانات يدوياً
  Future<void> _refreshAnalytics() async {
    try {
      state = state.copyWith(isLoading: true);

      final List<Sale> sales = await _repository.getAllSales();
      await _processSalesUpdate(sales);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث التحليلات: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// تحديث فترة المراقبة
  void updateDateRange({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) {
    startRealtimeMonitoring(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// إيقاف المراقبة
  void stopMonitoring() {
    _salesSubscription?.cancel();
    _salesSubscription = null;
    state = state.copyWith(isLoading: false);
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider للمستودع الموحد
final Provider<UnifiedSalesRepository> unifiedSalesRepositoryProvider =
    Provider<UnifiedSalesRepository>((ProviderRef<UnifiedSalesRepository> ref) => UnifiedSalesRepository());

/// Provider للتحليلات في الوقت الفعلي
final StateNotifierProvider<RealtimeAnalyticsNotifier, RealtimeAnalyticsState> realtimeAnalyticsProvider =
    StateNotifierProvider<RealtimeAnalyticsNotifier, RealtimeAnalyticsState>(
  (StateNotifierProviderRef<RealtimeAnalyticsNotifier, RealtimeAnalyticsState>
      ref) {
    final UnifiedSalesRepository repository = ref.watch(unifiedSalesRepositoryProvider);
    return RealtimeAnalyticsNotifier(repository);
  },
);

/// StreamProvider للمبيعات في الوقت الفعلي
final StreamProvider<List<Sale>> realtimeSalesStreamProvider = StreamProvider<List<Sale>>(
  (StreamProviderRef<List<Sale>> ref) {
    final UnifiedSalesRepository repository = ref.watch(unifiedSalesRepositoryProvider);
    return repository.watchSales(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  },
);

/// StreamProvider للتحليلات في الوقت الفعلي
final StreamProvider<Map<String, dynamic>> realtimeAnalyticsStreamProvider = StreamProvider<Map<String, dynamic>>(
  (StreamProviderRef<Map<String, dynamic>> ref) async* {
    final AsyncValue<List<Sale>> salesAsync = ref.watch(realtimeSalesStreamProvider);

    await for (final List<Sale> salesValue in salesAsync.when(
      data: (List<Sale> sales) async* {
        yield* Stream.value(sales);
      },
      loading: () async* {
        yield* Stream.value(<Sale>[]);
      },
      error: (_, __) async* {
        yield* Stream.value(<Sale>[]);
      },
    )) {
      if (salesValue.isNotEmpty) {
        final UnifiedSalesRepository repository = ref.watch(unifiedSalesRepositoryProvider);
        final Map<String, dynamic> analytics =
            await repository.calculateSalesAnalytics(sales: salesValue);
        yield analytics;
      } else {
        yield <String, dynamic>{
          'totalRevenue': 0.0,
          'totalProfit': 0.0,
          'totalTransactions': 0,
          'averageTransactionValue': 0.0,
          'averageProfit': 0.0,
          'hourlySales': <int, double>{},
          'dailySales': <DateTime, double>{},
        };
      }
    }
  },
);

/// StreamProvider لتحليل الاتجاهات في الوقت الفعلي
final StreamProvider<Map<String, dynamic>> realtimeTrendAnalysisStreamProvider =
    StreamProvider<Map<String, dynamic>>(
  (StreamProviderRef<Map<String, dynamic>> ref) async* {
    final AsyncValue<List<Sale>> salesAsync = ref.watch(realtimeSalesStreamProvider);

    await for (final List<Sale> salesValue in salesAsync.when(
      data: (List<Sale> sales) async* {
        yield* Stream.value(sales);
      },
      loading: () async* {
        yield* Stream.value(<Sale>[]);
      },
      error: (_, __) async* {
        yield* Stream.value(<Sale>[]);
      },
    )) {
      if (salesValue.length >= 2) {
        final UnifiedSalesRepository repository = ref.watch(unifiedSalesRepositoryProvider);
        final Map<String, dynamic> trendAnalysis =
            await repository.calculateTrendAnalysis(sales: salesValue);
        yield trendAnalysis;
      } else {
        yield <String, dynamic>{
          'revenueGrowth': 0.0,
          'profitGrowth': 0.0,
          'transactionGrowth': 0.0,
          'trend': 'stable',
        };
      }
    }
  },
);

/// Provider لإجمالي الإيرادات في الوقت الفعلي
final Provider<double> realtimeTotalRevenueProvider =
    Provider<double>((ProviderRef<double> ref) {
  final AsyncValue<Map<String, dynamic>> analyticsAsync = ref.watch(realtimeAnalyticsStreamProvider);
  return analyticsAsync.when(
    data: (Map<String, dynamic> analytics) =>
        (analytics['totalRevenue'] as double?) ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider لإجمالي الأرباح في الوقت الفعلي
final Provider<double> realtimeTotalProfitProvider = Provider<double>((ProviderRef<double> ref) {
  final AsyncValue<Map<String, dynamic>> analyticsAsync = ref.watch(realtimeAnalyticsStreamProvider);
  return analyticsAsync.when(
    data: (Map<String, dynamic> analytics) =>
        (analytics['totalProfit'] as double?) ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider لعدد المعاملات في الوقت الفعلي
final Provider<int> realtimeTransactionCountProvider = Provider<int>((ProviderRef<int> ref) {
  final AsyncValue<Map<String, dynamic>> analyticsAsync = ref.watch(realtimeAnalyticsStreamProvider);
  return analyticsAsync.when(
    data: (Map<String, dynamic> analytics) =>
        (analytics['totalTransactions'] as int?) ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider لمتوسط قيمة المعاملة في الوقت الفعلي
final Provider<double> realtimeAverageTransactionValueProvider =
    Provider<double>((ProviderRef<double> ref) {
  final AsyncValue<Map<String, dynamic>> analyticsAsync = ref.watch(realtimeAnalyticsStreamProvider);
  return analyticsAsync.when(
    data: (Map<String, dynamic> analytics) =>
        (analytics['averageTransactionValue'] as double?) ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider لنمو الإيرادات في الوقت الفعلي
final Provider<double> realtimeRevenueGrowthProvider =
    Provider<double>((ProviderRef<double> ref) {
  final AsyncValue<Map<String, dynamic>> trendAsync = ref.watch(realtimeTrendAnalysisStreamProvider);
  return trendAsync.when(
    data: (Map<String, dynamic> trend) =>
        (trend['revenueGrowth'] as double?) ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider لاتجاه النمو في الوقت الفعلي
final Provider<String> realtimeGrowthTrendProvider = Provider<String>((ProviderRef<String> ref) {
  final AsyncValue<Map<String, dynamic>> trendAsync = ref.watch(realtimeTrendAnalysisStreamProvider);
  return trendAsync.when(
    data: (Map<String, dynamic> trend) =>
        (trend['trend'] as String?) ?? 'stable',
    loading: () => 'stable',
    error: (_, __) => 'stable',
  );
});
