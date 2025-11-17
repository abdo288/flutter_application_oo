import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sale.dart';
import '../services/app_event_bus.dart';
import '../services/local_sales_service.dart';
import '../services/performance_optimized_analytics_service.dart';

/// حالة التقارير المحسنة
class EnhancedPOSReportsState {
  const EnhancedPOSReportsState({
    this.sales = const <Sale>[],
    this.isLoading = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
    this.analytics,
    this.trendAnalysis,
    this.hourlySales,
    this.dailySales,
    this.advancedAnalytics,
    this.lastUpdated,
  });

  final List<Sale> sales;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? trendAnalysis;
  final Map<int, double>? hourlySales;
  final Map<DateTime, double>? dailySales;
  final Map<String, dynamic>? advancedAnalytics;
  final DateTime? lastUpdated;

  EnhancedPOSReportsState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? trendAnalysis,
    Map<int, double>? hourlySales,
    Map<DateTime, double>? dailySales,
    Map<String, dynamic>? advancedAnalytics,
    DateTime? lastUpdated,
  }) =>
      EnhancedPOSReportsState(
        sales: sales ?? this.sales,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        analytics: analytics ?? this.analytics,
        trendAnalysis: trendAnalysis ?? this.trendAnalysis,
        hourlySales: hourlySales ?? this.hourlySales,
        dailySales: dailySales ?? this.dailySales,
        advancedAnalytics: advancedAnalytics ?? this.advancedAnalytics,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedPOSReportsState &&
          runtimeType == other.runtimeType &&
          sales == other.sales &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          analytics == other.analytics &&
          trendAnalysis == other.trendAnalysis &&
          hourlySales == other.hourlySales &&
          dailySales == other.dailySales &&
          advancedAnalytics == other.advancedAnalytics &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      sales.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      analytics.hashCode ^
      trendAnalysis.hashCode ^
      hourlySales.hashCode ^
      dailySales.hashCode ^
      advancedAnalytics.hashCode ^
      lastUpdated.hashCode;
}

/// Notifier للتقارير المحسنة
class EnhancedPOSReportsNotifier
    extends StateNotifier<EnhancedPOSReportsState> {
  EnhancedPOSReportsNotifier(
    this._analyticsService,
    this._localSalesService,
  ) : super(const EnhancedPOSReportsState()) {
    _setupEventListeners();
    _initializeDefaultDates();
  }

  final PerformanceOptimizedAnalyticsService _analyticsService;
  final LocalSalesService _localSalesService;
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
        '📊 EnhancedPOSReports: استلام حدث إتمام بيع - ${event.sale.totalAmount}');

    // تحديث البيانات فوراً
    _refreshAllData();
  }

  /// تهيئة التواريخ الافتراضية
  void _initializeDefaultDates() {
    final DateTime now = DateTime.now();
    state = state.copyWith(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  /// تحديث فترة التقارير
  Future<void> updateDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
      sales: <Sale>[], // مسح البيانات القديمة
    );

    await _refreshAllData();
  }

  /// تحديث جميع البيانات
  Future<void> _refreshAllData() async {
    if (state.startDate == null || state.endDate == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // جلب البيانات الأساسية من LocalSalesService
      final List<Sale> sales = await _localSalesService.getAllLocalSales();

      // تصفية البيانات حسب التاريخ المحدد
      final List<Sale> filteredSales = sales.where((Sale sale) => sale.saleDate
                .isAfter(state.startDate!.subtract(const Duration(days: 1))) &&
            sale.saleDate.isBefore(state.endDate!.add(const Duration(days: 1)))).toList();

      state = state.copyWith(
        sales: filteredSales,
        lastUpdated: DateTime.now(),
      );

      // حساب التحليلات في الخلفية
      await _calculateAllAnalytics(filteredSales);

      debugPrint('✅ تم تحديث جميع بيانات التقارير بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات التقارير: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// حساب جميع التحليلات
  Future<void> _calculateAllAnalytics(List<Sale> sales) async {
    try {
      // حساب التحليلات الأساسية
      final Map<String, dynamic> analytics =
          await _analyticsService.calculateOptimizedAnalytics(
        sales: sales,
      );

      // حساب تحليل الاتجاهات
      final Map<String, dynamic> trendAnalysis =
          await _analyticsService.calculateOptimizedTrendAnalysis(
        sales: sales,
      );

      // حساب المبيعات بالساعة
      final Map<int, double> hourlySales =
          await _analyticsService.calculateOptimizedHourlySales(
        sales: sales,
      );

      // حساب المبيعات اليومية
      final Map<DateTime, double> dailySales =
          await _analyticsService.calculateOptimizedDailySales(
        sales: sales,
      );

      // حساب التحليلات المتقدمة
      final Map<String, dynamic> advancedAnalytics =
          await _analyticsService.calculateAdvancedAnalytics(
        sales: sales,
      );

      state = state.copyWith(
        analytics: analytics,
        trendAnalysis: trendAnalysis,
        hourlySales: hourlySales,
        dailySales: dailySales,
        advancedAnalytics: advancedAnalytics,
      );

      debugPrint('✅ تم حساب جميع التحليلات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حساب التحليلات: $e');
      // لا نحدث state في حالة الخطأ للحفاظ على البيانات السابقة
    }
  }

  /// تحديث البيانات يدوياً
  Future<void> refreshData() async {
    await _refreshAllData();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  /// مسح cache التحليلات
  void clearAnalyticsCache() {
    _analyticsService.clearCache();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider للتقارير المحسنة
final StateNotifierProvider<EnhancedPOSReportsNotifier, EnhancedPOSReportsState> enhancedPOSReportsProvider =
    StateNotifierProvider<EnhancedPOSReportsNotifier, EnhancedPOSReportsState>(
  (StateNotifierProviderRef<EnhancedPOSReportsNotifier, EnhancedPOSReportsState>
      ref) {
    final PerformanceOptimizedAnalyticsService analyticsService =
        ref.watch(performanceOptimizedAnalyticsServiceProvider);
    final LocalSalesService localSalesService = LocalSalesService();
    return EnhancedPOSReportsNotifier(analyticsService, localSalesService);
  },
);

/// Provider لإجمالي الإيرادات من التقارير المحسنة
final Provider<double> enhancedTotalRevenueProvider =
    Provider<double>((ProviderRef<double> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.analytics?['totalRevenue'] as double? ?? 0.0;
});

/// Provider لإجمالي الأرباح من التقارير المحسنة
final Provider<double> enhancedTotalProfitProvider = Provider<double>((ProviderRef<double> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.analytics?['totalProfit'] as double? ?? 0.0;
});

/// Provider لعدد المعاملات من التقارير المحسنة
final Provider<int> enhancedTransactionCountProvider = Provider<int>((ProviderRef<int> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.analytics?['totalTransactions'] as int? ?? 0;
});

/// Provider لمتوسط قيمة المعاملة من التقارير المحسنة
final Provider<double> enhancedAverageTransactionValueProvider =
    Provider<double>((ProviderRef<double> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.analytics?['averageTransactionValue'] as double? ?? 0.0;
});

/// Provider لنمو الإيرادات من التقارير المحسنة
final Provider<double> enhancedRevenueGrowthProvider =
    Provider<double>((ProviderRef<double> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.trendAnalysis?['revenueGrowth'] as double? ?? 0.0;
});

/// Provider لاتجاه النمو من التقارير المحسنة
final Provider<String> enhancedGrowthTrendProvider = Provider<String>((ProviderRef<String> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.trendAnalysis?['trend'] as String? ?? 'stable';
});

/// Provider لبيانات الرسم البياني للمبيعات بالساعة
final Provider<List<FlSpot>> enhancedHourlySalesChartDataProvider =
    Provider<List<FlSpot>>((ProviderRef<List<FlSpot>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final Map<int, double>? hourlySales = reportsState.hourlySales;

  if (hourlySales == null || hourlySales.isEmpty) {
    return <FlSpot>[];
  }

  return hourlySales.entries
      .map((MapEntry<int, double> entry) =>
          FlSpot(entry.key.toDouble(), entry.value))
      .toList()
    ..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
});

/// Provider لبيانات الرسم البياني للمبيعات اليومية
final Provider<List<FlSpot>> enhancedDailySalesChartDataProvider =
    Provider<List<FlSpot>>((ProviderRef<List<FlSpot>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final Map<DateTime, double>? dailySales = reportsState.dailySales;

  if (dailySales == null || dailySales.isEmpty) {
    return <FlSpot>[];
  }

  final List<MapEntry<DateTime, double>> sortedEntries = dailySales.entries
      .toList()
    ..sort((MapEntry<DateTime, double> a, MapEntry<DateTime, double> b) =>
        a.key.compareTo(b.key));

  return sortedEntries
      .asMap()
      .entries
      .map((MapEntry<int, MapEntry<DateTime, double>> entry) =>
          FlSpot(entry.key.toDouble(), entry.value.value))
      .toList();
});

/// Provider للمنتجات الأكثر ربحية
final Provider<List<Map<String, dynamic>>> enhancedTopProductsProvider = Provider<List<Map<String, dynamic>>>(
    (ProviderRef<List<Map<String, dynamic>>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final List<dynamic>? topProducts =
      reportsState.advancedAnalytics?['topProducts'] as List<dynamic>?;
  return topProducts?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
});

/// Provider لتوزيع طرق الدفع
final Provider<Map<String, double>> enhancedPaymentMethodBreakdownProvider =
    Provider<Map<String, double>>((ProviderRef<Map<String, double>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final Map<String, dynamic>? paymentBreakdown = reportsState
      .advancedAnalytics?['paymentMethodBreakdown'] as Map<String, dynamic>?;
  return paymentBreakdown?.cast<String, double>() ?? <String, double>{};
});

/// Provider لساعات الذروة
final Provider<List<int>> enhancedPeakHoursProvider =
    Provider<List<int>>((ProviderRef<List<int>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final List<dynamic>? peakHours =
      reportsState.advancedAnalytics?['peakHours'] as List<dynamic>?;
  return peakHours?.cast<int>() ?? <int>[];
});

/// Provider لتوزيع الإيرادات (صباح، ظهر، مساء، ليل)
final Provider<Map<String, double>> enhancedRevenueDistributionProvider =
    Provider<Map<String, double>>((ProviderRef<Map<String, double>> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  final Map<String, dynamic>? revenueDistribution = reportsState
      .advancedAnalytics?['revenueDistribution'] as Map<String, dynamic>?;
  return revenueDistribution?.cast<String, double>() ?? <String, double>{};
});

/// Provider لحالة التحميل
final Provider<bool> enhancedReportsLoadingProvider = Provider<bool>((ProviderRef<bool> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.isLoading;
});

/// Provider لرسالة الخطأ
final Provider<String?> enhancedReportsErrorProvider =
    Provider<String?>((ProviderRef<String?> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.errorMessage;
});

/// Provider لآخر تحديث
final Provider<DateTime?> enhancedReportsLastUpdatedProvider =
    Provider<DateTime?>((ProviderRef<DateTime?> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.lastUpdated;
});

/// Provider للتحقق من وجود بيانات
final Provider<bool> enhancedReportsHasDataProvider = Provider<bool>((ProviderRef<bool> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.sales.isNotEmpty;
});

/// Provider للتحقق من وجود تحليلات
final Provider<bool> enhancedReportsHasAnalyticsProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  final EnhancedPOSReportsState reportsState = ref.watch(enhancedPOSReportsProvider);
  return reportsState.analytics != null;
});
