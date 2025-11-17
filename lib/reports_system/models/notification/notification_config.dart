import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_enums.dart';
import 'notification_action.dart';
import 'notification_condition.dart';
import 'notification_schedule.dart';

part 'notification_config.freezed.dart';
part 'notification_config.g.dart';

/// نموذج إعدادات الإشعارات
@freezed
class NotificationConfig with _$NotificationConfig {
  const factory NotificationConfig({
    required String id,
    required String name,
    String? description,
    required NotificationType type,
    required bool enabled,
    required List<NotificationCondition> conditions,
    required List<NotificationAction> actions,
    @Default(NotificationPriority.medium) NotificationPriority priority,
    NotificationSchedule? schedule,
    @Default(<dynamic>[]) List<String> recipients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _NotificationConfig;

  factory NotificationConfig.fromJson(Map<String, dynamic> json) =>
      _$NotificationConfigFromJson(json);
}

/// Extensions for computed properties
extension NotificationConfigX on NotificationConfig {
  /// التحقق من صحة الإعدادات
  bool get isValid => name.isNotEmpty &&
        type != NotificationType.unknown &&
        conditions.isNotEmpty &&
        actions.isNotEmpty;

  /// التحقق من تفعيل الإشعار
  bool get isActive => enabled &&
        (schedule?.isActive ?? true) &&
        conditions.any((NotificationCondition condition) => condition.isActive);
}
