import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../providers/riverpod/stream_product_riverpod_provider.dart';

/// خدمة استعادة البيانات الشاملة
class RestoreService {
  static const String _restoreHistoryKey = 'restore_history';

  /// استعادة من ملف محدد
  static Future<RestoreResult> restoreFromFileStatic({
    required WidgetRef ref,
    required String filePath,
    bool backupBeforeRestore = true,
  }) async {
    try {
      // إنشاء نسخة احتياطية قبل الاستعادة إذا طُلب ذلك
      if (backupBeforeRestore) {
        // يمكن إضافة منطق إنشاء نسخة احتياطية هنا
        debugPrint('إنشاء نسخة احتياطية قبل الاستعادة...');
      }

      final File file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          error: 'الملف غير موجود: $filePath',
        );
      }

      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          jsonDecode(content) as Map<String, dynamic>;

      int restoredCount = 0;
      const int skippedCount = 0;
      int errorCount = 0;

      // استعادة المنتجات
      if (data.containsKey('products')) {
        final List<dynamic> productsData = data['products'] as List<dynamic>;
        for (final dynamic productData in productsData) {
          try {
            final Map<String, dynamic> productMap =
                productData as Map<String, dynamic>;
            final Product product = Product(
              id: productMap['id'] as String?,
              name: productMap['name'] as String? ?? '',
              wholesalePrice:
                  (productMap['wholesalePrice'] as num?)?.toInt() ?? 0,
              retailPrice: (productMap['retailPrice'] as num?)?.toInt() ?? 0,
              savedAt:
                  DateTime.tryParse(productMap['savedAt'] as String? ?? '') ??
                      DateTime.now(),
              lastModified: DateTime.tryParse(
                  productMap['lastModified'] as String? ?? ''),
              description: productMap['description'] as String?,
              barcode: productMap['barcode'] as String?,
              category: productMap['category'] as String?,
            );
            await ref
                .read(productsControllerProvider.notifier)
                .addProduct(product);
            restoredCount++;
          } catch (e) {
            debugPrint('خطأ في استعادة منتج: $e');
            errorCount++;
          }
        }
      }

      // استعادة المخزون
      if (data.containsKey('inventory')) {
        final List<dynamic> inventoryData = data['inventory'] as List<dynamic>;
        for (final dynamic inventoryItemData in inventoryData) {
          try {
            final Map<String, dynamic> itemMap =
                inventoryItemData as Map<String, dynamic>;
            final InventoryItem item = InventoryItem(
              id: itemMap['id'] as String?,
              name: itemMap['name'] as String? ?? '',
              barcode: itemMap['barcode'] as String?,
              wholesalePrice: (itemMap['wholesalePrice'] as num?)?.toInt() ?? 0,
              retailPrice: (itemMap['retailPrice'] as num?)?.toInt() ?? 0,
              quantity: itemMap['quantity'] as int? ?? 0,
              originalQuantity: itemMap['originalQuantity'] as int? ?? 0,
              addedDate:
                  DateTime.tryParse(itemMap['addedDate'] as String? ?? '') ??
                      DateTime.now(),
              addedTime:
                  DateTime.tryParse(itemMap['addedTime'] as String? ?? '') ??
                      DateTime.now(),
              expiryDate:
                  DateTime.tryParse(itemMap['expiryDate'] as String? ?? ''),
              lastModified:
                  DateTime.tryParse(itemMap['lastModified'] as String? ?? ''),
            );
            await ref
                .read(inventoryControllerProvider.notifier)
                .addInventoryItem(item);
            restoredCount++;
          } catch (e) {
            debugPrint('خطأ في استعادة عنصر مخزون: $e');
            errorCount++;
          }
        }
      }

      // تسجيل عملية الاستعادة
      await _recordRestoreHistory(
        fileName: file.path.split('/').last,
        restoredCount: restoredCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        success: errorCount == 0,
      );

      return RestoreResult(
        success: errorCount == 0,
        restoredCount: restoredCount,
        errorCount: errorCount,
        summary: 'تم استعادة $restoredCount عنصر بنجاح',
        error: errorCount > 0 ? 'حدث $errorCount خطأ أثناء الاستعادة' : null,
      );
    } catch (e) {
      debugPrint('خطأ في استعادة البيانات: $e');
      return RestoreResult(
        success: false,
        error: 'خطأ في استعادة البيانات: $e',
      );
    }
  }

  /// استعادة من ملف المستخدم
  static Future<RestoreResult> restoreFromUserFileStatic({
    required WidgetRef ref,
    bool backupBeforeRestore = true,
  }) async {
    // في التطبيق الحقيقي، هنا سيتم فتح file picker
    // للآن سنقوم بإرجاع رسالة خطأ
    return RestoreResult(
      success: false,
      error: 'ميزة اختيار الملف غير متاحة حالياً',
    );
  }

  /// الحصول على تاريخ عمليات الاستعادة
  static Future<List<RestoreHistory>> getRestoreHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_restoreHistoryKey);

      if (historyJson == null) return <RestoreHistory>[];

      final List<dynamic> historyList =
          jsonDecode(historyJson) as List<dynamic>;
      return historyList
          .map<RestoreHistory>((item) =>
              RestoreHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في تحميل تاريخ الاستعادة: $e');
      return <RestoreHistory>[];
    }
  }

  /// مسح تاريخ الاستعادة
  static Future<void> clearRestoreHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restoreHistoryKey);
    } catch (e) {
      debugPrint('خطأ في مسح تاريخ الاستعادة: $e');
    }
  }

  /// تسجيل عملية الاستعادة في التاريخ
  static Future<void> _recordRestoreHistory({
    required String fileName,
    required int restoredCount,
    required int skippedCount,
    required int errorCount,
    required bool success,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<RestoreHistory> history = await getRestoreHistory();

      final RestoreHistory newEntry = RestoreHistory(
        fileName: fileName,
        restoredCount: restoredCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        success: success,
        dateTime: DateTime.now(),
      );

      history.insert(0, newEntry);

      // الاحتفاظ بآخر 50 عملية فقط
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      final String historyJson = jsonEncode(
        history.map((RestoreHistory item) => item.toJson()).toList(),
      );

      await prefs.setString(_restoreHistoryKey, historyJson);
    } catch (e) {
      debugPrint('خطأ في تسجيل تاريخ الاستعادة: $e');
    }
  }
}

/// نتيجة عملية الاستعادة
class RestoreResult {

  RestoreResult({
    required this.success,
    this.restoredCount = 0,
    this.skippedCount = 0,
    this.errorCount = 0,
    this.summary = '',
    this.error,
  });
  final bool success;
  final int restoredCount;
  final int skippedCount;
  final int errorCount;
  final String summary;
  final String? error;
}

/// تاريخ عملية الاستعادة
class RestoreHistory {

  RestoreHistory({
    required this.fileName,
    required this.restoredCount,
    required this.skippedCount,
    required this.errorCount,
    required this.success,
    required this.dateTime,
  });

  factory RestoreHistory.fromJson(Map<String, dynamic> json) => RestoreHistory(
        fileName: json['fileName'] as String,
        restoredCount: json['restoredCount'] as int,
        skippedCount: json['skippedCount'] as int,
        errorCount: json['errorCount'] as int,
        success: json['success'] as bool,
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
  final String fileName;
  final int restoredCount;
  final int skippedCount;
  final int errorCount;
  final bool success;
  final DateTime dateTime;

  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fileName': fileName,
        'restoredCount': restoredCount,
        'skippedCount': skippedCount,
        'errorCount': errorCount,
        'success': success,
        'dateTime': dateTime.toIso8601String(),
      };
}
