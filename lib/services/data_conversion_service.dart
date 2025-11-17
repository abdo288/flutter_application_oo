import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import 'error_handler_service.dart';

/// خدمة تحويل البيانات من Firestore إلى النماذج
class DataConversionService {
  /// تحويل مستند Firestore إلى Product
  static Product? convertDocumentToProduct(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final Map<String, dynamic> data = doc.data();
      return Product(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        wholesalePrice:
            _parseInt(data['wholesalePrice'] ?? data['wholesale_price']),
        retailPrice: _parseInt(data['retailPrice'] ?? data['retail_price']),
        savedAt: _parseDateTime(data['savedAt'] ?? data['saved_at']),
        lastModified: _parseOptionalDateTime(
          data['last_modified'] ?? data['savedAt'] ?? data['saved_at'],
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.validation,
        userAction: 'تحويل مستند Firestore إلى Product',
        context: <String, dynamic>{'documentId': doc.id},
      );
      debugPrint('خطأ في تحويل المستند إلى Product: $e');
      return null;
    }
  }

  /// تحويل مستند Firestore إلى InventoryItem
  static InventoryItem? convertDocumentToInventoryItem(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final Map<String, dynamic> data = doc.data();
      return convertMapToInventoryItem(<String, dynamic>{
        'id': doc.id,
        ...data,
      });
    } catch (e, stackTrace) {
      ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.validation,
        userAction: 'تحويل مستند Firestore إلى InventoryItem',
        context: <String, dynamic>{'documentId': doc.id},
      );
      debugPrint('خطأ في تحويل المستند إلى InventoryItem: $e');
      return null;
    }
  }

  /// تحويل قائمة مستندات إلى قائمة منتجات
  static List<Product> convertDocumentsToProducts(
      List<QueryDocumentSnapshot<Object?>> docs) {
    final List<Product> products = <Product>[];

    for (final QueryDocumentSnapshot<Object?> doc in docs) {
      try {
        Product? product;
        if (doc is QueryDocumentSnapshot<Map<String, dynamic>>) {
          product = convertDocumentToProduct(doc);
        } else {
          // معالجة DocumentSnapshot العادي
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          product = convertMapToProduct(data);
        }
        if (product != null && product.isValid()) {
          products.add(product);
        }
      } catch (e, stackTrace) {
        ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.validation,
          userAction: 'تحويل مستند إلى Product في قائمة',
          context: <String, dynamic>{'documentId': doc.id},
        );
        debugPrint('خطأ في تحويل مستند إلى Product: $e - تم تجاهل المستند');
        // تجاهل المستند الفاسد بدلاً من إيقاف العملية
        continue;
      }
    }

    return products;
  }

  /// تحويل قائمة مستندات إلى قائمة عناصر مخزون
  static List<InventoryItem> convertDocumentsToInventoryItems(
      List<QueryDocumentSnapshot<Object?>> docs) {
    final List<InventoryItem> items = <InventoryItem>[];

    for (final QueryDocumentSnapshot<Object?> doc in docs) {
      try {
        InventoryItem? item;
        if (doc is QueryDocumentSnapshot<Map<String, dynamic>>) {
          item = convertDocumentToInventoryItem(doc);
        } else {
          // معالجة DocumentSnapshot العادي
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          item = convertMapToInventoryItem(data);
        }
        if (item != null && item.isValid()) {
          items.add(item);
        }
      } catch (e, stackTrace) {
        ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.validation,
          userAction: 'تحويل مستند إلى InventoryItem في قائمة',
          context: <String, dynamic>{'documentId': doc.id},
        );
        debugPrint(
            'خطأ في تحويل مستند إلى InventoryItem: $e - تم تجاهل المستند');
        // تجاهل المستند الفاسد بدلاً من إيقاف العملية
        continue;
      }
    }

    return items;
  }

  /// تحويل Map إلى Product مع التحقق من صحة البيانات
  static Product? convertMapToProduct(Map<String, dynamic> data) {
    try {
      // التحقق من وجود الحقول المطلوبة
      if (!_hasRequiredProductFields(data)) {
        throw FormatException('بيانات المنتج ناقصة: $data');
      }

      return Product(
        id: data['id']?.toString(),
        name: data['name']?.toString() ?? '',
        wholesalePrice: _parsePrice(data['wholesalePrice']),
        retailPrice: _parsePrice(data['retailPrice']),
        savedAt: data['savedAt'] is DateTime
            ? data['savedAt'] as DateTime
            : _parseDateTime(data['savedAt']),
        lastModified: data['lastModified'] is DateTime
            ? data['lastModified'] as DateTime
            : _parseOptionalDateTime(data['lastModified'] ?? data['savedAt']),
      );
    } catch (e, stackTrace) {
      ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.validation,
        severity: ErrorSeverity.high,
        userAction: 'تحويل Map إلى Product',
        context: <String, dynamic>{'dataKeys': data.keys.toList()},
      );
      debugPrint('خطأ في تحويل Map إلى Product: $e');
      rethrow; // رمي الاستثناء بدلاً من إرجاع null
    }
  }

  /// تحويل Map إلى InventoryItem مع التحقق من صحة البيانات
  static InventoryItem? convertMapToInventoryItem(Map<String, dynamic> data) {
    try {
      // التحقق من وجود الحقول المطلوبة
      if (!_hasRequiredInventoryFields(data)) {
        throw FormatException('بيانات عنصر المخزون ناقصة: $data');
      }

      return InventoryItem(
        id: data['id']?.toString(),
        name: data['name']?.toString() ?? '',
        barcode: data['barcode']?.toString(),
        wholesalePrice: _parsePrice(data['wholesalePrice']),
        retailPrice: _parsePrice(data['retailPrice']),
        quantity: _parseQuantity(data['quantity']),
        originalQuantity: _parsePrice(data['originalQuantity']),
        addedDate: _parseDate(data['addedDate']),
        addedTime: _parseTime(data['addedTime']),
        expiryDate: _parseOptionalDate(data['expiryDate']),
        lastModified: _parseOptionalDateTime(data['lastModified']) ??
            _parseTime(data['addedTime']),
      );
    } catch (e, stackTrace) {
      ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.validation,
        severity: ErrorSeverity.high,
        userAction: 'تحويل Map إلى InventoryItem',
        context: <String, dynamic>{'dataKeys': data.keys.toList()},
      );
      debugPrint('خطأ في تحويل Map إلى InventoryItem: $e');
      rethrow; // رمي الاستثناء بدلاً من إرجاع null
    }
  }

  /// تحويل Product إلى Map للاستخدام مع Firestore
  static Map<String, dynamic> convertProductToMap(Product product) {
    try {
      return product.toMap();
    } catch (e) {
      debugPrint('خطأ في تحويل Product إلى Map: $e');
      return <String, dynamic>{};
    }
  }

  /// تحويل InventoryItem إلى Map للاستخدام مع Firestore
  static Map<String, dynamic> convertInventoryItemToMap(InventoryItem item) {
    try {
      return item.toMap();
    } catch (e) {
      debugPrint('خطأ في تحويل InventoryItem إلى Map: $e');
      return <String, dynamic>{};
    }
  }

  /// تنظيف وتحسين بيانات المنتج قبل الحفظ
  static Map<String, dynamic> cleanProductData(Map<String, dynamic> data) {
    final Map<String, dynamic> cleanedData = Map<String, dynamic>.from(data);

    // تنظيف النص
    if (cleanedData['name'] is String) {
      cleanedData['name'] = cleanedData['name'].toString().trim();
    }

    // تحويل الأسعار إلى أرقام صحيحة
    if (cleanedData['wholesalePrice'] != null) {
      cleanedData['wholesalePrice'] =
          _parsePrice(cleanedData['wholesalePrice']);
    } else if (cleanedData['wholesale_price'] != null) {
      cleanedData['wholesale_price'] =
          _parsePrice(cleanedData['wholesale_price']);
    }

    if (cleanedData['retailPrice'] != null) {
      cleanedData['retailPrice'] = _parsePrice(cleanedData['retailPrice']);
    } else if (cleanedData['retail_price'] != null) {
      cleanedData['retail_price'] = _parsePrice(cleanedData['retail_price']);
    }

    // إضافة timestamp إذا لم يكن موجوداً
    if (cleanedData['savedAt'] == null && cleanedData['saved_at'] == null) {
      cleanedData['savedAt'] = DateTime.now().toIso8601String();
    }

    return cleanedData;
  }

  /// تنظيف وتحسين بيانات عنصر المخزون قبل الحفظ
  static Map<String, dynamic> cleanInventoryData(Map<String, dynamic> data) {
    final Map<String, dynamic> cleanedData = Map<String, dynamic>.from(data);

    // تنظيف النص
    if (cleanedData['name'] is String) {
      cleanedData['name'] = cleanedData['name'].toString().trim();
    }

    if (cleanedData['barcode'] is String) {
      cleanedData['barcode'] = cleanedData['barcode'].toString().trim();
    }

    // تحويل الأسعار والكميات إلى أرقام صحيحة
    if (cleanedData['wholesalePrice'] != null) {
      cleanedData['wholesalePrice'] =
          _parsePrice(cleanedData['wholesalePrice']);
    }

    if (cleanedData['quantity'] != null) {
      cleanedData['quantity'] = _parseQuantity(cleanedData['quantity']);
    }

    if (cleanedData['originalQuantity'] != null) {
      cleanedData['originalQuantity'] =
          _parseQuantity(cleanedData['originalQuantity']);
    }

    // إضافة التواريخ إذا لم تكن موجودة
    if (cleanedData['addedDate'] == null) {
      cleanedData['addedDate'] = DateTime.now().toIso8601String().split('T')[0];
    }

    if (cleanedData['addedTime'] == null) {
      cleanedData['addedTime'] =
          DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    }

    return cleanedData;
  }

  /// التحقق من وجود الحقول المطلوبة للمنتج
  static bool _hasRequiredProductFields(Map<String, dynamic> data) =>
      data.containsKey('name') &&
      data['name'] != null &&
      data['name'].toString().isNotEmpty &&
      (data.containsKey('wholesalePrice') ||
          data.containsKey('wholesale_price')) &&
      (data.containsKey('retailPrice') || data.containsKey('retail_price'));

  /// التحقق من وجود الحقول المطلوبة لعنصر المخزون
  static bool _hasRequiredInventoryFields(Map<String, dynamic> data) =>
      data.containsKey('name') &&
      data['name'] != null &&
      data['name'].toString().isNotEmpty &&
      data.containsKey('wholesalePrice') &&
      data.containsKey('quantity');

  /// تحليل السعر وتحويله إلى رقم صحيح
  static int _parsePrice(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      final double? parsed = double.tryParse(value);
      if (parsed == null) {
        debugPrint('⚠️ لا يمكن تحليل السعر: $value - استخدام 0 كقيمة افتراضية');
        return 0;
      }
      return parsed.toInt();
    }
    debugPrint(
        '⚠️ نوع بيانات غير صالح للسعر: ${value.runtimeType} - استخدام 0 كقيمة افتراضية');
    return 0;
  }

  /// تحليل الكمية وتحويلها إلى رقم صحيح
  static int _parseQuantity(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      if (value == 'نفذت الكمية') return 0;
      final int? parsed = int.tryParse(value);
      if (parsed == null) {
        debugPrint(
            '⚠️ لا يمكن تحليل الكمية: $value - استخدام 0 كقيمة افتراضية');
        return 0;
      }
      return parsed;
    }
    debugPrint(
        '⚠️ نوع بيانات غير صالح للكمية: ${value.runtimeType} - استخدام 0 كقيمة افتراضية');
    return 0;
  }

  /// تحويل Timestamp إلى DateTime
  static DateTime convertTimestampToDateTime(Object? timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        debugPrint('خطأ في تحليل التاريخ: $e');
        return DateTime.now();
      }
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  /// تحويل DateTime إلى Timestamp
  static Timestamp convertDateTimeToTimestamp(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);

  /// التحقق من صحة بيانات المنتج
  static bool validateProductData(Map<String, dynamic> data) {
    try {
      final Product? product = convertMapToProduct(data);
      return product != null && product.isValid();
    } catch (e) {
      return false;
    }
  }

  /// التحقق من صحة بيانات عنصر المخزون
  static bool validateInventoryData(Map<String, dynamic> data) {
    try {
      final InventoryItem? item = convertMapToInventoryItem(data);
      return item != null && item.isValid();
    } catch (e) {
      return false;
    }
  }

  /// إصلاح البيانات التالفة
  static Map<String, dynamic> repairData(Map<String, dynamic> data) {
    final Map<String, dynamic> repairedData = Map<String, dynamic>.from(data);

    // إصلاح الحقول المفقودة
    if (!repairedData.containsKey('name') || repairedData['name'] == null) {
      repairedData['name'] = 'اسم غير معروف';
    }

    if (!repairedData.containsKey('wholesalePrice') ||
        repairedData['wholesalePrice'] == null) {
      repairedData['wholesalePrice'] = 0;
    }

    if (!repairedData.containsKey('quantity') ||
        repairedData['quantity'] == null) {
      repairedData['quantity'] = 0;
    }

    return repairedData;
  }

  // Helper methods for parsing
  static int _parseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// تحليل DateTime من Timestamp أو String
  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw FormatException('لا يمكن تحليل التاريخ: $value - $e');
      }
    } else if (value is DateTime) {
      return value;
    }
    throw FormatException('نوع بيانات غير صالح للتاريخ: ${value.runtimeType}');
  }

  /// تحليل DateTime اختياري
  static DateTime? _parseOptionalDateTime(Object? value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw FormatException('لا يمكن تحليل التاريخ: $value - $e');
      }
    }
    throw FormatException('نوع بيانات غير صالح للتاريخ: ${value.runtimeType}');
  }

  static DateTime _parseTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Parse time string like "HH:mm:ss"
        if (value.contains('T') && value.contains('Z')) {
          // تنسيق ISO 8601
          return DateTime.parse(value);
        } else if (value.contains(':')) {
          // تنسيق HH:mm:ss - إنشاء DateTime مع التاريخ الحالي
          final List<String> parts = value.split(':');
          if (parts.length >= 2) {
            final int? hour = int.tryParse(parts[0]);
            final int? minute = int.tryParse(parts[1]);
            final int? second = parts.length > 2 ? int.tryParse(parts[2]) : 0;

            if (hour == null || minute == null) {
              throw FormatException('لا يمكن تحليل الوقت: $value');
            }

            final DateTime now = DateTime.now();
            return DateTime(
                now.year, now.month, now.day, hour, minute, second ?? 0);
          }
          throw FormatException('تنسيق وقت غير صالح: $value');
        } else {
          // تنسيق آخر
          return DateTime.parse(value);
        }
      } catch (e) {
        throw FormatException('لا يمكن تحليل الوقت: $value - $e');
      }
    }
    throw FormatException('نوع بيانات غير صالح للوقت: ${value.runtimeType}');
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('خطأ في تحليل التاريخ الاختياري: $e');
      }
    }
    return null;
  }
}
