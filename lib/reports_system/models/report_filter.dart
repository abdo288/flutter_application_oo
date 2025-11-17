import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'common/date_range.dart';
import 'common/price_range.dart';
import 'enums/payment_enums.dart';

part 'report_filter.freezed.dart';
part 'report_filter.g.dart';

/// نموذج فلتر التقارير
@freezed
class ReportFilter with _$ReportFilter {
  const factory ReportFilter({
    DateRange? dateRange,
    List<PaymentMethod>? paymentMethods,
    List<String>? employees,
    PriceRange? priceRange,
    List<String>? categories,
    List<String>? suppliers,
    SyncStatus? syncStatus,
    String? searchQuery,
    SortField? sortBy,
    SortOrder? sortOrder,
    int? limit,
    int? offset,
  }) = _ReportFilter;

  factory ReportFilter.fromJson(Map<String, dynamic> json) =>
      _$ReportFilterFromJson(json);
}

/// Extensions for computed properties
extension ReportFilterX on ReportFilter {
  /// إنشاء فلتر فارغ
  static ReportFilter empty() => const ReportFilter();

  /// إنشاء فلتر للتاريخ فقط
  static ReportFilter byDateRange(DateTime startDate, DateTime endDate) => ReportFilter(
      dateRange: DateRange(startDate: startDate, endDate: endDate),
    );

  /// إنشاء فلتر للموظف
  static ReportFilter byEmployee(String employeeId) => ReportFilter(
      employees: <String>[employeeId],
    );

  /// إنشاء فلتر لطريقة الدفع
  static ReportFilter byPaymentMethod(PaymentMethod method) => ReportFilter(
      paymentMethods: <PaymentMethod>[method],
    );

  /// التحقق من وجود فلاتر نشطة
  bool get hasActiveFilters => dateRange != null ||
        (paymentMethods?.isNotEmpty ?? false) ||
        (employees?.isNotEmpty ?? false) ||
        priceRange != null ||
        (categories?.isNotEmpty ?? false) ||
        (suppliers?.isNotEmpty ?? false) ||
        syncStatus != null ||
        (searchQuery?.isNotEmpty ?? false);

  /// إعادة تعيين جميع الفلاتر
  ReportFilter clear() => const ReportFilter();

  /// إضافة طريقة دفع
  ReportFilter addPaymentMethod(PaymentMethod method) {
    final List<PaymentMethod> currentMethods = paymentMethods ?? <PaymentMethod>[];
    if (currentMethods.contains(method)) return this;
    return copyWith(paymentMethods: <PaymentMethod>[...currentMethods, method]);
  }

  /// إزالة طريقة دفع
  ReportFilter removePaymentMethod(PaymentMethod method) {
    final List<PaymentMethod> currentMethods = paymentMethods ?? <PaymentMethod>[];
    if (!currentMethods.contains(method)) return this;
    return copyWith(
      paymentMethods: currentMethods.where((PaymentMethod m) => m != method).toList(),
    );
  }

  /// إضافة موظف
  ReportFilter addEmployee(String employeeId) {
    final List<String> currentEmployees = employees ?? <String>[];
    if (currentEmployees.contains(employeeId)) return this;
    return copyWith(employees: <String>[...currentEmployees, employeeId]);
  }

  /// إزالة موظف
  ReportFilter removeEmployee(String employeeId) {
    final List<String> currentEmployees = employees ?? <String>[];
    if (!currentEmployees.contains(employeeId)) return this;
    return copyWith(
      employees: currentEmployees.where((String e) => e != employeeId).toList(),
    );
  }

  /// إضافة فئة
  ReportFilter addCategory(String category) {
    final List<String> currentCategories = categories ?? <String>[];
    if (currentCategories.contains(category)) return this;
    return copyWith(categories: <String>[...currentCategories, category]);
  }

  /// إزالة فئة
  ReportFilter removeCategory(String category) {
    final List<String> currentCategories = categories ?? <String>[];
    if (!currentCategories.contains(category)) return this;
    return copyWith(
      categories: currentCategories.where((String c) => c != category).toList(),
    );
  }

  /// إضافة مورد
  ReportFilter addSupplier(String supplier) {
    final List<String> currentSuppliers = suppliers ?? <String>[];
    if (currentSuppliers.contains(supplier)) return this;
    return copyWith(suppliers: <String>[...currentSuppliers, supplier]);
  }

  /// إزالة مورد
  ReportFilter removeSupplier(String supplier) {
    final List<String> currentSuppliers = suppliers ?? <String>[];
    if (!currentSuppliers.contains(supplier)) return this;
    return copyWith(
      suppliers: currentSuppliers.where((String s) => s != supplier).toList(),
    );
  }
}
