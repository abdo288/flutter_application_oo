import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/payment_enums.dart';
import 'trend_models.dart';

part 'payment_trends.freezed.dart';
part 'payment_trends.g.dart';

/// اتجاهات المدفوعات
@freezed
class PaymentTrends with _$PaymentTrends {
  const factory PaymentTrends({
    required List<DailyPaymentTrend> dailyTrends,
    required List<WeeklyPaymentTrend> weeklyTrends,
    required List<MonthlyPaymentTrend> monthlyTrends,
    required PaymentMethodTrend cashTrend,
    required PaymentMethodTrend cardTrend,
    required PaymentMethodTrend otherTrends,
  }) = _PaymentTrends;

  factory PaymentTrends.fromJson(Map<String, dynamic> json) =>
      _$PaymentTrendsFromJson(json);
}

/// اتجاه طريقة الدفع
@freezed
class PaymentMethodTrend with _$PaymentMethodTrend {
  const factory PaymentMethodTrend({
    required PaymentMethod method,
    required double growthRate,
    required double volatility,
    required double peakValue,
    required DateTime peakDate,
  }) = _PaymentMethodTrend;

  factory PaymentMethodTrend.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodTrendFromJson(json);
}
