import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

/// Provider لخدمة لوحة التحكم
final Provider<DashboardService> dashboardServiceProvider = Provider<DashboardService>((ProviderRef<DashboardService> ref) => DashboardService());

/// Provider لإحصائيات لوحة التحكم
final FutureProvider<DashboardSummary> dashboardSummaryProvider = FutureProvider<DashboardSummary>((FutureProviderRef<DashboardSummary> ref) async {
  final DashboardService dashboardService = ref.read(dashboardServiceProvider);
  return await dashboardService.getDashboardSummary();
});

/// Provider للإحصائيات السريعة
final FutureProviderFamily<Map<String, dynamic>, Map<String, DateTime>> quickStatsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, DateTime>>(
        (FutureProviderRef<Map<String, dynamic>> ref, Map<String, DateTime> params) async {
  final DashboardService dashboardService = ref.read(dashboardServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;
  return await dashboardService.getQuickStats(startDate, endDate);
});

/// Provider لبيانات الرسم البياني للمبيعات
final FutureProvider<List<Map<String, dynamic>>> salesChartDataProvider =
    FutureProvider<List<Map<String, dynamic>>>((FutureProviderRef<List<Map<String, dynamic>>> ref) async {
  final DashboardService dashboardService = ref.read(dashboardServiceProvider);
  return await dashboardService.getDailySalesChart();
});

/// Provider لحالة التحديث
final StateProvider<bool> dashboardRefreshProvider = StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Provider لإعادة تحميل لوحة التحكم
final Provider<void Function()> refreshDashboardProvider = Provider<void Function()>((ProviderRef<void Function()> ref) => () {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(quickStatsProvider);
    ref.invalidate(salesChartDataProvider);
    ref.read(dashboardRefreshProvider.notifier).state =
        !ref.read(dashboardRefreshProvider);
  });
