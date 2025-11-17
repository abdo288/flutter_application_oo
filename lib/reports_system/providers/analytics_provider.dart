import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart_data.dart';
import '../models/sales_analytics.dart';
import '../services/analytics_service.dart';

/// Provider لخدمة التحليلات
final Provider<AnalyticsService> analyticsServiceProvider = Provider<AnalyticsService>((ProviderRef<AnalyticsService> ref) => AnalyticsService());

/// Provider لتحليل الاتجاهات
final FutureProviderFamily<TrendAnalysis, Map<String, DateTime>> trendAnalysisProvider =
    FutureProvider.family<TrendAnalysis, Map<String, DateTime>>(
        (FutureProviderRef<TrendAnalysis> ref, Map<String, DateTime> params) async {
  final AnalyticsService service = ref.read(analyticsServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;
  return await service.getTrendAnalysis(startDate, endDate);
});

/// Provider للرسم البياني للمبيعات الساعية
final FutureProviderFamily<ChartData, DateTime> hourlySalesChartProvider =
    FutureProvider.family<ChartData, DateTime>((FutureProviderRef<ChartData> ref, DateTime date) async {
  final AnalyticsService service = ref.read(analyticsServiceProvider);
  return await service.getHourlySalesChart(date);
});

/// Provider للرسم البياني للمبيعات اليومية
final FutureProviderFamily<ChartData, Map<String, DateTime>> dailySalesChartProvider =
    FutureProvider.family<ChartData, Map<String, DateTime>>(
        (FutureProviderRef<ChartData> ref, Map<String, DateTime> params) async {
  final AnalyticsService service = ref.read(analyticsServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;
  return await service.getDailySalesChart(startDate, endDate);
});

/// Provider للرسم البياني لتوزيع طرق الدفع
final FutureProviderFamily<ChartData, Map<String, DateTime>> paymentDistributionChartProvider =
    FutureProvider.family<ChartData, Map<String, DateTime>>(
        (FutureProviderRef<ChartData> ref, Map<String, DateTime> params) async {
  final AnalyticsService service = ref.read(analyticsServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;
  return await service.getPaymentDistributionChart(startDate, endDate);
});

/// Provider للرسم البياني لأفضل المنتجات
final FutureProviderFamily<ChartData, Map<String, DateTime>> topProductsChartProvider =
    FutureProvider.family<ChartData, Map<String, DateTime>>(
        (FutureProviderRef<ChartData> ref, Map<String, DateTime> params) async {
  final AnalyticsService service = ref.read(analyticsServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;
  return await service.getTopProductsChart(startDate, endDate);
});

/// Provider لحالة التحديث
final StateProvider<bool> analyticsRefreshProvider = StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Provider لإعادة تحميل التحليلات
final Provider<void Function()> refreshAnalyticsProvider = Provider<void Function()>((ProviderRef<void Function()> ref) => () {
    ref.invalidate(trendAnalysisProvider);
    ref.invalidate(hourlySalesChartProvider);
    ref.invalidate(dailySalesChartProvider);
    ref.invalidate(paymentDistributionChartProvider);
    ref.invalidate(topProductsChartProvider);
    ref.read(analyticsRefreshProvider.notifier).state =
        !ref.read(analyticsRefreshProvider);
  });
