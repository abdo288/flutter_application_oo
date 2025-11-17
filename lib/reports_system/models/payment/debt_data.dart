import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/payment_enums.dart';

part 'debt_data.freezed.dart';
part 'debt_data.g.dart';

/// بيانات الديون
@freezed
class DebtData with _$DebtData {
  const factory DebtData({
    required String id,
    required String customerId,
    required String customerName,
    required double amount,
    required double originalAmount,
    required DateTime date,
    required DateTime dueDate,
    required DebtStatus status,
    required String notes,
  }) = _DebtData;

  factory DebtData.fromJson(Map<String, dynamic> json) =>
      _$DebtDataFromJson(json);
}

/// Extensions for computed properties
extension DebtDataX on DebtData {
  /// حساب المبلغ المدفوع
  double get paidAmount => originalAmount - amount;

  /// حساب نسبة السداد
  double get paymentPercentage {
    if (originalAmount == 0) return 0.0;
    return (paidAmount / originalAmount) * 100;
  }

  /// التحقق من انتهاء مدة السداد
  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != DebtStatus.paid;
}
