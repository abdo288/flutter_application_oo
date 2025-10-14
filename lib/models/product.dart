import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// أنواع حالة المنتج
enum ProductStatus {
  active, // نشط
  inactive, // غير نشط
  discontinued, // متوقف
  outOfStock, // نفدت الكمية
}

/// نموذج المنتج المحسن مع معالجة شاملة للبيانات
class Product {
  Product({
    this.id,
    required this.name,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.savedAt,
    this.lastModified,
    this.description,
    this.barcode,
    this.category,
    this.supplier,
    this.status = ProductStatus.active,
    this.images,
    this.tags,
    this.weight,
    this.dimensions,
    this.minimumStock,
    this.maximumStock,
    this.taxRate,
    this.discountRate,
    this.isActive = true,
    this.notes,
    this.isSynced,
  });

  // تم نقل دوال fromFirestore و fromMap إلى DataConversionService
  // لمركزية تحويل البيانات
  String? id;
  String name;
  int wholesalePrice;
  int retailPrice;
  DateTime savedAt;
  DateTime? lastModified;

  // حقول جديدة محسنة
  String? description; // وصف المنتج
  String? barcode; // الباركود
  String? category; // فئة المنتج
  String? supplier; // المورد
  ProductStatus status; // حالة المنتج
  List<String>? images; // صور المنتج
  List<String>? tags; // علامات المنتج
  double? weight; // الوزن (بالكيلو)
  String? dimensions; // الأبعاد (الطول × العرض × الارتفاع)
  int? minimumStock; // الحد الأدنى للمخزون
  int? maximumStock; // الحد الأقصى للمخزون
  double? taxRate; // نسبة الضريبة
  double? discountRate; // نسبة الخصم
  bool isActive; // حالة النشاط
  String? notes; // ملاحظات إضافية
  bool? isSynced; // حالة المزامنة مع Firebase

  /// حساب الربح مع التحقق من صحة البيانات
  int calculateProfit() {
    if (wholesalePrice < 0 || retailPrice < 0) {
      throw ArgumentError('الأسعار لا يمكن أن تكون سالبة');
    }
    return retailPrice - wholesalePrice;
  }

  /// حساب نسبة الربح
  double calculateProfitPercentage() {
    if (wholesalePrice == 0) {
      return 0.0;
    }
    if (retailPrice == wholesalePrice) {
      return 0.0;
    }
    return ((retailPrice - wholesalePrice) / wholesalePrice) * 100;
  }

  /// حساب السعر مع الضريبة
  int calculatePriceWithTax() {
    if (taxRate == null || taxRate == 0) {
      return retailPrice;
    }
    return (retailPrice * (1 + taxRate! / 100)).round();
  }

  /// حساب السعر مع الخصم
  int calculateDiscountedPrice() {
    if (discountRate == null || discountRate == 0) {
      return retailPrice;
    }
    return (retailPrice * (1 - discountRate! / 100)).round();
  }

  /// حساب السعر النهائي (مع الضريبة والخصم)
  int calculateFinalPrice() {
    final int discountedPrice = calculateDiscountedPrice();
    if (taxRate == null || taxRate == 0) {
      return discountedPrice;
    }
    return (discountedPrice * (1 + taxRate! / 100)).round();
  }

  /// التحقق من صحة بيانات المنتج
  bool isValid() => name.isNotEmpty && wholesalePrice >= 0 && retailPrice >= 0;

  /// التحقق من صحة البيانات الشاملة
  bool isValidComplete() =>
      isValid() &&
      (description?.isNotEmpty ?? true) &&
      (category?.isNotEmpty ?? true) &&
      (supplier?.isNotEmpty ?? true) &&
      (weight == null || weight! >= 0) &&
      (minimumStock == null || minimumStock! >= 0) &&
      (maximumStock == null || maximumStock! >= minimumStock!) &&
      (taxRate == null || (taxRate! >= 0 && taxRate! <= 100)) &&
      (discountRate == null || (discountRate! >= 0 && discountRate! <= 100));

  /// الحصول على حالة المنتج كنص
  String getStatusText() {
    switch (status) {
      case ProductStatus.active:
        return 'نشط';
      case ProductStatus.inactive:
        return 'غير نشط';
      case ProductStatus.discontinued:
        return 'متوقف';
      case ProductStatus.outOfStock:
        return 'نفدت الكمية';
    }
  }

  /// الحصول على لون حالة المنتج
  Color getStatusColor() {
    switch (status) {
      case ProductStatus.active:
        return Colors.green;
      case ProductStatus.inactive:
        return Colors.orange;
      case ProductStatus.discontinued:
        return Colors.red;
      case ProductStatus.outOfStock:
        return Colors.red.shade700;
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name.trim(),
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'savedAt': DateFormat('yyyy-MM-dd HH:mm:ss').format(savedAt),
        'description': description,
        'barcode': barcode,
        'category': category,
        'supplier': supplier,
        'status': status.name,
        'images': images,
        'tags': tags,
        'weight': weight,
        'dimensions': dimensions,
        'minimumStock': minimumStock,
        'maximumStock': maximumStock,
        'taxRate': taxRate,
        'discountRate': discountRate,
        'isActive': isActive,
        'notes': notes,
        'isSynced': isSynced,
        'lastModified': lastModified?.toIso8601String(),
      };

  /// تحليل التاريخ مع معالجة أفضل للأخطاء
  static DateTime parseSavedAt(Object? savedAt) {
    try {
      if (savedAt is Timestamp) {
        return savedAt.toDate();
      } else if (savedAt is String) {
        // محاولة تحليل تنسيقات مختلفة
        if (savedAt.contains('T')) {
          // ISO 8601 بدون الحاجة لوجود Z
          return DateTime.parse(savedAt);
        }
        // التحقق من تنسيق الوقت فقط (HH:mm:ss)
        if (savedAt.contains(':') &&
            !savedAt.contains('-') &&
            !savedAt.contains(' ')) {
          // تنسيق وقت فقط - إنشاء DateTime مع التاريخ الحالي
          final List<String> parts = savedAt.split(':');
          if (parts.length >= 2) {
            final int hour = int.tryParse(parts[0]) ?? 0;
            final int minute = int.tryParse(parts[1]) ?? 0;
            final int second = parts.length > 2
                ? int.tryParse(parts[2].split('.')[0]) ?? 0
                : 0;
            final DateTime now = DateTime.now();
            return DateTime(now.year, now.month, now.day, hour, minute, second);
          }
        }
        // تنسيق مخصص "yyyy-MM-dd HH:mm:ss"
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(savedAt, true);
      } else if (savedAt is DateTime) {
        return savedAt;
      }
    } on Exception catch (e) {
      // استخدام ErrorHandlerService لمعالجة الأخطاء
      // import 'package:flutter/foundation.dart';
      // import '../services/error_handler_service.dart';
      // ErrorHandlerService.handleError(
      //   e,
      //   stackTrace: stackTrace.toString(),
      //   type: ErrorType.validation,
      //   severity: ErrorSeverity.low,
      //   userAction: 'تحليل التاريخ في Product',
      //   context: {'savedAt': savedAt.toString()},
      // );
      debugPrint('❌ خطأ في تحليل التاريخ: $savedAt - $e');
    }
    return DateTime.now();
  }

  // تم نقل _parseInt إلى DataConversionService

  @override
  String toString() =>
      'Product{id: $id, name: $name, wholesalePrice: $wholesalePrice, retailPrice: $retailPrice}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// إنشاء نسخة من المنتج مع تحديث القيم المحددة
  Product copyWith({
    String? id,
    String? name,
    int? wholesalePrice,
    int? retailPrice,
    DateTime? savedAt,
    DateTime? lastModified,
    String? description,
    String? barcode,
    String? category,
    String? supplier,
    ProductStatus? status,
    List<String>? images,
    List<String>? tags,
    double? weight,
    String? dimensions,
    int? minimumStock,
    int? maximumStock,
    double? taxRate,
    double? discountRate,
    bool? isActive,
    String? notes,
    bool? isSynced,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        savedAt: savedAt ?? this.savedAt,
        lastModified: lastModified ?? this.lastModified,
        description: description ?? this.description,
        barcode: barcode ?? this.barcode,
        category: category ?? this.category,
        supplier: supplier ?? this.supplier,
        status: status ?? this.status,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        weight: weight ?? this.weight,
        dimensions: dimensions ?? this.dimensions,
        minimumStock: minimumStock ?? this.minimumStock,
        maximumStock: maximumStock ?? this.maximumStock,
        taxRate: taxRate ?? this.taxRate,
        discountRate: discountRate ?? this.discountRate,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
        isSynced: isSynced ?? this.isSynced,
      );
}
