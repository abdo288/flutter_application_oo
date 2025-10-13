import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';
import 'backup_service.dart';
import 'data_conversion_service.dart';
import 'error_handler_service.dart';

/// خدمة استعادة البيانات من النسخ الاحتياطية
class RestoreService {
  RestoreService({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  })  : _productProvider = productProvider,
        _inventoryProvider = inventoryProvider;
  static const String _restoreHistoryKey = 'restore_history';

  final StreamProductProvider _productProvider;
  final StreamInventoryProvider _inventoryProvider;

  /// استعادة البيانات من ملف النسخة الاحتياطية
  Future<RestoreResult> restoreFromFile(
    String filePath, {
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    try {
      debugPrint('بدء استعادة البيانات من: $filePath');

      // التحقق من صحة الملف
      final BackupValidationResult validation =
          await BackupService.validateBackupFile(filePath);
      if (!validation.isValid) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير صحيح: ${validation.error}',
        );
      }

      // إنشاء نسخة احتياطية قبل الاستعادة إذا طُلب ذلك
      String? backupFilePath;
      if (backupBeforeRestore) {
        final BackupService backupService = BackupService(
          productProvider: _productProvider,
          inventoryProvider: _inventoryProvider,
        );
        final BackupResult backupResult =
            await backupService.createFullBackup();
        if (backupResult.success) {
          backupFilePath = backupResult.filePath;
        }
      }

      // قراءة البيانات من الملف مع معالجة أخطاء محسنة
      final File file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير موجود: $filePath',
        );
      }

      final int fileSize = await file.length();
      if (fileSize == 0) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية فارغ',
        );
      }

      if (fileSize > 100 * 1024 * 1024) {
        // 100MB limit
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية كبير جداً (أكبر من 100MB)',
        );
      }

      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        return RestoreResult(
          success: false,
          error: 'فشل في قراءة ملف النسخة الاحتياطية: $e',
        );
      }

      if (content.isEmpty) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية فارغ من المحتوى',
        );
      }

      Map<String, dynamic> data;
      try {
        final dynamic decoded = json.decode(content);
        if (decoded is! Map<String, dynamic>) {
          return RestoreResult(
            success: false,
            error: 'تنسيق ملف النسخة الاحتياطية غير صحيح',
          );
        }
        data = decoded;
      } catch (e) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية تالف أو غير صالح: $e',
        );
      }

      // استعادة البيانات حسب النوع
      final RestoreResult result = await _restoreData(data, mergeData);

      // تسجيل عملية الاستعادة
      await _recordRestoreOperation(filePath, result, backupFilePath);

      debugPrint('تمت استعادة البيانات بنجاح');
      return result;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'استعادة البيانات حسب النوع في RestoreService',
        context: <String, dynamic>{
          'operation': '_restoreData',
          'service': 'RestoreService',
          'mergeData': mergeData,
        },
      );
      debugPrint('خطأ في استعادة البيانات: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة البيانات: خطأ غير محدد',
      );
    }
  }

  /// استعادة البيانات من ملف محدد من قبل المستخدم
  Future<RestoreResult> restoreFromUserFile({
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(
          success: false,
          error: 'لم يتم اختيار ملف',
        );
      }

      final String filePath = result.files.first.path!;
      return await restoreFromFile(
        filePath,
        mergeData: mergeData,
        backupBeforeRestore: backupBeforeRestore,
      );
    } catch (e) {
      debugPrint('خطأ في اختيار ملف الاستعادة: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في اختيار الملف: خطأ غير محدد',
      );
    }
  }

  /// استعادة البيانات من السحابة
  Future<RestoreResult> restoreFromCloud(
    String cloudUrl, {
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    try {
      debugPrint('بدء استعادة البيانات من السحابة: $cloudUrl');

      // تحميل الملف من السحابة
      final File? downloadedFile =
          await BackupService.downloadFromCloud(cloudUrl);
      if (downloadedFile == null) {
        return RestoreResult(
          success: false,
          error: 'فشل في تحميل النسخة الاحتياطية من السحابة',
        );
      }

      // استعادة البيانات من الملف المحمل
      final RestoreResult result = await restoreFromFile(
        downloadedFile.path,
        mergeData: mergeData,
        backupBeforeRestore: backupBeforeRestore,
      );

      // حذف الملف المؤقت
      try {
        await downloadedFile.delete();
      } catch (e) {
        debugPrint('خطأ في حذف الملف المؤقت: خطأ غير محدد');
      }

      return result;
    } catch (e) {
      debugPrint('خطأ في استعادة البيانات من السحابة: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة البيانات من السحابة: خطأ غير محدد',
      );
    }
  }

  /// استعادة المنتجات فقط
  Future<RestoreResult> restoreProductsOnly(
    String filePath, {
    bool mergeData = false,
  }) async {
    try {
      final BackupValidationResult validation =
          await BackupService.validateBackupFile(filePath);
      if (!validation.isValid) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير صحيح',
        );
      }

      final File file = File(filePath);
      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(json.decode(content) as Map);

      final Map<String, dynamic> backupData =
          Map<String, dynamic>.from(data['data'] as Map);
      final List<dynamic> productsData =
          List<dynamic>.from(backupData['products'] as List? ?? <dynamic>[]);

      int restoredCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (final Map<String, dynamic> productData
          in productsData.cast<Map<String, dynamic>>()) {
        try {
          final Product? product =
              DataConversionService.convertMapToProduct(productData);
          if (product == null) throw Exception('تعذر تحويل البيانات إلى منتج');

          if (!mergeData) {
            // التحقق من وجود المنتج
            final bool exists =
                await _productProvider.checkIfProductNameExists(product.name);
            if (exists) {
              skippedCount++;
              continue;
            }
          }

          await _productProvider.addProduct(product);
          restoredCount++;
        } on Exception catch (_) {
          debugPrint('خطأ في استعادة منتج: خطأ غير محدد');
          errorCount++;
        }
      }

      return RestoreResult(
        success: true,
        restoredCount: restoredCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        dataType: 'products',
      );
    } catch (e) {
      debugPrint('خطأ في استعادة المنتجات: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة المنتجات: خطأ غير محدد',
      );
    }
  }

  /// استعادة المخزون فقط
  Future<RestoreResult> restoreInventoryOnly(
    String filePath, {
    bool mergeData = false,
  }) async {
    try {
      final BackupValidationResult validation =
          await BackupService.validateBackupFile(filePath);
      if (!validation.isValid) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير صحيح',
        );
      }

      final File file = File(filePath);
      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(json.decode(content) as Map);

      final Map<String, dynamic> backupData =
          Map<String, dynamic>.from(data['data'] as Map);
      final List<dynamic> inventoryData =
          List<dynamic>.from(backupData['inventory'] as List? ?? <dynamic>[]);

      int restoredCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (final Map<String, dynamic> itemData
          in inventoryData.cast<Map<String, dynamic>>()) {
        try {
          final InventoryItem? item =
              DataConversionService.convertMapToInventoryItem(itemData);
          if (item == null) {
            throw Exception('تعذر تحويل البيانات إلى عنصر مخزون');
          }

          if (!mergeData) {
            // التحقق من وجود العنصر
            final bool exists =
                await _inventoryProvider.checkIfInventoryNameExists(item.name);
            if (exists) {
              skippedCount++;
              continue;
            }
          }

          await _inventoryProvider.addInventoryItem(item);
          restoredCount++;
        } on Exception catch (_) {
          debugPrint('خطأ في استعادة عنصر المخزون: خطأ غير محدد');
          errorCount++;
        }
      }

      return RestoreResult(
        success: true,
        restoredCount: restoredCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        dataType: 'inventory',
      );
    } catch (e) {
      debugPrint('خطأ في استعادة المخزون: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة المخزون: خطأ غير محدد',
      );
    }
  }

  /// استعادة إعدادات التنبيهات
  static Future<RestoreResult> restoreAlertSettings(String filePath) async {
    try {
      final File file = File(filePath);
      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(json.decode(content) as Map);

      final Map<String, dynamic> backupData =
          Map<String, dynamic>.from(data['data'] as Map);
      final Map<String, dynamic> alertSettings = Map<String, dynamic>.from(
          backupData['alert_settings'] as Map? ?? <dynamic, dynamic>{});

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      int restoredCount = 0;

      for (final MapEntry<String, dynamic> entry in alertSettings.entries) {
        try {
          final String key = entry.key;
          final dynamic value = entry.value;

          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List<String>) {
            await prefs.setStringList(key, value);
          }

          restoredCount++;
        } on Exception catch (_) {
          debugPrint('خطأ في استعادة إعداد التنبيه: ${entry.key}');
        }
      }

      return RestoreResult(
        success: true,
        restoredCount: restoredCount,
        dataType: 'alert_settings',
      );
    } catch (e) {
      debugPrint('خطأ في استعادة إعدادات التنبيهات: خطأ غير محدد');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة إعدادات التنبيهات: خطأ غير محدد',
      );
    }
  }

  /// الحصول على تاريخ عمليات الاستعادة
  static Future<List<RestoreHistory>> getRestoreHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_restoreHistoryKey);

      if (historyJson == null || historyJson.isEmpty) {
        return <RestoreHistory>[];
      }

      final List<dynamic> historyData =
          List<dynamic>.from(json.decode(historyJson) as List);

      // التحقق من صحة البيانات قبل التحويل
      final List<RestoreHistory> history = <RestoreHistory>[];
      for (final dynamic data in historyData) {
        try {
          if (data is Map<String, dynamic>) {
            history.add(RestoreHistory.fromMap(data));
          } else {
            debugPrint('⚠️ بيانات غير صالحة في تاريخ الاستعادة: $data');
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في تحويل عنصر من تاريخ الاستعادة: $e');
          // تجاهل العنصر التالف والمتابعة
        }
      }

      return history;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على تاريخ الاستعادة: $e');
      // في حالة الخطأ، احذف البيانات التالفة
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove(_restoreHistoryKey);
        debugPrint('🗑️ تم حذف تاريخ الاستعادة التالف');
      } catch (deleteError) {
        debugPrint('❌ فشل في حذف تاريخ الاستعادة التالف: $deleteError');
      }
      return <RestoreHistory>[];
    }
  }

  /// حذف تاريخ عمليات الاستعادة
  static Future<void> clearRestoreHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restoreHistoryKey);
      debugPrint('تم حذف تاريخ عمليات الاستعادة');
    } catch (e) {
      debugPrint('خطأ في حذف تاريخ الاستعادة: خطأ غير محدد');
    }
  }

  /// التحقق من توافق النسخة الاحتياطية
  static Future<CompatibilityResult> checkCompatibility(String filePath) async {
    try {
      final BackupValidationResult validation =
          await BackupService.validateBackupFile(filePath);
      if (!validation.isValid) {
        return CompatibilityResult(
          isCompatible: false,
          error: validation.error ?? 'ملف غير صحيح',
        );
      }

      final File file = File(filePath);
      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(json.decode(content) as Map);

      final String? version = data['version'] as String?;
      final String? appVersion = data['app_version'] as String?;

      // التحقق من التوافق (يمكن تخصيص هذا المنطق)
      const bool isCompatible = true;
      String? warning;

      if (version != null && version != '1.0') {
        warning = 'النسخة الاحتياطية من إصدار مختلف ($version)';
      }

      if (appVersion != null && appVersion != '1.1.0') {
        warning = 'النسخة الاحتياطية من تطبيق إصدار مختلف ($appVersion)';
      }

      return CompatibilityResult(
        isCompatible: isCompatible,
        version: version,
        appVersion: appVersion,
        warning: warning,
        dataType: validation.type,
        dataCount: validation.dataCount,
      );
    } catch (e) {
      debugPrint('خطأ في التحقق من التوافق: خطأ غير محدد');
      return CompatibilityResult(
        isCompatible: false,
        error: 'خطأ في قراءة الملف: خطأ غير محدد',
      );
    }
  }

  // ========== الدوال المساعدة ==========

  /// استعادة البيانات حسب النوع
  Future<RestoreResult> _restoreData(
      Map<String, dynamic> data, bool mergeData) async {
    final String type = data['type'] as String;
    final Map<String, dynamic> backupData =
        data['data'] as Map<String, dynamic>;

    int totalRestored = 0;
    int totalSkipped = 0;
    int totalErrors = 0;
    final List<String> errors = <String>[];

    switch (type) {
      case 'full_backup':
        // استعادة المنتجات
        if (backupData.containsKey('products')) {
          final RestoreResult productsResult = await _restoreProducts(
            backupData['products'] as List<dynamic>,
            mergeData,
          );
          totalRestored += productsResult.restoredCount ?? 0;
          totalSkipped += productsResult.skippedCount ?? 0;
          totalErrors += productsResult.errorCount ?? 0;
          if (productsResult.error != null) {
            errors.add('المنتجات: ${productsResult.error}');
          }
        }

        // استعادة المخزون
        if (backupData.containsKey('inventory')) {
          final RestoreResult inventoryResult = await _restoreInventory(
            backupData['inventory'] as List<dynamic>,
            mergeData,
          );
          totalRestored += inventoryResult.restoredCount ?? 0;
          totalSkipped += inventoryResult.skippedCount ?? 0;
          totalErrors += inventoryResult.errorCount ?? 0;
          if (inventoryResult.error != null) {
            errors.add('المخزون: ${inventoryResult.error}');
          }
        }

        // استعادة إعدادات التنبيهات
        if (backupData.containsKey('alert_settings')) {
          final RestoreResult settingsResult = await _restoreAlertSettings(
            backupData['alert_settings'] as Map<String, dynamic>,
          );
          totalRestored += settingsResult.restoredCount ?? 0;
          if (settingsResult.error != null) {
            errors.add('الإعدادات: ${settingsResult.error}');
          }
        }
        break;

      case 'products_only':
        final RestoreResult productsResult = await _restoreProducts(
          backupData['products'] as List<dynamic>,
          mergeData,
        );
        totalRestored += productsResult.restoredCount ?? 0;
        totalSkipped += productsResult.skippedCount ?? 0;
        totalErrors += productsResult.errorCount ?? 0;
        if (productsResult.error != null) {
          errors.add(productsResult.error!);
        }
        break;

      case 'inventory_only':
        final RestoreResult inventoryResult = await _restoreInventory(
          backupData['inventory'] as List<dynamic>,
          mergeData,
        );
        totalRestored += inventoryResult.restoredCount ?? 0;
        totalSkipped += inventoryResult.skippedCount ?? 0;
        totalErrors += inventoryResult.errorCount ?? 0;
        if (inventoryResult.error != null) {
          errors.add(inventoryResult.error!);
        }
        break;
    }

    return RestoreResult(
      success: totalErrors == 0,
      restoredCount: totalRestored,
      skippedCount: totalSkipped,
      errorCount: totalErrors,
      error: errors.isNotEmpty ? errors.join('; ') : null,
      dataType: type,
    );
  }

  /// استعادة المنتجات
  Future<RestoreResult> _restoreProducts(
      List<dynamic> productsData, bool mergeData) async {
    int restoredCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    for (final Map<String, dynamic> productData
        in productsData.cast<Map<String, dynamic>>()) {
      try {
        final Product? product =
            DataConversionService.convertMapToProduct(productData);
        if (product == null) throw Exception('تعذر تحويل البيانات إلى منتج');

        if (!mergeData) {
          final bool exists =
              await _productProvider.checkIfProductNameExists(product.name);
          if (exists) {
            skippedCount++;
            continue;
          }
        }

        await _productProvider.addProduct(product);
        restoredCount++;
      } catch (e) {
        debugPrint('خطأ في استعادة منتج: خطأ غير محدد');
        errorCount++;
      }
    }

    return RestoreResult(
      success: errorCount == 0,
      restoredCount: restoredCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
    );
  }

  /// استعادة المخزون
  Future<RestoreResult> _restoreInventory(
      List<dynamic> inventoryData, bool mergeData) async {
    int restoredCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    for (final Map<String, dynamic> itemData
        in inventoryData.cast<Map<String, dynamic>>()) {
      try {
        final InventoryItem? item =
            DataConversionService.convertMapToInventoryItem(itemData);
        if (item == null) throw Exception('تعذر تحويل البيانات إلى عنصر مخزون');

        if (!mergeData) {
          final bool exists =
              await _inventoryProvider.checkIfInventoryNameExists(item.name);
          if (exists) {
            skippedCount++;
            continue;
          }
        }

        await _inventoryProvider.addInventoryItem(item);
        restoredCount++;
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          userAction: 'استعادة عنصر مخزون في RestoreService',
          context: <String, dynamic>{
            'operation': '_restoreInventory',
            'service': 'RestoreService',
            'itemData': itemData,
            'mergeData': mergeData,
          },
        );
        debugPrint('خطأ في استعادة عنصر المخزون: خطأ غير محدد');
        errorCount++;
      }
    }

    return RestoreResult(
      success: errorCount == 0,
      restoredCount: restoredCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
    );
  }

  /// استعادة إعدادات التنبيهات
  static Future<RestoreResult> _restoreAlertSettings(
      Map<String, dynamic> alertSettings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int restoredCount = 0;
    int errorCount = 0;

    for (final MapEntry<String, dynamic> entry in alertSettings.entries) {
      try {
        final String key = entry.key;
        final dynamic value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }

        restoredCount++;
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          userAction: 'استعادة إعداد تنبيه في RestoreService',
          context: <String, dynamic>{
            'operation': '_restoreAlertSettings',
            'service': 'RestoreService',
            'key': entry.key,
            'value': entry.value,
          },
        );
        debugPrint('خطأ في استعادة إعداد التنبيه: ${entry.key}');
        errorCount++;
      }
    }

    return RestoreResult(
      success: errorCount == 0,
      restoredCount: restoredCount,
      errorCount: errorCount,
    );
  }

  /// تسجيل عملية الاستعادة
  static Future<void> _recordRestoreOperation(
    String filePath,
    RestoreResult result,
    String? backupFilePath,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_restoreHistoryKey);

      final List<RestoreHistory> history = historyJson != null
          ? List<dynamic>.from(json.decode(historyJson) as List)
              .map((data) =>
                  RestoreHistory.fromMap(data as Map<String, dynamic>))
              .toList()
          : <RestoreHistory>[];

      history.add(RestoreHistory(
        filePath: filePath,
        timestamp: DateTime.now(),
        success: result.success,
        restoredCount: result.restoredCount ?? 0,
        skippedCount: result.skippedCount ?? 0,
        errorCount: result.errorCount ?? 0,
        backupFilePath: backupFilePath,
        dataType: result.dataType,
      ));

      // الاحتفاظ بآخر 50 عملية فقط
      if (history.length > 50) {
        history.removeRange(0, history.length - 50);
      }

      // تحويل RestoreHistory إلى Map قبل JSON encoding
      final List<Map<String, dynamic>> historyMaps =
          history.map((RestoreHistory h) => h.toMap()).toList();
      await prefs.setString(_restoreHistoryKey, json.encode(historyMaps));
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        userAction: 'تسجيل عملية الاستعادة في RestoreService',
        context: <String, dynamic>{
          'operation': '_recordRestoreOperation',
          'service': 'RestoreService',
          'filePath': filePath,
          'backupFilePath': backupFilePath,
        },
      );
      debugPrint('خطأ في تسجيل عملية الاستعادة: خطأ غير محدد');
    }
  }

  // ========== دوال ثابتة للتوافق مع الكود الحالي ==========

  /// إنشاء مثيل من الخدمة مع المزودات المطلوبة
  static RestoreService create({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) =>
      RestoreService(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

  /// استعادة البيانات من ملف النسخة الاحتياطية (دالة ثابتة للتوافق)
  static Future<RestoreResult> restoreFromFileStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String filePath,
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    final RestoreService service = RestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.restoreFromFile(
      filePath,
      mergeData: mergeData,
      backupBeforeRestore: backupBeforeRestore,
    );
  }

  /// استعادة البيانات من ملف محدد من قبل المستخدم (دالة ثابتة للتوافق)
  static Future<RestoreResult> restoreFromUserFileStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    final RestoreService service = RestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.restoreFromUserFile(
      mergeData: mergeData,
      backupBeforeRestore: backupBeforeRestore,
    );
  }

  /// استعادة البيانات من السحابة (دالة ثابتة للتوافق)
  static Future<RestoreResult> restoreFromCloudStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String cloudUrl,
    bool mergeData = false,
    bool backupBeforeRestore = true,
  }) async {
    final RestoreService service = RestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.restoreFromCloud(
      cloudUrl,
      mergeData: mergeData,
      backupBeforeRestore: backupBeforeRestore,
    );
  }

  /// استعادة المنتجات فقط (دالة ثابتة للتوافق)
  static Future<RestoreResult> restoreProductsOnlyStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String filePath,
    bool mergeData = false,
  }) async {
    final RestoreService service = RestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.restoreProductsOnly(
      filePath,
      mergeData: mergeData,
    );
  }

  /// استعادة المخزون فقط (دالة ثابتة للتوافق)
  static Future<RestoreResult> restoreInventoryOnlyStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String filePath,
    bool mergeData = false,
  }) async {
    final RestoreService service = RestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.restoreInventoryOnly(
      filePath,
      mergeData: mergeData,
    );
  }
}

/// نتيجة عملية الاستعادة
class RestoreResult {
  RestoreResult({
    required this.success,
    this.restoredCount,
    this.skippedCount,
    this.errorCount,
    this.error,
    this.dataType,
  });
  final bool success;
  final int? restoredCount;
  final int? skippedCount;
  final int? errorCount;
  final String? error;
  final String? dataType;

  String get summary {
    if (!success) {
      return 'فشل في الاستعادة: $error';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.write('تمت الاستعادة بنجاح\n');
    buffer.write('تم استعادة: ${restoredCount ?? 0} عنصر\n');

    if ((skippedCount ?? 0) > 0) {
      buffer.write('تم تخطي: $skippedCount عنصر (موجود مسبقاً)\n');
    }

    if ((errorCount ?? 0) > 0) {
      buffer.write('أخطاء: $errorCount عنصر\n');
    }

    return buffer.toString();
  }
}

/// نتيجة التحقق من التوافق
class CompatibilityResult {
  CompatibilityResult({
    required this.isCompatible,
    this.version,
    this.appVersion,
    this.warning,
    this.error,
    this.dataType,
    this.dataCount,
  });
  final bool isCompatible;
  final String? version;
  final String? appVersion;
  final String? warning;
  final String? error;
  final String? dataType;
  final int? dataCount;
}

/// تاريخ عملية الاستعادة
class RestoreHistory {
  RestoreHistory({
    required this.filePath,
    required this.timestamp,
    required this.success,
    required this.restoredCount,
    required this.skippedCount,
    required this.errorCount,
    this.backupFilePath,
    this.dataType,
  });

  factory RestoreHistory.fromMap(Map<String, dynamic> map) => RestoreHistory(
        filePath: map['filePath'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        success: map['success'] as bool,
        restoredCount: map['restoredCount'] as int,
        skippedCount: map['skippedCount'] as int,
        errorCount: map['errorCount'] as int,
        backupFilePath: map['backupFilePath'] as String?,
        dataType: map['dataType'] as String?,
      );
  final String filePath;
  final DateTime timestamp;
  final bool success;
  final int restoredCount;
  final int skippedCount;
  final int errorCount;
  final String? backupFilePath;
  final String? dataType;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'filePath': filePath,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        'restoredCount': restoredCount,
        'skippedCount': skippedCount,
        'errorCount': errorCount,
        'backupFilePath': backupFilePath,
        'dataType': dataType,
      };

  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm').format(timestamp);

  String get fileName => filePath.split('/').last;
}
