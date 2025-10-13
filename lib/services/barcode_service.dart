import 'package:flutter/foundation.dart';

/// خدمة مركزية لتوليد وإدارة الباركود
class BarcodeService {
  static const String _barcodePrefix = 'BC';
  static const int _barcodeLength = 13; // طول الباركود القياسي
  static final Set<String> _usedBarcodes = <String>{};

  /// توليد باركود فريد
  static String generateUniqueBarcode() {
    String barcode;
    int attempts = 0;
    const int maxAttempts = 100;

    do {
      // توليد باركود عشوائي
      barcode = _generateRandomBarcode();
      attempts++;

      if (attempts >= maxAttempts) {
        debugPrint(
            'تحذير: تم الوصول للحد الأقصى من المحاولات لتوليد باركود فريد');
        // إضافة timestamp لضمان التفرد
        barcode = '$_barcodePrefix${DateTime.now().millisecondsSinceEpoch}';
        break;
      }
    } while (_usedBarcodes.contains(barcode));

    // إضافة الباركود إلى القائمة المستخدمة
    _usedBarcodes.add(barcode);

    debugPrint('تم توليد باركود فريد: $barcode');
    return barcode;
  }

  /// توليد باركود عشوائي
  static String _generateRandomBarcode() {
    // توليد رقم عشوائي بطول مناسب
    final String randomNumber =
        _generateRandomNumber(_barcodeLength - _barcodePrefix.length);
    return '$_barcodePrefix$randomNumber';
  }

  /// توليد رقم عشوائي بطول محدد
  static String _generateRandomNumber(int length) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(DateTime.now().millisecondsSinceEpoch % 10);
    }
    return buffer.toString();
  }

  /// توليد باركود من معرف المنتج
  static String generateBarcodeFromId(String productId) {
    if (productId.isEmpty) {
      return generateUniqueBarcode();
    }

    // تحويل المعرف إلى باركود
    final String barcode =
        '$_barcodePrefix${productId.replaceAll('-', '').substring(0, 8)}';

    // التأكد من التفرد
    if (_usedBarcodes.contains(barcode)) {
      return generateUniqueBarcode();
    }

    _usedBarcodes.add(barcode);
    return barcode;
  }

  /// توليد باركود من اسم المنتج
  static String generateBarcodeFromName(String productName) {
    if (productName.isEmpty) {
      return generateUniqueBarcode();
    }

    // تحويل الاسم إلى باركود باستخدام hash
    final int nameHash = productName.hashCode.abs();
    final String barcode =
        '$_barcodePrefix${nameHash.toString().padLeft(8, '0')}';

    // التأكد من التفرد
    if (_usedBarcodes.contains(barcode)) {
      return generateUniqueBarcode();
    }

    _usedBarcodes.add(barcode);
    return barcode;
  }

  /// التحقق من صحة تنسيق الباركود
  static bool isValidBarcodeFormat(String barcode) {
    if (barcode.isEmpty) return false;

    // التحقق من البادئة
    if (!barcode.startsWith(_barcodePrefix)) return false;

    // التحقق من الطول
    if (barcode.length != _barcodeLength) return false;

    // التحقق من أن باقي الأحرف أرقام
    final String numberPart = barcode.substring(_barcodePrefix.length);
    return RegExp(r'^\d+$').hasMatch(numberPart);
  }

  /// التحقق من أن الباركود فريد
  static bool isBarcodeUnique(String barcode) =>
      !_usedBarcodes.contains(barcode);

  /// تسجيل باركود كـ مستخدم
  static void markBarcodeAsUsed(String barcode) {
    if (isValidBarcodeFormat(barcode)) {
      _usedBarcodes.add(barcode);
    }
  }

  /// إزالة باركود من القائمة المستخدمة
  static void markBarcodeAsUnused(String barcode) {
    _usedBarcodes.remove(barcode);
  }

  /// الحصول على جميع الباركود المستخدمة
  static Set<String> getUsedBarcodes() => Set<String>.from(_usedBarcodes);

  /// مسح جميع الباركود المستخدمة (للاستخدام في الاختبارات)
  static void clearUsedBarcodes() {
    _usedBarcodes.clear();
  }

  /// توليد باركود مخصص
  static String generateCustomBarcode({
    String? prefix,
    String? suffix,
    int? length,
  }) {
    final String customPrefix = prefix ?? _barcodePrefix;
    final int customLength = length ?? _barcodeLength;
    final int numberLength = customLength - customPrefix.length;

    String barcode;
    int attempts = 0;
    const int maxAttempts = 100;

    do {
      final String randomNumber = _generateRandomNumber(numberLength);
      barcode = '$customPrefix$randomNumber';

      if (suffix != null) {
        barcode = '$barcode$suffix';
      }

      attempts++;

      if (attempts >= maxAttempts) {
        debugPrint(
            'تحذير: تم الوصول للحد الأقصى من المحاولات لتوليد باركود مخصص فريد');
        barcode = '$customPrefix${DateTime.now().millisecondsSinceEpoch}';
        if (suffix != null) {
          barcode = '$barcode$suffix';
        }
        break;
      }
    } while (_usedBarcodes.contains(barcode));

    _usedBarcodes.add(barcode);
    return barcode;
  }

  /// توليد باركود متسلسل
  static String generateSequentialBarcode({int? startNumber}) {
    final int start = startNumber ?? _usedBarcodes.length + 1;
    final String numberPart = start.toString().padLeft(8, '0');
    final String barcode = '$_barcodePrefix$numberPart';

    _usedBarcodes.add(barcode);
    return barcode;
  }

  /// تحليل الباركود واستخراج المعلومات
  static Map<String, dynamic> parseBarcode(String barcode) {
    if (!isValidBarcodeFormat(barcode)) {
      return <String, dynamic>{
        'isValid': false,
        'error': 'تنسيق الباركود غير صحيح',
      };
    }

    final String prefix = barcode.substring(0, _barcodePrefix.length);
    final String numberPart = barcode.substring(_barcodePrefix.length);

    return <String, dynamic>{
      'isValid': true,
      'prefix': prefix,
      'number': numberPart,
      'length': barcode.length,
      'isUsed': _usedBarcodes.contains(barcode),
    };
  }

  /// إحصائيات الباركود
  static Map<String, dynamic> getBarcodeStats() => <String, dynamic>{
        'totalUsed': _usedBarcodes.length,
        'prefix': _barcodePrefix,
        'standardLength': _barcodeLength,
        'usedBarcodes': List<String>.from(_usedBarcodes),
      };
}
