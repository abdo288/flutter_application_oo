import 'package:flutter/foundation.dart';

/// إعدادات تنبيهات المخزون
class AlertSettings {
  // عدد الأيام قبل الانتهاء للتنبيه

  AlertSettings({
    this.lowStockThreshold = 10,
    this.enableOutOfStockAlert = true,
    this.enableLowStockAlert = true,
    this.enableExpiringAlert = false,
    this.expiringDaysThreshold = 7,
  });

  factory AlertSettings.fromMap(Map<String, dynamic> map) {
    try {
      return AlertSettings(
        lowStockThreshold: _parseInt(map['lowStockThreshold']) ?? 10,
        enableOutOfStockAlert: map['enableOutOfStockAlert'] == true,
        enableLowStockAlert: map['enableLowStockAlert'] == true,
        enableExpiringAlert: map['enableExpiringAlert'] == true,
        expiringDaysThreshold: _parseInt(map['expiringDaysThreshold']) ?? 7,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء إعدادات التنبيهات من Map: $e');
      return AlertSettings(); // إرجاع الإعدادات الافتراضية
    }
  }
  int lowStockThreshold; // الحد الأدنى للتنبيه
  bool enableOutOfStockAlert; // تفعيل تنبيه نفاد الكمية
  bool enableLowStockAlert; // تفعيل تنبيه الحد الأدنى
  bool enableExpiringAlert; // تفعيل تنبيه قرب الانتهاء
  int expiringDaysThreshold;

  /// التحقق من صحة الإعدادات
  bool isValid() =>
      lowStockThreshold >= 0 &&
      lowStockThreshold <= 1000 && // حد أقصى منطقي
      expiringDaysThreshold >= 0 &&
      expiringDaysThreshold <= 365; // حد أقصى سنة

  /// التحقق من وجود تنبيهات مفعلة
  bool hasEnabledAlerts() =>
      enableOutOfStockAlert || enableLowStockAlert || enableExpiringAlert;

  /// الحصول على رسالة خطأ التحقق
  String? getValidationError() {
    if (lowStockThreshold < 0) {
      return 'الحد الأدنى للتنبيه يجب أن يكون أكبر من أو يساوي صفر';
    }
    if (lowStockThreshold > 1000) {
      return 'الحد الأدنى للتنبيه يجب أن يكون أقل من أو يساوي 1000';
    }
    if (expiringDaysThreshold < 0) {
      return 'أيام الانتهاء يجب أن تكون أكبر من أو تساوي صفر';
    }
    if (expiringDaysThreshold > 365) {
      return 'أيام الانتهاء يجب أن تكون أقل من أو تساوي 365';
    }
    if (!hasEnabledAlerts()) {
      return 'يجب تفعيل نوع واحد على الأقل من التنبيهات';
    }
    return null;
  }

  /// إنشاء نسخة من الإعدادات مع تحديث القيم المحددة
  AlertSettings copyWith({
    int? lowStockThreshold,
    bool? enableOutOfStockAlert,
    bool? enableLowStockAlert,
    bool? enableExpiringAlert,
    int? expiringDaysThreshold,
  }) =>
      AlertSettings(
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        enableOutOfStockAlert:
            enableOutOfStockAlert ?? this.enableOutOfStockAlert,
        enableLowStockAlert: enableLowStockAlert ?? this.enableLowStockAlert,
        enableExpiringAlert: enableExpiringAlert ?? this.enableExpiringAlert,
        expiringDaysThreshold:
            expiringDaysThreshold ?? this.expiringDaysThreshold,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'lowStockThreshold': lowStockThreshold,
        'enableOutOfStockAlert': enableOutOfStockAlert,
        'enableLowStockAlert': enableLowStockAlert,
        'enableExpiringAlert': enableExpiringAlert,
        'expiringDaysThreshold': expiringDaysThreshold,
      };

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  String toString() => 'AlertSettings{lowStockThreshold: $lowStockThreshold, '
      'enableOutOfStockAlert: $enableOutOfStockAlert, '
      'enableLowStockAlert: $enableLowStockAlert, '
      'enableExpiringAlert: $enableExpiringAlert, '
      'expiringDaysThreshold: $expiringDaysThreshold}';
}
