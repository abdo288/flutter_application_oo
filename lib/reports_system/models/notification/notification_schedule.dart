import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/json_converters.dart';

part 'notification_schedule.freezed.dart';
part 'notification_schedule.g.dart';

/// جدولة الإشعار
@freezed
class NotificationSchedule with _$NotificationSchedule {
  const factory NotificationSchedule({
    @TimeOfDayConverter() TimeOfDay? startTime,
    @TimeOfDayConverter() TimeOfDay? endTime,
    @Default(<dynamic>[]) List<int> daysOfWeek, // 1-7 (Monday-Sunday)
    @Default(<dynamic>[]) List<int> daysOfMonth, // 1-31
    @Default(<dynamic>[]) List<int> months, // 1-12
    @Default('UTC') String timezone,
    @DurationNullableConverter() Duration? repeatInterval,
    int? repeatCount,
  }) = _NotificationSchedule;

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) =>
      _$NotificationScheduleFromJson(json);
}

/// Extensions for computed properties
extension NotificationScheduleX on NotificationSchedule {
  /// التحقق من نشاط الجدولة
  bool get isActive {
    final DateTime now = DateTime.now();
    final int currentDayOfWeek = now.weekday;
    final int currentDayOfMonth = now.day;
    final int currentMonth = now.month;
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

    // التحقق من اليوم
    if (daysOfWeek.isNotEmpty && !daysOfWeek.contains(currentDayOfWeek)) {
      return false;
    }

    // التحقق من اليوم من الشهر
    if (daysOfMonth.isNotEmpty && !daysOfMonth.contains(currentDayOfMonth)) {
      return false;
    }

    // التحقق من الشهر
    if (months.isNotEmpty && !months.contains(currentMonth)) {
      return false;
    }

    // التحقق من الوقت
    if (startTime != null && endTime != null) {
      return _isTimeInRange(currentTime, startTime!, endTime!);
    }

    return true;
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final int currentMinutes = current.hour * 60 + current.minute;
    final int startMinutes = start.hour * 60 + start.minute;
    final int endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // يتجاوز منتصف الليل
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}
