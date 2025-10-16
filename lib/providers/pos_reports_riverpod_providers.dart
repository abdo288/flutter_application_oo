import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/page_result.dart';
import '../models/sale.dart';
import '../services/error_handler_service.dart';
import '../services/pos_service.dart';

// ========== State Model ==========

/// حالة تقارير نقطة البيع
class POSReportsState {
  const POSReportsState({
    this.sales = const <Sale>[],
    this.isLoading = false,
    this.isLoadingMoreSales = false,
    this.isLoadingMoreQuick = false,
    this.hasMoreSales = true,
    this.hasMoreQuick = true,
    this.startDate,
    this.endDate,
    this.lastQuickDoc,
    this.errorMessage,
  });

  final List<Sale> sales;
  final bool isLoading;
  final bool isLoadingMoreSales;
  final bool isLoadingMoreQuick;
  final bool hasMoreSales;
  final bool hasMoreQuick;
  final DateTime? startDate;
  final DateTime? endDate;
  final DocumentSnapshot<Map<String, dynamic>>? lastQuickDoc;
  final String? errorMessage;

  POSReportsState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    bool? isLoadingMoreSales,
    bool? isLoadingMoreQuick,
    bool? hasMoreSales,
    bool? hasMoreQuick,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot<Map<String, dynamic>>? lastQuickDoc,
    String? errorMessage,
  }) =>
      POSReportsState(
        sales: sales ?? this.sales,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMoreSales: isLoadingMoreSales ?? this.isLoadingMoreSales,
        isLoadingMoreQuick: isLoadingMoreQuick ?? this.isLoadingMoreQuick,
        hasMoreSales: hasMoreSales ?? this.hasMoreSales,
        hasMoreQuick: hasMoreQuick ?? this.hasMoreQuick,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        lastQuickDoc: lastQuickDoc ?? this.lastQuickDoc,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is POSReportsState &&
          runtimeType == other.runtimeType &&
          sales == other.sales &&
          isLoading == other.isLoading &&
          isLoadingMoreSales == other.isLoadingMoreSales &&
          isLoadingMoreQuick == other.isLoadingMoreQuick &&
          hasMoreSales == other.hasMoreSales &&
          hasMoreQuick == other.hasMoreQuick &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          lastQuickDoc == other.lastQuickDoc &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      sales.hashCode ^
      isLoading.hashCode ^
      isLoadingMoreSales.hashCode ^
      isLoadingMoreQuick.hashCode ^
      hasMoreSales.hashCode ^
      hasMoreQuick.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      lastQuickDoc.hashCode ^
      errorMessage.hashCode;
}

// ========== StateNotifier ==========

/// Notifier لإدارة حالة تقارير نقطة البيع
class POSReportsNotifier extends StateNotifier<POSReportsState> {
  POSReportsNotifier() : super(const POSReportsState()) {
    _initializeDefaultDates();
  }

  /// تهيئة التواريخ الافتراضية
  void _initializeDefaultDates() {
    final DateTime now = DateTime.now();
    state = state.copyWith(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  /// تحميل البيانات
  Future<void> loadData() async {
    if (state.startDate == null || state.endDate == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.wait(<Future<void>>[
        _loadSales(),
      ]);
      debugPrint('✅ تم تحميل بيانات التقارير بنجاح');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      debugPrint('❌ خطأ في تحميل بيانات التقارير: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// تحميل عمليات البيع
  Future<void> _loadSales() async {
    if (state.startDate == null || state.endDate == null) return;

    try {
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: state.startDate!,
        endDate: state.endDate!,
      );

      state = state.copyWith(
        sales: page.items,
        hasMoreSales: page.hasMore,
      );
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل عمليات البيع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadSales',
        },
      );
      rethrow;
    }
  }

  /// تحميل المزيد من المبيعات
  Future<void> loadMoreSales() async {
    if (state.isLoadingMoreSales || !state.hasMoreSales) return;
    if (state.startDate == null || state.endDate == null) return;

    state = state.copyWith(isLoadingMoreSales: true);

    try {
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: state.startDate!,
        endDate: state.endDate!,
      );

      state = state.copyWith(
        sales: <Sale>[...state.sales, ...page.items],
        hasMoreSales: page.hasMore,
      );
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل المزيد من المبيعات في تقارير POS',
        context: <String, dynamic>{
          'operation': 'loadMoreSales',
        },
      );
      rethrow;
    } finally {
      state = state.copyWith(isLoadingMoreSales: false);
    }
  }

  /// تحديث نطاق التاريخ
  Future<void> updateDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      sales: <Sale>[], // مسح البيانات القديمة
      hasMoreSales: true,
      hasMoreQuick: true,
      lastQuickDoc: null,
    );
    await loadData();
  }

  /// تحديث البيانات
  Future<void> refreshData() async {
    await loadData();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ========== Providers ==========

/// Provider للحالة الرئيسية
final posReportsProvider =
    StateNotifierProvider<POSReportsNotifier, POSReportsState>((ref) {
  return POSReportsNotifier();
});

/// Provider لبيانات رسم المبيعات
final salesChartDataProvider = Provider<List<FlSpot>>((ref) {
  final POSReportsState state = ref.watch(posReportsProvider);
  return _calculateSalesChartData(state.sales, state.startDate);
});

/// Provider لبيانات رسم الأرباح
final profitChartDataProvider = Provider<List<FlSpot>>((ref) {
  final POSReportsState state = ref.watch(posReportsProvider);
  return _calculateProfitChartData(state.sales, state.startDate);
});

/// Provider لبيانات طرق الدفع
final paymentMethodDataProvider = Provider<List<PieChartSectionData>>((ref) {
  final POSReportsState state = ref.watch(posReportsProvider);
  return _calculatePaymentMethodData(state.sales);
});

/// Provider لبيانات المبيعات اليومية
final dailySalesDataProvider = Provider<List<BarChartGroupData>>((ref) {
  final POSReportsState state = ref.watch(posReportsProvider);
  return _calculateDailySalesData(state.sales);
});

/// Provider لعدد المبيعات غير المزامنة
final unsyncedSalesCountProvider = Provider<int>((ref) {
  final POSReportsState state = ref.watch(posReportsProvider);
  return state.sales.where((Sale sale) => !sale.isSynced).length;
});

// ========== Chart Data Calculation Functions ==========

/// حساب بيانات رسم المبيعات
List<FlSpot> _calculateSalesChartData(List<Sale> sales, DateTime? startDate) {
  if (startDate == null) return <FlSpot>[];

  final Map<String, double> dailySales = <String, double>{};

  for (final Sale sale in sales) {
    final String dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
    dailySales[dateKey] =
        (dailySales[dateKey] ?? 0) + sale.totalAmount.toDouble();
  }

  return dailySales.entries.map((MapEntry<String, double> entry) {
    final DateTime date = DateTime.parse(entry.key);
    final double daysSinceStart = date.difference(startDate).inDays.toDouble();
    return FlSpot(daysSinceStart, entry.value);
  }).toList()
    ..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
}

/// حساب بيانات رسم الأرباح
List<FlSpot> _calculateProfitChartData(List<Sale> sales, DateTime? startDate) {
  if (startDate == null) return <FlSpot>[];

  final Map<String, double> dailyProfit = <String, double>{};

  for (final Sale sale in sales) {
    final String dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
    dailyProfit[dateKey] =
        (dailyProfit[dateKey] ?? 0) + sale.totalProfit.toDouble();
  }

  return dailyProfit.entries.map((MapEntry<String, double> entry) {
    final DateTime date = DateTime.parse(entry.key);
    final double daysSinceStart = date.difference(startDate).inDays.toDouble();
    return FlSpot(daysSinceStart, entry.value);
  }).toList()
    ..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
}

/// حساب بيانات طرق الدفع
List<PieChartSectionData> _calculatePaymentMethodData(List<Sale> sales) {
  final Map<String, int> paymentMethods = <String, int>{};

  for (final Sale sale in sales) {
    paymentMethods[sale.paymentMethod] =
        (paymentMethods[sale.paymentMethod] ?? 0) + 1;
  }

  final List<Color> colors = <Color>[
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];

  return paymentMethods.entries.map((MapEntry<String, int> entry) {
    final int index = paymentMethods.keys.toList().indexOf(entry.key);
    return PieChartSectionData(
      color: colors[index % colors.length],
      value: entry.value.toDouble(),
      title: entry.key,
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();
}

/// حساب بيانات المبيعات اليومية
List<BarChartGroupData> _calculateDailySalesData(List<Sale> sales) {
  final Map<String, double> dailySales = <String, double>{};

  for (final Sale sale in sales) {
    final String dateKey = DateFormat('MM-dd').format(sale.saleDate);
    dailySales[dateKey] =
        (dailySales[dateKey] ?? 0) + sale.totalAmount.toDouble();
  }

  return dailySales.entries.map((MapEntry<String, double> entry) {
    final int index = dailySales.keys.toList().indexOf(entry.key);
    return BarChartGroupData(
      x: index,
      barRods: <BarChartRodData>[
        BarChartRodData(
          toY: entry.value,
          color: Colors.purple,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }).toList();
}
