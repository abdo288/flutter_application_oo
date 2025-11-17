import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/page_result.dart';
import '../../models/sale.dart';
import '../models/common/date_range.dart';
import '../models/enums/payment_enums.dart';
import '../models/report_filter.dart';
import '../services/advanced_sales_service.dart';

/// Provider لخدمة المبيعات المتقدمة
final Provider<AdvancedSalesService> advancedSalesServiceProvider = Provider<AdvancedSalesService>((ProviderRef<AdvancedSalesService> ref) => AdvancedSalesService());

/// Provider لفلاتر التقارير
final StateProvider<ReportFilter> reportFilterProvider = StateProvider<ReportFilter>((StateProviderRef<ReportFilter> ref) => ReportFilter(
    dateRange: DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    ),
    searchQuery: '',
    sortBy: SortField.date,
    sortOrder: SortOrder.descending,
  ));

/// Provider لتحليلات المبيعات
final FutureProvider<PageResult<Sale>> salesAnalyticsProvider = FutureProvider<PageResult<Sale>>((FutureProviderRef<PageResult<Sale>> ref) async {
  final AdvancedSalesService service = ref.read(advancedSalesServiceProvider);
  final ReportFilter filter = ref.watch(reportFilterProvider);

  return await service.getSalesWithFilters(filter);
});

/// Provider للمبيعات حسب النطاق الزمني
final FutureProviderFamily<List<Sale>, Map<String, DateTime>> salesByTimeRangeProvider =
    FutureProvider.family<List<Sale>, Map<String, DateTime>>(
        (FutureProviderRef<List<Sale>> ref, Map<String, DateTime> params) async {
  final AdvancedSalesService service = ref.read(advancedSalesServiceProvider);
  final DateTime startDate = params['startDate']!;
  final DateTime endDate = params['endDate']!;

  return await service.getSalesByTimeRange(startDate, endDate);
});

/// Provider للمبيعات حسب طريقة الدفع
final FutureProviderFamily<List<Sale>, PaymentMethod> salesByPaymentMethodProvider =
    FutureProvider.family<List<Sale>, PaymentMethod>(
        (FutureProviderRef<List<Sale>> ref, PaymentMethod paymentMethod) async {
  final AdvancedSalesService service = ref.read(advancedSalesServiceProvider);
  return await service.getSalesByPaymentMethod(paymentMethod);
});

/// Provider للمبيعات حسب الموظف
final FutureProviderFamily<List<Sale>, String> salesByEmployeeProvider =
    FutureProvider.family<List<Sale>, String>((FutureProviderRef<List<Sale>> ref, String employeeId) async {
  final AdvancedSalesService service = ref.read(advancedSalesServiceProvider);
  return await service.getSalesByEmployee(employeeId);
});

/// Provider لمتوسط قيمة البيع
final FutureProviderFamily<double, Map<String, DateTime?>> averageSaleValueProvider =
    FutureProvider.family<double, Map<String, DateTime?>>((FutureProviderRef<double> ref, Map<String, DateTime?> params) async {
  final AdvancedSalesService service = ref.read(advancedSalesServiceProvider);
  final DateTime? startDate = params['startDate'];
  final DateTime? endDate = params['endDate'];

  return await service.getAverageSaleValue(startDate, endDate);
});

/// Provider لحالة التحديث
final StateProvider<bool> salesRefreshProvider = StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Provider لإعادة تحميل تحليلات المبيعات
final Provider<void Function()> refreshSalesAnalyticsProvider = Provider<void Function()>((ProviderRef<void Function()> ref) => () {
    ref.invalidate(salesAnalyticsProvider);
    ref.invalidate(salesByTimeRangeProvider);
    ref.invalidate(salesByPaymentMethodProvider);
    ref.invalidate(salesByEmployeeProvider);
    ref.invalidate(averageSaleValueProvider);
    ref.read(salesRefreshProvider.notifier).state =
        !ref.read(salesRefreshProvider);
  });
