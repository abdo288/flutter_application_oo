import 'package:flutter/material.dart';

/// نموذج إعدادات الإشعارات
class NotificationConfig {
  const NotificationConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    required this.conditions,
    required this.actions,
    this.description,
    this.priority = NotificationPriority.medium,
    this.schedule,
    this.recipients = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationConfig.fromMap(Map<String, dynamic> map) =>
      NotificationConfig(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        description: map['description'] as String?,
        type: NotificationType.values.firstWhere(
          (NotificationType e) => e.name == map['type'],
          orElse: () => NotificationType.info,
        ),
        enabled: (map['enabled'] as bool?) ?? false,
        conditions: List<NotificationCondition>.from(
          (map['conditions'] as List<dynamic>?)?.map((x) =>
                  NotificationCondition.fromMap(x as Map<String, dynamic>)) ??
              <dynamic>[],
        ),
        actions: List<NotificationAction>.from(
          (map['actions'] as List<dynamic>?)?.map((x) =>
                  NotificationAction.fromMap(x as Map<String, dynamic>)) ??
              <dynamic>[],
        ),
        priority: NotificationPriority.values.firstWhere(
          (NotificationPriority e) => e.name == map['priority'],
          orElse: () => NotificationPriority.medium,
        ),
        schedule: map['schedule'] != null
            ? NotificationSchedule.fromMap(
                map['schedule'] as Map<String, dynamic>)
            : null,
        recipients: (map['recipients'] as List<dynamic>?)?.cast<String>() ?? <String>[],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );

  final String id;
  final String name;
  final String? description;
  final NotificationType type;
  final bool enabled;
  final List<NotificationCondition> conditions;
  final List<NotificationAction> actions;
  final NotificationPriority priority;
  final NotificationSchedule? schedule;
  final List<String> recipients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// التحقق من صحة الإعدادات
  bool get isValid =>
      name.isNotEmpty &&
      type != NotificationType.unknown &&
      conditions.isNotEmpty &&
      actions.isNotEmpty;

  /// التحقق من تفعيل الإشعار
  bool get isActive =>
      enabled &&
      (schedule?.isActive ?? true) &&
      conditions.any((NotificationCondition condition) => condition.isActive);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'enabled': enabled,
        'conditions':
            conditions.map((NotificationCondition x) => x.toMap()).toList(),
        'actions': actions.map((NotificationAction x) => x.toMap()).toList(),
        'priority': priority.name,
        'schedule': schedule?.toMap(),
        'recipients': recipients,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

/// شرط الإشعار
class NotificationCondition {
  const NotificationCondition({
    required this.field,
    required this.operator,
    required this.value,
    required this.isActive,
  });

  factory NotificationCondition.fromMap(Map<String, dynamic> map) =>
      NotificationCondition(
        field: (map['field'] as String?) ?? '',
        operator: ConditionOperator.values.firstWhere(
          (ConditionOperator e) => e.name == map['operator'],
          orElse: () => ConditionOperator.equals,
        ),
        value: map['value'],
        isActive: (map['isActive'] as bool?) ?? false,
      );

  final String field;
  final ConditionOperator operator;
  final dynamic value;
  final bool isActive;

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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'field': field,
        'operator': operator.name,
        'value': value,
        'isActive': isActive,
      };
}

/// إجراء الإشعار
class NotificationAction {
  const NotificationAction({
    required this.type,
    required this.config,
    required this.enabled,
  });

  factory NotificationAction.fromMap(Map<String, dynamic> map) =>
      NotificationAction(
        type: ActionType.values.firstWhere(
          (ActionType e) => e.name == map['type'],
          orElse: () => ActionType.showSnackbar,
        ),
        config: (map['config'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        enabled: (map['enabled'] as bool?) ?? false,
      );

  final ActionType type;
  final Map<String, dynamic> config;
  final bool enabled;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type.name,
        'config': config,
        'enabled': enabled,
      };
}

/// جدولة الإشعار
class NotificationSchedule {
  const NotificationSchedule({
    this.startTime,
    this.endTime,
    this.daysOfWeek = const <int>[],
    this.daysOfMonth = const <int>[],
    this.months = const <int>[],
    this.timezone = 'UTC',
    this.repeatInterval,
    this.repeatCount,
  });

  factory NotificationSchedule.fromMap(Map<String, dynamic> map) =>
      NotificationSchedule(
        startTime: map['startTime'] != null
            ? TimeOfDaySerialization.fromMap(
                map['startTime'] as Map<String, dynamic>)
            : null,
        endTime: map['endTime'] != null
            ? TimeOfDaySerialization.fromMap(
                map['endTime'] as Map<String, dynamic>)
            : null,
        daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? <int>[],
        daysOfMonth: (map['daysOfMonth'] as List<dynamic>?)?.cast<int>() ?? <int>[],
        months: (map['months'] as List<dynamic>?)?.cast<int>() ?? <int>[],
        timezone: (map['timezone'] as String?) ?? 'UTC',
        repeatInterval: map['repeatInterval'] != null
            ? Duration(milliseconds: map['repeatInterval'] as int)
            : null,
        repeatCount: map['repeatCount'] as int?,
      );

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)
  final List<int> daysOfMonth; // 1-31
  final List<int> months; // 1-12
  final String timezone;
  final Duration? repeatInterval;
  final int? repeatCount;

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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'startTime': startTime?.toMap(),
        'endTime': endTime?.toMap(),
        'daysOfWeek': daysOfWeek,
        'daysOfMonth': daysOfMonth,
        'months': months,
        'timezone': timezone,
        'repeatInterval': repeatInterval?.inMilliseconds,
        'repeatCount': repeatCount,
      };
}

// TimeOfDay extensions for serialization
extension TimeOfDaySerialization on TimeOfDay {
  Map<String, dynamic> toMap() => <String, dynamic>{
        'hour': hour,
        'minute': minute,
      };

  static TimeOfDay fromMap(Map<String, dynamic> map) => TimeOfDay(
        hour: (map['hour'] as int?) ?? 0,
        minute: (map['minute'] as int?) ?? 0,
      );
}

/// نوع الإشعار
enum NotificationType {
  info,
  warning,
  error,
  success,
  lowStock,
  eodReminder,
  syncStatus,
  achievement,
  unknown,
}

/// أولوية الإشعار
enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

/// مشغل الشرط
enum ConditionOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  contains,
  notContains,
  startsWith,
  endsWith,
  isEmpty,
  isNotEmpty,
  inList,
  notInList,
}

/// نوع الإجراء
enum ActionType {
  showSnackbar,
  showDialog,
  showNotification,
  sendEmail,
  sendSms,
  playSound,
  vibrate,
  logEvent,
  triggerAction,
}

/// إعدادات الإشعارات المسبقة
class NotificationPresets {
  static const NotificationConfig lowStockAlert = NotificationConfig(
    id: 'low_stock_alert',
    name: 'تنبيه المخزون المنخفض',
    description: 'إشعار عند انخفاض مخزون المنتجات',
    type: NotificationType.lowStock,
    enabled: true,
    conditions: <NotificationCondition>[
      NotificationCondition(
        field: 'currentStock',
        operator: ConditionOperator.lessThanOrEqual,
        value: 10,
        isActive: true,
      ),
    ],
    actions: <NotificationAction>[
      NotificationAction(
        type: ActionType.showNotification,
        config: <String, dynamic>{
          'title': 'تنبيه المخزون',
          'message': 'منتج بمخزون منخفض',
        },
        enabled: true,
      ),
    ],
    priority: NotificationPriority.high,
  );

  static const NotificationConfig eodReminder = NotificationConfig(
    id: 'eod_reminder',
    name: 'تذكير إنهاء اليوم',
    description: 'تذكير بإنهاء يوم العمل',
    type: NotificationType.eodReminder,
    enabled: true,
    conditions: <NotificationCondition>[
      NotificationCondition(
        field: 'currentTime',
        operator: ConditionOperator.equals,
        value: '18:00',
        isActive: true,
      ),
    ],
    actions: <NotificationAction>[
      NotificationAction(
        type: ActionType.showDialog,
        config: <String, dynamic>{
          'title': 'تذكير إنهاء اليوم',
          'message': 'حان وقت إنهاء يوم العمل',
        },
        enabled: true,
      ),
    ],
  );

  static const NotificationConfig syncStatus = NotificationConfig(
    id: 'sync_status',
    name: 'حالة المزامنة',
    description: 'إشعار عند فشل المزامنة',
    type: NotificationType.syncStatus,
    enabled: true,
    conditions: <NotificationCondition>[
      NotificationCondition(
        field: 'syncStatus',
        operator: ConditionOperator.equals,
        value: 'failed',
        isActive: true,
      ),
    ],
    actions: <NotificationAction>[
      NotificationAction(
        type: ActionType.showSnackbar,
        config: <String, dynamic>{
          'message': 'فشل في المزامنة مع الخادم',
          'duration': 5000,
        },
        enabled: true,
      ),
    ],
    priority: NotificationPriority.high,
  );

  static const List<NotificationConfig> allPresets = <NotificationConfig>[
    lowStockAlert,
    eodReminder,
    syncStatus,
  ];
}
