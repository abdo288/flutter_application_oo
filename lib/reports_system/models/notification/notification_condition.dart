import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_enums.dart';

part 'notification_condition.freezed.dart';
part 'notification_condition.g.dart';

/// شرط الإشعار
@freezed
class NotificationCondition with _$NotificationCondition {
  const factory NotificationCondition({
    required String field,
    required ConditionOperator operator,
    required value,
    required bool isActive,
  }) = _NotificationCondition;

  factory NotificationCondition.fromJson(Map<String, dynamic> json) =>
      _$NotificationConditionFromJson(json);
}

/// Extensions for computed properties
extension NotificationConditionX on NotificationCondition {
  /// التحقق من تطابق الشرط
  bool matches(actualValue) {
    if (!isActive) return false;

    switch (operator) {
      case ConditionOperator.equals:
        return actualValue == value;
      case ConditionOperator.notEquals:
        return actualValue != value;
      case ConditionOperator.greaterThan:
        return (actualValue as num) > (value as num);
      case ConditionOperator.lessThan:
        return (actualValue as num) < (value as num);
      case ConditionOperator.greaterThanOrEqual:
        return (actualValue as num) >= (value as num);
      case ConditionOperator.lessThanOrEqual:
        return (actualValue as num) <= (value as num);
      case ConditionOperator.contains:
        return (actualValue as String).contains(value as String);
      case ConditionOperator.notContains:
        return !(actualValue as String).contains(value as String);
      case ConditionOperator.startsWith:
        return (actualValue as String).startsWith(value as String);
      case ConditionOperator.endsWith:
        return (actualValue as String).endsWith(value as String);
      case ConditionOperator.isEmpty:
        return actualValue == null || actualValue.toString().isEmpty;
      case ConditionOperator.isNotEmpty:
        return actualValue != null && actualValue.toString().isNotEmpty;
      case ConditionOperator.inList:
        return (value as List).contains(actualValue);
      case ConditionOperator.notInList:
        return !(value as List).contains(actualValue);
    }
  }
}
