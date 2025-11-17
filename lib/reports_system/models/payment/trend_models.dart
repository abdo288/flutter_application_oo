import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trend_models.freezed.dart';
part 'trend_models.g.dart';

/// اتجاه المدفوعات اليومية
@freezed
class DailyPaymentTrend with _$DailyPaymentTrend {
  const factory DailyPaymentTrend({
    required DateTime date,
    required double totalAmount,
    required double cashAmount,
    required double cardAmount,
    required double otherAmount,
  }) = _DailyPaymentTrend;

  factory DailyPaymentTrend.fromJson(Map<String, dynamic> json) =>
      _$DailyPaymentTrendFromJson(json);
}

/// اتجاه المدفوعات الأسبوعية
@freezed
class WeeklyPaymentTrend with _$WeeklyPaymentTrend {
  const factory WeeklyPaymentTrend({
    required DateTime weekStart,
    required DateTime weekEnd,
    required double totalAmount,
    required double averageDailyAmount,
  }) = _WeeklyPaymentTrend;

  factory WeeklyPaymentTrend.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPaymentTrendFromJson(json);
}

/// اتجاه المدفوعات الشهرية
@freezed
class MonthlyPaymentTrend with _$MonthlyPaymentTrend {
  const factory MonthlyPaymentTrend({
    required int month,
    required int year,
    required double totalAmount,
    required double averageDailyAmount,
  }) = _MonthlyPaymentTrend;

  factory MonthlyPaymentTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyPaymentTrendFromJson(json);
}
