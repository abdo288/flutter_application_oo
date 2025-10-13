import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// نموذج عنصر الجرد السريع
class QuickInventoryItem {
  QuickInventoryItem({
    this.id,
    required this.barcode,
    required this.name,
    required this.scannedQuantity,
    required this.scanDate,
    this.originalQuantity,
    this.wholesalePrice,
    this.retailPrice,
    this.isNewProduct = false,
    this.notes,
  });

  factory QuickInventoryItem.fromMap(Map<String, dynamic> map) {
    try {
      return QuickInventoryItem(
        id: map['id']?.toString(),
        barcode: map['barcode']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        scannedQuantity: (map['scannedQuantity'] as int?) ?? 0,
        scanDate: map['scanDate'] is DateTime
            ? map['scanDate'] as DateTime
            : _parseDate(map['scanDate']),
        originalQuantity: map['originalQuantity'] as int?,
        wholesalePrice: map['wholesalePrice'] as int?,
        retailPrice: map['retailPrice'] as int?,
        isNewProduct: (map['isNewProduct'] as bool?) ?? false,
        notes: map['notes'] as String?,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء عنصر الجرد السريع من Map: $e');
      rethrow;
    }
  }

  String? id;
  String barcode;
  String name;
  int scannedQuantity;
  DateTime scanDate;
  int? originalQuantity;
  int? wholesalePrice;
  int? retailPrice;
  bool isNewProduct;
  String? notes;

  /// حساب الفرق بين الكمية الممسوحة والكمية الأصلية
  int get quantityDifference => originalQuantity != null
      ? scannedQuantity - originalQuantity!
      : scannedQuantity;

  /// التحقق من وجود اختلاف في الكمية
  bool get hasQuantityDifference =>
      originalQuantity != null && quantityDifference != 0;

  /// التحقق من صحة بيانات عنصر الجرد
  bool isValid() =>
      barcode.isNotEmpty && name.isNotEmpty && scannedQuantity >= 0;

  /// الحصول على نص حالة الكمية
  String getQuantityStatusText() {
    if (originalQuantity == null) {
      return 'منتج جديد';
    }

    if (quantityDifference > 0) {
      return 'زيادة: +$quantityDifference';
    } else if (quantityDifference < 0) {
      return 'نقص: $quantityDifference';
    } else {
      return 'متطابق';
    }
  }

  /// الحصول على لون حالة الكمية
  Color getQuantityStatusColor() {
    if (originalQuantity == null) {
      return Colors.blue;
    }

    if (quantityDifference > 0) {
      return Colors.green;
    } else if (quantityDifference < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'barcode': barcode,
        'name': name,
        'scannedQuantity': scannedQuantity,
        'scanDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(scanDate),
        'originalQuantity': originalQuantity,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'isNewProduct': isNewProduct,
        'notes': notes,
      };

  /// تحليل التاريخ
  static DateTime _parseDate(Object? date) {
    try {
      if (date is DateTime) {
        return date;
      } else if (date is String) {
        if (date.contains('T') && date.contains('Z')) {
          return DateTime.parse(date);
        } else {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(date, true);
        }
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تحليل تاريخ الجرد: $e');
    }
    return DateTime.now();
  }

  /// إنشاء نسخة من عنصر الجرد مع تحديث القيم المحددة
  QuickInventoryItem copyWith({
    String? id,
    String? barcode,
    String? name,
    int? scannedQuantity,
    DateTime? scanDate,
    int? originalQuantity,
    int? wholesalePrice,
    int? retailPrice,
    bool? isNewProduct,
    String? notes,
  }) =>
      QuickInventoryItem(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        scannedQuantity: scannedQuantity ?? this.scannedQuantity,
        scanDate: scanDate ?? this.scanDate,
        originalQuantity: originalQuantity ?? this.originalQuantity,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        isNewProduct: isNewProduct ?? this.isNewProduct,
        notes: notes ?? this.notes,
      );

  @override
  String toString() =>
      'QuickInventoryItem{barcode: $barcode, name: $name, scannedQuantity: $scannedQuantity}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickInventoryItem && other.barcode == barcode;
  }

  @override
  int get hashCode => barcode.hashCode;
}
