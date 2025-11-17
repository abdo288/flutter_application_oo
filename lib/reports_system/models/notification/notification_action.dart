import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_enums.dart';

part 'notification_action.freezed.dart';
part 'notification_action.g.dart';

/// إجراء الإشعار
@freezed
class NotificationAction with _$NotificationAction {
  const factory NotificationAction({
    required ActionType type,
    required Map<String, dynamic> config,
    required bool enabled,
  }) = _NotificationAction;

  factory NotificationAction.fromJson(Map<String, dynamic> json) =>
      _$NotificationActionFromJson(json);
}
