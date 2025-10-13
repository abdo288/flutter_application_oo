// import 'package:drift/drift.dart';

/// تكوين قاعدة البيانات
class DatabaseConfig {
  // ========== إعدادات قاعدة البيانات ==========

  /// إصدار قاعدة البيانات
  static const int databaseVersion = 1;

  /// اسم قاعدة البيانات
  static const String databaseName = 'profit_calculator.db';

  /// حجم الذاكرة المؤقتة (بالكيلوبايت) - تحسين لتقليل استهلاك الذاكرة
  static const int cacheSize = 1000;

  /// مهلة الاستعلام (بالميلي ثانية)
  static const int queryTimeout = 10000;

  // ========== إعدادات الجداول ==========

  /// الحد الأقصى لطول اسم المنتج
  static const int maxProductNameLength = 100;

  /// الحد الأقصى لطول اسم عنصر المخزون
  static const int maxInventoryNameLength = 100;

  /// الحد الأقصى لسعر المنتج
  static const double maxPrice = 999999.99;

  /// الحد الأقصى لكمية المخزون
  static const int maxQuantity = 999999;

  // ========== إعدادات المزامنة ==========

  /// عدد الأيام للاحتفاظ بالعمليات المعالجة
  static const int daysToKeepProcessedOperations = 7;

  /// الحد الأقصى لعدد المحاولات
  static const int maxRetryAttempts = 3;

  /// مهلة المزامنة (بالثواني)
  static const int syncTimeoutSeconds = 15;

  // ========== إعدادات الأداء ==========

  /// حجم الدفعة للعمليات المجمعة - تحسين لتقليل استهلاك الذاكرة
  static const int batchSize = 50;

  /// عدد الاستعلامات المتزامنة
  static const int maxConcurrentQueries = 5;

  /// مهلة الاتصال (بالميلي ثانية)
  static const int connectionTimeout = 5000;

  // ========== إعدادات الأمان ==========

  /// تمكين تشفير قاعدة البيانات
  static const bool enableEncryption = false;

  /// مفتاح التشفير (يجب تغييره في الإنتاج)
  static const String encryptionKey =
      'default_encryption_key_change_in_production';

  // ========== إعدادات التطوير ==========

  /// تمكين وضع التطوير
  static const bool isDevelopmentMode = true;

  /// تمكين تسجيل الاستعلامات
  static const bool enableQueryLogging = true;

  /// تمكين التحقق من صحة البيانات
  static const bool enableDataValidation = true;

  // ========== دوال التحقق ==========

  /// التحقق من صحة اسم المنتج
  static bool isValidProductName(String name) {
    if (name.isEmpty || name.length > maxProductNameLength) {
      return false;
    }

    // التحقق من الأحرف المسموحة
    final RegExp validChars = RegExp(r'^[a-zA-Z0-9\u0600-\u06FF\s\-_\.]+$');
    return validChars.hasMatch(name);
  }

  /// التحقق من صحة اسم عنصر المخزون
  static bool isValidInventoryName(String name) {
    if (name.isEmpty || name.length > maxInventoryNameLength) {
      return false;
    }

    // التحقق من الأحرف المسموحة
    final RegExp validChars = RegExp(r'^[a-zA-Z0-9\u0600-\u06FF\s\-_\.]+$');
    return validChars.hasMatch(name);
  }

  /// التحقق من صحة السعر
  static bool isValidPrice(double price) => price >= 0 && price <= maxPrice;

  /// التحقق من صحة الكمية
  static bool isValidQuantity(int quantity) =>
      quantity >= 0 && quantity <= maxQuantity;

  // ========== دوال التحويل ==========

  /// تحويل السعر إلى عدد صحيح (بالقروش)
  static int priceToCents(double price) => (price * 100).round();

  /// تحويل عدد صحيح إلى سعر (بالقروش)
  static double centsToPrice(int cents) => cents / 100.0;

  // ========== إعدادات النسخ الاحتياطي ==========

  /// تمكين النسخ الاحتياطي التلقائي
  static const bool enableAutoBackup = true;

  /// فاصل النسخ الاحتياطي (بالساعات) - تحسين لتقليل استهلاك الذاكرة
  static const int backupIntervalHours = 48;

  /// عدد النسخ الاحتياطية للاحتفاظ بها
  static const int maxBackupFiles = 7;

  // ========== إعدادات الاستعلامات ==========

  /// إعدادات الاستعلام الافتراضية
  // static const QueryExecutor defaultQueryExecutor = QueryExecutor();

  /// إعدادات الفهرس
  static const Map<String, Map<String, dynamic>> indexes =
      <String, Map<String, dynamic>>{
    'products_name_idx': <String, dynamic>{
      'table': 'products',
      'columns': <String>['name'],
      'unique': false,
    },
    'products_user_id_idx': <String, dynamic>{
      'table': 'products',
      'columns': <String>['user_id'],
      'unique': false,
    },
    'inventory_name_idx': <String, dynamic>{
      'table': 'inventory',
      'columns': <String>['name'],
      'unique': false,
    },
    'inventory_user_id_idx': <String, dynamic>{
      'table': 'inventory',
      'columns': <String>['user_id'],
      'unique': false,
    },
    'sync_operations_timestamp_idx': <String, dynamic>{
      'table': 'sync_operations',
      'columns': <String>['timestamp'],
      'unique': false,
    },
  };

  // ========== رسائل الخطأ ==========

  /// رسائل الخطأ الشائعة
  static const Map<String, String> errorMessages = <String, String>{
    'invalid_product_name': 'اسم المنتج غير صالح',
    'invalid_inventory_name': 'اسم عنصر المخزون غير صالح',
    'invalid_price': 'السعر غير صالح',
    'invalid_quantity': 'الكمية غير صالحة',
    'database_connection_failed': 'فشل في الاتصال بقاعدة البيانات',
    'sync_failed': 'فشل في المزامنة',
    'backup_failed': 'فشل في النسخ الاحتياطي',
  };

  // ========== دوال المساعدة ==========

  /// الحصول على رسالة خطأ
  static String getErrorMessage(String errorCode) =>
      errorMessages[errorCode] ?? 'خطأ غير معروف';

  /// التحقق من صحة جميع البيانات
  static bool validateAllData(Map<String, dynamic> data) {
    try {
      // التحقق من اسم المنتج
      if (data.containsKey('name')) {
        if (!isValidProductName(data['name'].toString())) {
          return false;
        }
      }

      // التحقق من السعر
      if (data.containsKey('wholesale_price')) {
        final dynamic price = data['wholesale_price'];
        if (price is num && !isValidPrice(price.toDouble())) {
          return false;
        }
      }

      if (data.containsKey('retail_price')) {
        final dynamic price = data['retail_price'];
        if (price is num && !isValidPrice(price.toDouble())) {
          return false;
        }
      }

      // التحقق من الكمية
      if (data.containsKey('quantity')) {
        final dynamic quantity = data['quantity'];
        if (quantity is num && !isValidQuantity(quantity.toInt())) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// تنظيف البيانات
  static Map<String, dynamic> cleanData(Map<String, dynamic> data) {
    final Map<String, dynamic> cleanedData = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      // تنظيف النصوص
      if (value is String) {
        cleanedData[key] = value.trim();
      } else {
        cleanedData[key] = value;
      }
    }

    return cleanedData;
  }
}
