import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/payment_enums.dart';
import 'debt_data.dart';
import 'payment_method_data.dart';
import 'payment_trends.dart';
import 'refund_data.dart';

part 'payment_report.freezed.dart';
part 'payment_report.g.dart';

/// نموذج تقرير المدفوعات
@freezed
class PaymentReport with _$PaymentReport {
  const factory PaymentReport({
    required List<PaymentMethodData> paymentMethods,
    required List<RefundData> refunds,
    required List<DebtData> debts,
    required PaymentTrends paymentTrends,
    required ReportPeriod period,
    required double totalAmount,
    required int totalTransactions,
  }) = _PaymentReport;

  factory PaymentReport.fromJson(Map<String, dynamic> json) =>
      _$PaymentReportFromJson(json);
}

/// فترة التقرير
@freezed
class ReportPeriod with _$ReportPeriod {
  const factory ReportPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required PeriodType type,
  }) = _ReportPeriod;

  factory ReportPeriod.fromJson(Map<String, dynamic> json) =>
      _$ReportPeriodFromJson(json);
}

/// Extensions for computed properties
extension PaymentReportX on PaymentReport {
  /// حساب إجمالي المبالغ المستردة
  double get totalRefunds => refunds.fold(0.0, (double sum, RefundData refund) => sum + refund.amount);

  /// حساب إجمالي الديون
  double get totalDebts => debts.fold(0.0, (double sum, DebtData debt) => sum + debt.amount);

  /// حساب صافي المدفوعات
  double get netPayments => totalAmount - totalRefunds;

  /// حساب نسبة المبالغ المستردة
  double get refundPercentage {
    if (totalAmount == 0) return 0.0;
    return (totalRefunds / totalAmount) * 100;
  }

  /// حساب نسبة الديون
  double get debtPercentage {
    if (totalAmount == 0) return 0.0;
    return (totalDebts / totalAmount) * 100;
  }
}

extension ReportPeriodX on ReportPeriod {
  /// حساب عدد الأيام
  int get daysCount => endDate.difference(startDate).inDays + 1;
}
