import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../services/error_handler_service.dart';
import '../services/server_timestamp_service.dart';
import '../services/sync_state_service.dart';
import '../services/unified_sync_manager.dart';

/// مستودع موحد - مصدر الحقيقة الوحيد للبيانات
/// يدمج قاعدة البيانات المحلية (Drift) مع Firestore
class UnifiedRepository {
  factory UnifiedRepository() => _instance;
  UnifiedRepository._internal() {
    debugPrint('🔧 UnifiedRepository instance created');
  }
  static final UnifiedRepository _instance = UnifiedRepository._internal();

  final AppDatabase _localDb = AppDatabase.instance;

  // Expose for StreamSyncService
  AppDatabase get localDb => _localDb;
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;

  // ========== Streams للبيانات ==========

  /// Stream للمنتجات من قاعدة البيانات المحلية
  Stream<List<Product>> get productsStream {
    try {
      return _localDb
          .select(_localDb.productsTable)
          .watch()
          .map((List<ProductsTableData> rows) => rows
              .map((ProductsTableData row) => Product(
                    id: row.id,
                    name: row.name,
                    wholesalePrice: row.wholesalePrice,
                    retailPrice: row.retailPrice,
                    savedAt: safeParseDateTime(row.savedAt),
                    lastModified: safeParseDateTime(row.lastModified),

                    // ✅ إضافة جميع الحقول الجديدة
                    description: row.description,
                    barcode: row.barcode,
                    category: row.category,
                    supplier: row.supplier,
                    status: _parseProductStatus(row.status),
                    images: row.images != null
                        ? _parseStringList(row.images!)
                        : null,
                    tags: row.tags != null ? _parseStringList(row.tags!) : null,
                    weight: row.weight,
                    dimensions: row.dimensions,
                    minimumStock: row.minimumStock,
                    maximumStock: row.maximumStock,
                    taxRate: row.taxRate,
                    discountRate: row.discountRate,
                    isActive: row.isActive,
                    notes: row.notes,
                  ))
              .toList())
          .handleError((Object error) {
        debugPrint('❌ خطأ في productsStream: $error');
        // إرجاع قائمة فارغة في حالة الخطأ
        return <Product>[];
      });
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء productsStream: $e');
      // إرجاع stream فارغ في حالة الخطأ
      return Stream<List<Product>>.value(<Product>[]);
    }
  }

  /// Stream للمخزون من قاعدة البيانات المحلية
  Stream<List<InventoryItem>> get inventoryStream {
    try {
      return _localDb
          .select(_localDb.inventoryTable)
          .watch()
          .map((List<InventoryTableData> rows) {
        try {
          return rows
              .map((InventoryTableData row) {
                try {
                  return InventoryItem(
                    id: row.id,
                    name: row.name,
                    barcode: row.barcode,
                    wholesalePrice: row.wholesalePrice,
                    retailPrice: row.retailPrice,
                    quantity: row.quantity,
                    originalQuantity: row.originalQuantity,
                    addedDate: safeParseDateTime(row.addedDate),
                    addedTime: safeParseDateTime(row.addedTime),
                  );
                } catch (e) {
                  debugPrint('❌ خطأ في تحويل صف المخزون: $e');
                  return null;
                }
              })
              .where((InventoryItem? item) => item != null)
              .cast<InventoryItem>()
              .toList();
        } catch (e) {
          debugPrint('❌ خطأ في معالجة صفوف المخزون: $e');
          return <InventoryItem>[];
        }
      }).handleError((Object error) {
        debugPrint('❌ خطأ في inventoryStream: $error');
        // إرجاع قائمة فارغة في حالة الخطأ
        return <InventoryItem>[];
      });
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء inventoryStream: $e');
      // إرجاع stream فارغ في حالة الخطأ
      return Stream<List<InventoryItem>>.value(<InventoryItem>[]);
    }
  }

  // ========== عمليات المنتجات ==========

  /// تحويل آمن للقيم إلى int
  int safeParseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final int? parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    if (value is num) return value.toInt();
    return 0;
  }

  /// تحويل آمن للتواريخ
  DateTime safeParseDateTime(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // التحقق من تنسيق الوقت فقط (HH:mm:ss)
        if (value.contains(':') &&
            !value.contains('T') &&
            !value.contains('-')) {
          // تنسيق وقت فقط - إنشاء DateTime مع التاريخ الحالي
          final List<String> parts = value.split(':');
          if (parts.length >= 2) {
            final int hour = int.tryParse(parts[0]) ?? 0;
            final int minute = int.tryParse(parts[1]) ?? 0;
            final int second =
                parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
            final DateTime now = DateTime.now();
            return DateTime(now.year, now.month, now.day, hour, minute, second);
          }
        }
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('❌ خطأ في تحليل التاريخ: $value - $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// تحويل النص إلى ProductStatus
  ProductStatus _parseProductStatus(String? status) {
    switch (status) {
      case 'active':
        return ProductStatus.active;
      case 'inactive':
        return ProductStatus.inactive;
      case 'discontinued':
        return ProductStatus.discontinued;
      case 'outOfStock':
        return ProductStatus.outOfStock;
      default:
        return ProductStatus.active;
    }
  }

  /// تحويل JSON string إلى List<String>
  List<String>? _parseStringList(String jsonString) {
    try {
      if (jsonString.isEmpty) return null;
      final dynamic parsed = jsonDecode(jsonString);
      if (parsed is List) {
        return parsed.cast<String>();
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في تحليل JSON string: $jsonString - $e');
      return null;
    }
  }

  /// إضافة منتج جديد مع ضمان اتساق البيانات
  Future<String> addProduct(Product product) async {
    try {
      final String id =
          product.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final Product productWithId = product.copyWith(id: id);

      // إضافة المنتج مباشرة إلى قاعدة البيانات المحلية
      final ProductsTableCompanion productCompanion = ProductsTableCompanion(
        id: Value(id),
        name: Value(productWithId.name),
        wholesalePrice: Value(productWithId.wholesalePrice),
        retailPrice: Value(productWithId.retailPrice),
        savedAt: Value(productWithId.savedAt.toIso8601String()),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().toIso8601String()),
      );
      await _localDb.upsertProduct(productCompanion);

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      await _addToSyncQueue(
        'addProduct',
        'products',
        id,
        productWithId.toMap(),
      );

      // ✅ تفعيل المزامنة الفورية
      await _triggerImmediateSync();

      debugPrint('✅ تم إضافة المنتج محلياً وإضافته لطابور المزامنة: $id');
      return id;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إضافة منتج في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'addProduct',
          'productName': product.name,
        },
      );
      rethrow;
    }
  }

  /// تحديث منتج موجود مع ضمان اتساق البيانات
  Future<void> updateProduct(Product product) async {
    try {
      if (product.id == null) throw ArgumentError('معرف المنتج مطلوب');

      // تحديث المنتج مباشرة في قاعدة البيانات المحلية
      final ProductsTableCompanion productCompanion = ProductsTableCompanion(
        id: Value(product.id!),
        name: Value(product.name),
        wholesalePrice: Value(product.wholesalePrice),
        retailPrice: Value(product.retailPrice),
        savedAt: Value(product.savedAt.toIso8601String()),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().toIso8601String()),
      );
      await _localDb.upsertProduct(productCompanion);

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      await _addToSyncQueue(
        'updateProduct',
        'products',
        product.id!,
        product.toMap(),
      );

      // ✅ تفعيل المزامنة الفورية
      await _triggerImmediateSync();

      debugPrint(
          '✅ تم تحديث المنتج محلياً وإضافته لطابور المزامنة: ${product.id}');
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تحديث منتج في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'updateProduct',
          'productId': product.id,
        },
      );
      rethrow;
    }
  }

  // ========== عمليات المخزون ==========

  /// إضافة عنصر مخزون جديد مع ضمان اتساق البيانات
  Future<String> addInventoryItem(InventoryItem item) async {
    try {
      final String id =
          item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final InventoryItem itemWithId = item.copyWith(id: id);

      // إضافة عنصر المخزون مباشرة إلى قاعدة البيانات المحلية
      final InventoryTableCompanion itemCompanion = InventoryTableCompanion(
        id: Value(id),
        name: Value(itemWithId.name),
        barcode: Value(itemWithId.barcode),
        wholesalePrice: Value(itemWithId.wholesalePrice),
        retailPrice: Value(itemWithId.retailPrice),
        quantity: Value(itemWithId.quantity),
        originalQuantity: Value(itemWithId.originalQuantity),
        addedDate: Value(itemWithId.addedDate.toIso8601String()),
        addedTime: Value(itemWithId.addedTime.toIso8601String()),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().toIso8601String()),
      );
      await _localDb.upsertInventoryItem(itemCompanion);

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      // ✅ إرسال إلى quantities فقط (وليس inventory) عند إضافة عنصر مخزون جديد
      await _addToSyncQueue(
        'addInventoryItem',
        'quantities',
        id,
        itemWithId.toMap(),
      );

      // ✅ إضافة مزامنة فورية (سيتم إصلاح معرف المستخدم في ServiceInitializer)
      await _triggerImmediateSync();

      debugPrint('✅ تم إضافة عنصر المخزون محلياً وإضافته لطابور المزامنة: $id');
      return id;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إضافة عنصر مخزون في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'addInventoryItem',
          'itemName': item.name,
        },
      );
      rethrow;
    }
  }

  /// تحديث عنصر مخزون موجود مع ضمان اتساق البيانات
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      if (item.id == null) throw ArgumentError('معرف عنصر المخزون مطلوب');

      // تحديث عنصر المخزون مباشرة في قاعدة البيانات المحلية
      final InventoryTableCompanion itemCompanion = InventoryTableCompanion(
        id: Value(item.id!),
        name: Value(item.name),
        barcode: Value(item.barcode),
        wholesalePrice: Value(item.wholesalePrice),
        retailPrice: Value(item.retailPrice),
        quantity: Value(item.quantity),
        originalQuantity: Value(item.originalQuantity),
        addedDate: Value(item.addedDate.toIso8601String()),
        addedTime: Value(item.addedTime.toIso8601String()),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().toIso8601String()),
      );
      await _localDb.upsertInventoryItem(itemCompanion);

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      await _addToSyncQueue(
        'updateInventoryItem',
        'quantities',
        item.id!,
        item.toMap(),
      );

      // ✅ تفعيل المزامنة الفورية
      await _triggerImmediateSync();

      debugPrint(
          '✅ تم تحديث عنصر المخزون محلياً وإضافته لطابور المزامنة: ${item.id}');
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تحديث عنصر مخزون في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'updateInventoryItem',
          'itemId': item.id,
        },
      );
      rethrow;
    }
  }

  /// حذف عنصر مخزون مع ضمان اتساق البيانات
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      // حذف عنصر المخزون مباشرة من قاعدة البيانات المحلية
      await (_localDb.delete(_localDb.inventoryTable)
            ..where(($InventoryTableTable t) => t.id.equals(itemId)))
          .go();

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      await _addToSyncQueue(
        'deleteInventoryItem',
        'inventory',
        itemId,
        <String, dynamic>{'id': itemId, 'deleted': true},
      );

      debugPrint(
          '✅ تم حذف عنصر المخزون محلياً وإضافته لطابور المزامنة: $itemId');

      // ✅ NEW: Trigger immediate sync for delete operations
      _triggerImmediateSyncAfterDelete();
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'حذف عنصر مخزون في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'deleteInventoryItem',
          'itemId': itemId,
        },
      );
      rethrow;
    }
  }

  /// حذف منتج مع ضمان اتساق البيانات
  Future<void> deleteProduct(String productId) async {
    try {
      // حذف المنتج مباشرة من قاعدة البيانات المحلية
      await (_localDb.delete(_localDb.productsTable)
            ..where(($ProductsTableTable t) => t.id.equals(productId)))
          .go();

      // إضافة العملية إلى طابور المزامنة لإرسالها إلى Firestore
      await _addToSyncQueue(
        'deleteProduct',
        'products',
        productId,
        <String, dynamic>{'id': productId, 'deleted': true},
      );

      debugPrint('✅ تم حذف المنتج محلياً وإضافته لطابور المزامنة: $productId');

      // ✅ NEW: Trigger immediate sync for delete operations
      _triggerImmediateSyncAfterDelete();
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'حذف منتج في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'deleteProduct',
          'productId': productId,
        },
      );
      rethrow;
    }
  }

  // ========== طابور المزامنة ==========

  /// تحويل البيانات إلى قيم قابلة للتسلسل (إزالة FieldValue)
  Map<String, dynamic> _makeDataSerializable(Map<String, dynamic> data) {
    final Map<String, dynamic> serializableData = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value is firestore.FieldValue) {
        // تحويل FieldValue.serverTimestamp() إلى علامة خاصة
        if (value == firestore.FieldValue.serverTimestamp()) {
          serializableData[key] = '__SERVER_TIMESTAMP__';
        } else {
          // أنواع أخرى من FieldValue
          serializableData[key] = '__FIELD_VALUE__';
        }
      } else if (value is Map<String, dynamic>) {
        // معالجة متداخلة للخرائط
        serializableData[key] = _makeDataSerializable(value);
      } else if (value is List) {
        // معالجة القوائم
        serializableData[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _makeDataSerializable(item);
          } else if (item is firestore.FieldValue) {
            if (item == firestore.FieldValue.serverTimestamp()) {
              return '__SERVER_TIMESTAMP__';
            } else {
              return '__FIELD_VALUE__';
            }
          }
          return item;
        }).toList();
      } else {
        // القيم العادية
        serializableData[key] = value;
      }
    }

    return serializableData;
  }

  /// استعادة FieldValue من البيانات المسلسلة
  Map<String, dynamic> restoreFieldValues(Map<String, dynamic> data) {
    final Map<String, dynamic> restoredData = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value == '__SERVER_TIMESTAMP__') {
        // استعادة FieldValue.serverTimestamp()
        restoredData[key] = firestore.FieldValue.serverTimestamp();
      } else if (value == '__FIELD_VALUE__') {
        // استعادة FieldValue عام (يمكن تخصيصه حسب الحاجة)
        restoredData[key] = firestore.FieldValue.serverTimestamp();
      } else if (value is Map<String, dynamic>) {
        // معالجة متداخلة للخرائط
        restoredData[key] = restoreFieldValues(value);
      } else if (value is List) {
        // معالجة القوائم
        restoredData[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return restoreFieldValues(item);
          } else if (item == '__SERVER_TIMESTAMP__') {
            return firestore.FieldValue.serverTimestamp();
          } else if (item == '__FIELD_VALUE__') {
            return firestore.FieldValue.serverTimestamp();
          }
          return item;
        }).toList();
      } else {
        // القيم العادية
        restoredData[key] = value;
      }
    }

    return restoredData;
  }

  /// إضافة عملية إلى طابور المزامنة
  Future<void> _addToSyncQueue(String operation, String tableName,
      String recordId, Map<String, dynamic> data) async {
    try {
      // إضافة توقيتات الخادم الموثوقة
      final Map<String, dynamic> dataWithTimestamp =
          ServerTimestampService.updateDataWithServerTimestamp(data);

      // تحويل FieldValue إلى قيم قابلة للتسلسل
      final Map<String, dynamic> serializableData =
          _makeDataSerializable(dataWithTimestamp);

      // إضافة العملية إلى جدول العمليات
      final int result =
          await _localDb.addSyncOperation(SyncOperationsTableCompanion(
        operation: Value(operation),
        targetTable: Value(tableName),
        recordId: Value(recordId),
        data: Value(jsonEncode(serializableData)),
        timestamp: Value(DateTime.now().toIso8601String()),
        createdAt: Value(DateTime.now().toIso8601String()),
        isProcessed: const Value(false),
        retryCount: const Value(0),
      ));

      if (result == -1) {
        debugPrint(
            '⚠️ فشل في إضافة العملية إلى طابور المزامنة (اتصال قاعدة البيانات مغلق)');
      } else {
        debugPrint(
            '📋 تم إضافة العملية إلى طابور المزامنة: $operation - $recordId');
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إضافة العملية إلى طابور المزامنة: $e');
    }
  }

  /// إضافة عملية إلى طابور المزامنة (دالة عامة)
  Future<void> addToSyncQueue(String operation, String tableName,
      String recordId, Map<String, dynamic> data) async {
    await _addToSyncQueue(operation, tableName, recordId, data);
  }

  // ========== مزامنة البيانات من Firestore ==========

  /// مزامنة تفاضلية للبيانات من Firestore (جلب التغييرات فقط)
  Future<void> syncFromFirestore() async {
    try {
      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint('لا يوجد اتصال - لا يمكن المزامنة من Firestore');
        return;
      }

      // مزامنة المنتجات تفاضلياً
      await _syncProductsDelta();

      // مزامنة المخزون تفاضلياً
      await _syncInventoryDelta();

      debugPrint('✅ تم مزامنة البيانات من Firestore بنجاح');
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'مزامنة البيانات من Firestore في UnifiedRepository',
        context: <String, dynamic>{
          'operation': 'syncFromFirestore',
        },
      );
      debugPrint('❌ فشل في مزامنة البيانات من Firestore: $e');
    }
  }

  /// مزامنة تفاضلية للمنتجات
  Future<void> _syncProductsDelta() async {
    try {
      // الحصول على آخر وقت مزامنة للمنتجات
      final DateTime? lastSyncTime =
          await SyncStateService.getLastSync('products');

      // بناء استعلام Firestore باستخدام الخدمة الجديدة
      final firestore.Query<Map<String, dynamic>> query =
          ServerTimestampService.createDeltaQuery(
        _firestore.collection('products'),
        lastSyncTime,
      );

      if (lastSyncTime != null) {
        debugPrint('🔄 مزامنة تفاضلية للمنتجات منذ: $lastSyncTime');
      } else {
        debugPrint('🔄 مزامنة كاملة للمنتجات (أول مرة)');
      }

      // تنفيذ الاستعلام
      final firestore.QuerySnapshot<Map<String, dynamic>> snapshot =
          await query.get();

      debugPrint('📦 جلب ${snapshot.docs.length} منتج من Firestore');

      // معالجة كل مستند
      for (final firestore.QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;

        // إصلاح التوقيتات التالفة
        final Map<String, dynamic> repairedData =
            ServerTimestampService.repairTimestamps(data);

        // التحقق من صحة التوقيت
        final DateTime? lastModified = ServerTimestampService.convertToDateTime(
            repairedData['last_modified']);
        final String lastModifiedString =
            lastModified?.toIso8601String() ?? DateTime.now().toIso8601String();

        await _localDb.upsertProduct(ProductsTableCompanion(
          id: Value(doc.id),
          name: Value(repairedData['name']?.toString() ?? ''),
          wholesalePrice: Value(safeParseInt(
            repairedData['wholesalePrice'] ?? repairedData['wholesale_price'],
          )),
          retailPrice: Value(safeParseInt(
            repairedData['retailPrice'] ?? repairedData['retail_price'],
          )),
          savedAt: Value(safeParseDateTime(
            repairedData['savedAt'] ?? repairedData['saved_at'],
          ).toIso8601String()),
          isSynced: const Value(true),
          lastModified: Value(lastModifiedString),
        ));
      }

      // تحديث وقت آخر مزامنة
      await SyncStateService.setLastSync('products', DateTime.now());

      debugPrint('✅ تم مزامنة المنتجات بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة المنتجات: $e');
      rethrow;
    }
  }

  /// مزامنة تفاضلية للمخزون
  Future<void> _syncInventoryDelta() async {
    try {
      // الحصول على آخر وقت مزامنة للمخزون
      final DateTime? lastSyncTime =
          await SyncStateService.getLastSync('inventory');

      // بناء استعلام Firestore باستخدام الخدمة الجديدة
      final firestore.Query<Map<String, dynamic>> query =
          ServerTimestampService.createDeltaQuery(
        _firestore.collection('quantities'),
        lastSyncTime,
      );

      if (lastSyncTime != null) {
        debugPrint('🔄 مزامنة تفاضلية للمخزون منذ: $lastSyncTime');
      } else {
        debugPrint('🔄 مزامنة كاملة للمخزون (أول مرة)');
      }

      // تنفيذ الاستعلام
      final firestore.QuerySnapshot<Map<String, dynamic>> snapshot =
          await query.get();

      debugPrint('📦 جلب ${snapshot.docs.length} عنصر مخزون من Firestore');

      // معالجة كل مستند
      for (final firestore.QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;

        // إصلاح التوقيتات التالفة
        final Map<String, dynamic> repairedData =
            ServerTimestampService.repairTimestamps(data);

        // التحقق من صحة التوقيت
        final DateTime? lastModified = ServerTimestampService.convertToDateTime(
            repairedData['last_modified']);
        final String lastModifiedString =
            lastModified?.toIso8601String() ?? DateTime.now().toIso8601String();

        await _localDb.upsertInventoryItem(InventoryTableCompanion(
          id: Value(doc.id),
          name: Value(repairedData['name']?.toString() ?? ''),
          barcode: Value(repairedData['barcode']?.toString()),
          wholesalePrice: Value(safeParseInt(repairedData['wholesalePrice'])),
          retailPrice: Value(safeParseInt(repairedData['retailPrice'])),
          quantity: Value(safeParseInt(repairedData['quantity'])),
          originalQuantity:
              Value(safeParseInt(repairedData['originalQuantity'])),
          addedDate: Value(
              safeParseDateTime(repairedData['addedDate']).toIso8601String()),
          addedTime: Value(
              safeParseDateTime(repairedData['addedTime']).toIso8601String()),
          isSynced: const Value(true),
          lastModified: Value(lastModifiedString),
        ));
      }

      // تحديث وقت آخر مزامنة
      await SyncStateService.setLastSync('inventory', DateTime.now());

      debugPrint('✅ تم مزامنة المخزون بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة المخزون: $e');
      rethrow;
    }
  }

  // ========== دوال التحقق من الوجود ==========

  /// التحقق من وجود المنتج في Firestore وإضافته تلقائياً إذا لم يكن موجوداً
  Future<bool> ensureProductExistsInFirestore({
    required String itemId,
    required Product product,
    required int actualQuantity, // الكمية الفعلية من التبويب
  }) async {
    try {
      debugPrint(
          '🔍 التحقق من وجود المنتج في Firestore - itemId: $itemId, quantity: $actualQuantity');

      // التحقق من وجود المنتج في مجموعة quantities
      final firestore.DocumentSnapshot<Object?> quantitySnap =
          await _firestore.collection('quantities').doc(itemId).get();

      if (quantitySnap.exists) {
        debugPrint('✅ المنتج موجود في مجموعة quantities');
        return true;
      }

      // التحقق من وجود المنتج في مجموعة inventory
      final firestore.DocumentSnapshot<Object?> inventorySnap =
          await _firestore.collection('inventory').doc(itemId).get();

      if (inventorySnap.exists) {
        debugPrint('✅ المنتج موجود في مجموعة inventory');
        return true;
      }

      // المنتج غير موجود - لا يتم إنشاء quantities تلقائياً
      debugPrint('❌ المنتج غير موجود في Firestore - يجب إضافة المخزون أولاً');
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود المنتج: $e');
      return false;
    }
  }

  // ========== تنظيف الموارد ==========

  /// إغلاق الاتصالات
  Future<void> dispose() async {
    await _localDb.close();
  }

  /// تشغيل مزامنة فورية
  Future<void> _triggerImmediateSync() async {
    try {
      // التحقق من الاتصال بالإنترنت
      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('⚠️ لا يوجد اتصال بالإنترنت - تأجيل المزامنة');
        return;
      }

      debugPrint('🚀 بدء المزامنة الفورية...');

      // استخدام UnifiedSyncManager للمزامنة
      final UnifiedSyncManager syncManager = UnifiedSyncManager();
      await syncManager.syncPendingOperations();

      debugPrint('✅ تمت المزامنة الفورية بنجاح');
    } catch (e) {
      debugPrint('⚠️ خطأ في المزامنة الفورية: $e');
      // لا نرمي الخطأ لأن المزامنة الدورية ستعالجه لاحقاً
    }
  }

  /// تشغيل مزامنة فورية مع معرف المستخدم
  Future<void> triggerImmediateSyncWithUser(String userId) async {
    try {
      // التحقق من الاتصال
      final List<ConnectivityResult> connectivityResults =
          await Connectivity().checkConnectivity();
      // Broaden connectivity check to include Ethernet/VPN (not just mobile/wifi)
      final bool isOnline = connectivityResults.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (!isOnline) {
        debugPrint('⚠️ لا يوجد اتصال بالإنترنت - سيتم المزامنة لاحقاً');
        return;
      }

      // Ensure sync manager is initialized with the real user if needed
      final UnifiedSyncManager syncManager = UnifiedSyncManager();
      final Map<String, dynamic> syncInfo = syncManager.getSyncInfo();

      // التحقق من أن المدير مهيأ مع معرف المستخدم الحقيقي
      if (syncInfo['currentUserId'] != userId ||
          syncInfo['isInitialized'] != true) {
        debugPrint(
            '🔄 إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي: $userId');
        try {
          await syncManager.shutdown();
          await syncManager.initialize(userId);
          debugPrint(
              '✅ تم إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي');
        } catch (e) {
          debugPrint('⚠️ خطأ في إعادة تهيئة UnifiedSyncManager: $e');
        }
      }

      // تشغيل المزامنة فوراً
      await syncManager.performImmediateSync();

      debugPrint('✅ تم تشغيل المزامنة الفورية مع معرف المستخدم');
    } catch (e) {
      debugPrint('❌ خطأ في المزامنة الفورية: $e');
      // لا نريد إيقاف العملية الأساسية بسبب فشل المزامنة
    }
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة في UnifiedRepository...');

      // إعادة تعيين حالة المزامنة في SyncStateService
      final SyncStateService syncStateService = SyncStateService();
      await syncStateService.initialize();
      await syncStateService.resetSyncState();

      debugPrint('✅ تم إعادة تعيين حالة المزامنة في UnifiedRepository بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة في UnifiedRepository: $e');
      rethrow;
    }
  }

  /// تشغيل مزامنة فورية بعد عمليات الحذف
  Future<void> _triggerImmediateSyncAfterDelete() async {
    // نفس المنطق
    await _triggerImmediateSync();
  }
}
