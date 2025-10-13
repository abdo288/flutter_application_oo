/// أدوات التحقق من صحة البيانات
class Validators {
  /// التحقق من صحة اسم المنتج
  static String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المنتج مطلوب';
    }
    if (value.trim().length < 2) {
      return 'اسم المنتج يجب أن يكون على الأقل حرفين';
    }
    if (value.trim().length > 50) {
      return 'اسم المنتج لا يمكن أن يتجاوز 50 حرف';
    }
    return null;
  }

  /// التحقق من صحة السعر
  static String? validatePrice(String? value, {String fieldName = 'السعر'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }

    final int? price = int.tryParse(value.trim());
    if (price == null) {
      return '$fieldName يجب أن يكون رقماً صحيحاً';
    }

    if (price < 0) {
      return '$fieldName لا يمكن أن يكون سالباً';
    }

    if (price > 1000000) {
      return '$fieldName لا يمكن أن يتجاوز 1,000,000';
    }

    return null;
  }

  /// التحقق من صحة سعر الجملة
  static String? validateWholesalePrice(String? value) =>
      validatePrice(value, fieldName: 'سعر الجملة');

  /// التحقق من صحة سعر التجزئة
  static String? validateRetailPrice(String? value) =>
      validatePrice(value, fieldName: 'سعر التجزئة');

  /// التحقق من صحة الكمية
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الكمية مطلوبة';
    }

    final int? quantity = int.tryParse(value.trim());
    if (quantity == null) {
      return 'الكمية يجب أن تكون رقماً صحيحاً';
    }

    if (quantity < 0) {
      return 'الكمية لا يمكن أن تكون سالبة';
    }

    if (quantity > 10000) {
      return 'الكمية لا يمكن أن تتجاوز 10,000';
    }

    return null;
  }

  /// التحقق من صحة السعرين معاً
  static String? validatePrices(String? wholesalePrice, String? retailPrice) {
    final String? wholesaleError = validateWholesalePrice(wholesalePrice);
    if (wholesaleError != null) return wholesaleError;

    final String? retailError = validateRetailPrice(retailPrice);
    if (retailError != null) return retailError;

    final int wholesale = int.tryParse(wholesalePrice!.trim()) ?? 0;
    final int retail = int.tryParse(retailPrice!.trim()) ?? 0;

    if (retail < wholesale) {
      return 'سعر التجزئة يجب أن يكون أكبر من أو يساوي سعر الجملة';
    }

    return null;
  }

  /// التحقق من صحة البيانات الكاملة للمنتج
  static String? validateProductData({
    String? name,
    String? wholesalePrice,
    String? retailPrice,
  }) {
    final String? nameError = validateProductName(name);
    if (nameError != null) return nameError;

    return validatePrices(wholesalePrice, retailPrice);
  }

  /// التحقق من صحة البيانات الكاملة لعنصر المخزون
  static String? validateInventoryData({
    String? name,
    String? wholesalePrice,
    String? quantity,
  }) {
    final String? nameError = validateProductName(name);
    if (nameError != null) return nameError;

    final String? priceError = validateWholesalePrice(wholesalePrice);
    if (priceError != null) return priceError;

    return validateQuantity(quantity);
  }

  /// تنظيف النص من المسافات الزائدة
  static String cleanText(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// التحقق من صحة المعرف
  static String? validateId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'المعرف مطلوب';
    }
    return null;
  }
}
