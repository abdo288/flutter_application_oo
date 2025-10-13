import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// أنواع تنبيهات المخزون
enum AlertType {
  outOfStock, // نفاد الكمية
  lowStock, // وصول للحد الأدنى
  expiringSoon, // قارب على الانتهاء
}

/// نموذج تنبيه المخزون
class InventoryAlert {
  InventoryAlert({
    this.id,
    required this.productName,
    required this.alertType,
    required this.currentQuantity,
    this.threshold,
    required this.alertDate,
    this.isRead = false,
    this.description,
  });

  factory InventoryAlert.fromMap(Map<String, dynamic> map) {
    try {
      return InventoryAlert(
        id: map['id']?.toString(),
        productName: map['productName']?.toString() ?? '',
        alertType: _parseAlertType(map['alertType']),
        currentQuantity: _parseInt(map['currentQuantity']) ?? 0,
        threshold:
            map['threshold'] != null ? _parseInt(map['threshold']) : null,
        alertDate: _parseDateTime(map['alertDate']),
        isRead: map['isRead'] == true,
        description: map['description']?.toString(),
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء تنبيه المخزون من Map: $e');
      rethrow;
    }
  }
  String? id;
  String productName;
  AlertType alertType;
  int currentQuantity;
  int? threshold; // الحد الأدنى للتنبيه
  DateTime alertDate;
  bool isRead;
  String? description;

  /// الحصول على نص التنبيه
  String get alertMessage {
    switch (alertType) {
      case AlertType.outOfStock:
        return 'نفدت كمية المنتج "$productName"';
      case AlertType.lowStock:
        return 'وصلت كمية المنتج "$productName" للحد الأدنى ($currentQuantity وحدة)';
      case AlertType.expiringSoon:
        return 'المنتج "$productName" قارب على الانتهاء';
    }
  }

  /// الحصول على لون التنبيه
  String get alertColor {
    switch (alertType) {
      case AlertType.outOfStock:
        return '#FF5252'; // أحمر
      case AlertType.lowStock:
        return '#FF9800'; // برتقالي
      case AlertType.expiringSoon:
        return '#FFC107'; // أصفر
    }
  }

  /// الحصول على أيقونة التنبيه
  String get alertIcon {
    switch (alertType) {
      case AlertType.outOfStock:
        return '⚠️';
      case AlertType.lowStock:
        return '📉';
      case AlertType.expiringSoon:
        return '⏰';
    }
  }

  /// التحقق من صحة بيانات التنبيه
  bool isValid() => productName.isNotEmpty && currentQuantity >= 0;

  /// إنشاء نسخة من التنبيه مع تحديث القيم المحددة
  InventoryAlert copyWith({
    String? id,
    String? productName,
    AlertType? alertType,
    int? currentQuantity,
    int? threshold,
    DateTime? alertDate,
    bool? isRead,
    String? description,
  }) =>
      InventoryAlert(
        id: id ?? this.id,
        productName: productName ?? this.productName,
        alertType: alertType ?? this.alertType,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        threshold: threshold ?? this.threshold,
        alertDate: alertDate ?? this.alertDate,
        isRead: isRead ?? this.isRead,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'productName': productName.trim(),
        'alertType': alertType.name,
        'currentQuantity': currentQuantity,
        'threshold': threshold,
        'alertDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(alertDate),
        'isRead': isRead,
        'description': description,
      };

  static AlertType _parseAlertType(Object? value) {
    if (value is String) {
      switch (value) {
        case 'outOfStock':
          return AlertType.outOfStock;
        case 'lowStock':
          return AlertType.lowStock;
        case 'expiringSoon':
          return AlertType.expiringSoon;
        default:
          return AlertType.lowStock;
      }
    }
    return AlertType.lowStock;
  }

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      try {
        // محاولة تحليل تنسيقات مختلفة
        if (value.contains('T') && value.contains('Z')) {
          // تنسيق ISO 8601 مع Z
          return DateTime.parse(value);
        } else if (value.contains('T')) {
          // تنسيق ISO 8601 بدون Z
          return DateTime.parse(value);
        } else {
          // تنسيق مخصص
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
        }
      } on Exception catch (e) {
        debugPrint('خطأ في تحليل التاريخ والوقت: $e');
      }
    }
    return DateTime.now();
  }

  @override
  String toString() =>
      'InventoryAlert{id: $id, productName: $productName, alertType: $alertType, currentQuantity: $currentQuantity}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InventoryAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
