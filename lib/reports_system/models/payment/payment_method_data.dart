import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/payment_enums.dart';

part 'payment_method_data.freezed.dart';
part 'payment_method_data.g.dart';

/// بيانات طريقة الدفع
@freezed
class PaymentMethodData with _$PaymentMethodData {
  const factory PaymentMethodData({
    required PaymentMethod method,
    required double amount,
    required int transactionCount,
    required double percentage,
    required double averageValue,
    required double growthRate,
  }) = _PaymentMethodData;

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodDataFromJson(json);
}
