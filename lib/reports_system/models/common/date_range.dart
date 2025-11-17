import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range.freezed.dart';
part 'date_range.g.dart';

/// نطاق التاريخ
@freezed
class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRange;

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);
}

/// Extensions for computed properties
extension DateRangeX on DateRange {
  /// حساب عدد الأيام
  int get daysCount => endDate.difference(startDate).inDays + 1;

  /// التحقق من صحة النطاق
  bool get isValid => endDate.isAfter(startDate) || endDate.isAtSameMomentAs(startDate);
}
