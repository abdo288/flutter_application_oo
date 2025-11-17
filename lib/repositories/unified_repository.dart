import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../services/error_handler_service.dart';
import '../services/server_timestamp_service.dart';
import '../services/sync_state_service.dart';
import '../services/unified_sync_manager.dart';
import '../utils/platform_thread_safety.dart';

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

  // Stream لحالة المصادقة
  Stream<User?> get _authStateStream =>
      FirebaseAuth.instance.authStateChanges();

  // مفتاح الأمان - يتحكم في تفعيل/تعطيل Streams
  bool _streamsEnabled = true;

  // Stream subscriptions للتحكم فيها
  StreamSubscription<firestore.QuerySnapshot<Map<String, dynamic>>>?
      _productsSubscription;
  StreamSubscription<firestore.QuerySnapshot<Map<String, dynamic>>>?
      _inventorySubscription;

  /// تعطيل Streams قبل تسجيل الخروج
  Future<void> disableStreams() async {
    debugPrint('🔒 UnifiedRepository: بدء تعطيل Streams وإغلاق الاشتراكات');
    _streamsEnabled = false;

    try {
      // إلغاء الاشتراكات بشكل غير متزامن مع timeout
      final List<Future<void>> cancellations = <Future<void>>[];

      if (_productsSubscription != null) {
        cancellations.add(_productsSubscription!.cancel().then((_) => null));
      }

      if (_inventorySubscription != null) {
        cancellations.add(_inventorySubscription!.cancel().then((_) => null));
      }

      if (cancellations.isNotEmpty) {
        await Future.wait<void>(cancellations).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ انتهت مهلة إغلاق Streams');
            return <void>[];
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في إغلاق Streams (سيتم تجاهله): $e');
    }

    _productsSubscription = null;
    _inventorySubscription = null;

    debugPrint('✅ UnifiedRepository: تم إغلاق جميع الاشتراكات بنجاح');
  }

  /// إعادة تفعيل Streams بعد تسجيل الخروج
  void enableStreams() {
    debugPrint('😀 UnifiedRepository: تم إعادة تفعيل Streams');
    _streamsEnabled = true;
  }

  // ========== Streams للبيانات ==========

  /// Stream للمنتجات - يستمع مباشرة لـ Firestore ويحدث Local DB تلقائياً
  /// ✅ تطبيق CQRS Pattern: Firestore = مصدر الحقيقة الوحيد
  Stream<List<Product>> get productsStream {
    try {
      debugPrint('🔄 إنشاء productsStream مع Firestore listener مباشر');

      // ✅ التحقق من مفتاح الأمان أولاً
      if (!_streamsEnabled) {
        debugPrint('🔒 Streams معطلة - إرجاع قائمة فارغة');
        return Stream.value(<Product>[]);
      }

      // ✅ التحقق من حالة المصادقة قبل إنشاء Stream
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع Stream فارغ');
        return const Stream.empty();
      }

      // ✅ إغلاق الاشتراك السابق إن وجد
      _productsSubscription?.cancel();

      // ✅ استخدام authStateChanges للتحقق المستمر من حالة المصادقة
      return _authStateStream.asyncExpand((User? user) {
        if (user == null) {
          debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع Stream فارغ');
          return const Stream.empty();
        }

        // ✅ التحقق من مفتاح الأمان
        if (!_streamsEnabled) {
          debugPrint('🔒 Streams معطلة - إرجاع Stream فارغ');
          return const Stream.empty();
        }

        debugPrint('✅ المستخدم مصادق عليه - بدء الاستماع للمنتجات');

        // ✅ إغلاق الاشتراك السابق إن وجد
        _productsSubscription?.cancel();

        // ✅ إنشاء stream جديد للـ Firestore
        final Stream<firestore.QuerySnapshot<Map<String, dynamic>>> stream = _firestore
            .collection('products')
            .snapshots(includeMetadataChanges: true);

        // ✅ حفظ الاشتراك للتحكم فيه لاحقاً
        _productsSubscription = stream.listen(
          null,
          onError: (Object error) {
            // تجاهل أخطاء الصلاحيات بعد تسجيل الخروج
            if (error.toString().contains('permission-denied') ||
                error
                    .toString()
                    .contains('Missing or insufficient permissions')) {
              debugPrint(
                  '! تم تجاهل خطأ صلاحيات في productsStream (تسجيل خروج): $error');
              return;
            }
            debugPrint('❌ خطأ في productsSubscription: $error');
          },
        );

        return stream.asyncMap(
            (firestore.QuerySnapshot<Map<String, dynamic>> snapshot) async {
          try {
            // ✅ التحقق من مفتاح الأمان قبل المعالجة
            if (!_streamsEnabled) {
              debugPrint('🔒 Streams معطلة - إرجاع قائمة فارغة');
              return <Product>[];
            }

            debugPrint('📥 استلام ${snapshot.docs.length} منتج من Firestore');

            // ✅ استخدام PlatformThreadSafety لضمان التنفيذ على platform thread
            return await PlatformThreadSafety.executeFirestoreOperation(
              () async {
                // تحديث Local DB فوراً عند كل تغيير من Firestore
                for (final firestore
                    .QueryDocumentSnapshot<Map<String, dynamic>> doc
                    in snapshot.docs) {
                  // تخطي التحديثات المحلية المعلقة
                  if (doc.metadata.hasPendingWrites) {
                    debugPrint('⏭️ تخطي تحديث محلي معلق: ${doc.id}');
                    continue;
                  }

                  final Map<String, dynamic> data = doc.data();
                  data['id'] = doc.id;

                  // تحديث Local DB
                  await _upsertProductToLocalDb(data);
                }

                // إرجاع البيانات من Local DB (للاستفادة من الكاش)
                final List<ProductsTableData> rows =
                    await _localDb.select(_localDb.productsTable).get();

                return rows
                    .map((ProductsTableData row) => Product(
                          id: row.id,
                          name: row.name,
                          wholesalePrice: row.wholesalePrice,
                          retailPrice: row.retailPrice,
                          savedAt: safeParseDateTime(row.savedAt),
                          lastModified: safeParseDateTime(row.lastModified),
                          description: row.description,
                          barcode: row.barcode,
                          category: row.category,
                          supplier: row.supplier,
                          status: _parseProductStatus(row.status),
                          images: row.images != null
                              ? _parseStringList(row.images!)
                              : null,
                          tags: row.tags != null
                              ? _parseStringList(row.tags!)
                              : null,
                          weight: row.weight,
                          dimensions: row.dimensions,
                          minimumStock: row.minimumStock,
                          maximumStock: row.maximumStock,
                          taxRate: row.taxRate,
                          discountRate: row.discountRate,
                          isActive: row.isActive,
                          notes: row.notes,
                        ))
                    .toList();
              },
              operationName: 'productsStream_asyncMap',
            );
          } catch (e) {
            // تجاهل أخطاء الصلاحيات
            if (e.toString().contains('permission-denied') ||
                e.toString().contains('Missing or insufficient permissions')) {
              debugPrint(
                  '! تم تجاهل خطأ صلاحيات في productsStream asyncMap: $e');
              return <Product>[];
            }
            debugPrint('❌ خطأ في معالجة Firestore snapshot: $e');
            // في حالة الخطأ، إرجاع البيانات من Local DB
            try {
              final List<ProductsTableData> rows =
                  await _localDb.select(_localDb.productsTable).get();
              return rows
                  .map((ProductsTableData row) => Product(
                        id: row.id,
                        name: row.name,
                        wholesalePrice: row.wholesalePrice,
                        retailPrice: row.retailPrice,
                        savedAt: safeParseDateTime(row.savedAt),
                        lastModified: safeParseDateTime(row.lastModified),
                        description: row.description,
                        barcode: row.barcode,
                        category: row.category,
                        supplier: row.supplier,
                        status: _parseProductStatus(row.status),
                        images: row.images != null
                            ? _parseStringList(row.images!)
                            : null,
                        tags: row.tags != null
                            ? _parseStringList(row.tags!)
                            : null,
                        weight: row.weight,
                        dimensions: row.dimensions,
                        minimumStock: row.minimumStock,
                        maximumStock: row.maximumStock,
                        taxRate: row.taxRate,
                        discountRate: row.discountRate,
                        isActive: row.isActive,
                        notes: row.notes,
                      ))
                  .toList();
            } catch (dbError) {
              debugPrint('❌ خطأ في قراءة Local DB: $dbError');
              return <Product>[];
            }
          }
        }).handleError((Object error) {
          // تجاهل أخطاء الصلاحيات بعد تسجيل الخروج
          if (error.toString().contains('permission-denied') ||
              error
                  .toString()
                  .contains('Missing or insufficient permissions')) {
            debugPrint(
                '⚠️ تم تجاهل خطأ صلاحيات في productsStream (تسجيل خروج): $error');
            return <Product>[];
          }
          debugPrint('❌ خطأ في productsStream: $error');
          return <Product>[];
        });
      });
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء productsStream: $e');
      // Fallback: إرجاع stream من Local DB فقط
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
              .toList());
    }
  }

  /// مساعد: تحديث منتج في Local DB من Firestore data
  Future<void> _upsertProductToLocalDb(Map<String, dynamic> data) async {
    try {
      await _localDb.upsertProduct(ProductsTableCompanion(
        id: Value(data['id']?.toString() ?? ''),
        name: Value(data['name']?.toString() ?? ''),
        wholesalePrice: Value(safeParseInt(
          data['wholesalePrice'] ?? data['wholesale_price'],
        )),
        retailPrice: Value(safeParseInt(
          data['retailPrice'] ?? data['retail_price'],
        )),
        savedAt: Value(safeParseDateTime(
          data['savedAt'] ?? data['saved_at'],
        ).toIso8601String()),
        isSynced: const Value(true),
        lastModified: Value(DateTime.now().toIso8601String()),
        description: Value(data['description']?.toString()),
        barcode: Value(data['barcode']?.toString()),
        category: Value(data['category']?.toString()),
        supplier: Value(data['supplier']?.toString()),
        status: Value(data['status']?.toString() ?? 'active'),
      ));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث منتج في Local DB: $e');
    }
  }

  /// Stream للمخزون - يستمع مباشرة لـ Firestore ويحدث Local DB تلقائياً
  /// ✅ تطبيق CQRS Pattern: Firestore = مصدر الحقيقة الوحيد
  Stream<List<InventoryItem>> get inventoryStream {
    try {
      debugPrint('🔄 إنشاء inventoryStream مع Firestore listener مباشر');

      // ✅ التحقق من مفتاح الأمان أولاً
      if (!_streamsEnabled) {
        debugPrint('🔒 Streams معطلة - إرجاع قائمة فارغة');
        return Stream.value(<InventoryItem>[]);
      }

      // ✅ التحقق من حالة المصادقة قبل إنشاء Stream
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع Stream فارغ');
        return const Stream.empty();
      }

      // ✅ إغلاق الاشتراك السابق إن وجد
      _inventorySubscription?.cancel();

      // ✅ استخدام authStateChanges للتحقق المستمر من حالة المصادقة
      return _authStateStream.asyncExpand((User? user) {
        if (user == null) {
          debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع Stream فارغ');
          return const Stream.empty();
        }

        // ✅ التحقق من مفتاح الأمان
        if (!_streamsEnabled) {
          debugPrint('🔒 Streams معطلة - إرجاع Stream فارغ');
          return const Stream.empty();
        }

        debugPrint('✅ المستخدم مصادق عليه - بدء الاستماع للمخزون');

        // ✅ إغلاق الاشتراك السابق إن وجد
        _inventorySubscription?.cancel();

        // ✅ إنشاء stream جديد للـ Firestore
        final Stream<firestore.QuerySnapshot<Map<String, dynamic>>> stream = _firestore
            .collection('quantities')
            .snapshots(includeMetadataChanges: true);

        // ✅ حفظ الاشتراك للتحكم فيه لاحقاً
        _inventorySubscription = stream.listen(
          null,
          onError: (Object error) {
            // تجاهل أخطاء الصلاحيات بعد تسجيل الخروج
            if (error.toString().contains('permission-denied') ||
                error
                    .toString()
                    .contains('Missing or insufficient permissions')) {
              debugPrint(
                  '! تم تجاهل خطأ صلاحيات في inventoryStream (تسجيل خروج): $error');
              return;
            }
            debugPrint('❌ خطأ في inventorySubscription: $error');
          },
        );

        return stream.asyncMap(
            (firestore.QuerySnapshot<Map<String, dynamic>> snapshot) async {
          try {
            debugPrint(
                '📥 استلام ${snapshot.docs.length} عنصر مخزون من Firestore');

            // ✅ استخدام PlatformThreadSafety لضمان التنفيذ على platform thread
            return await PlatformThreadSafety.executeFirestoreOperation(
              () async {
                for (final firestore
                    .QueryDocumentSnapshot<Map<String, dynamic>> doc
                    in snapshot.docs) {
                  // تخطي التحديثات المحلية المعلقة
                  if (doc.metadata.hasPendingWrites) {
                    debugPrint('⏭️ تخطي تحديث محلي معلق: ${doc.id}');
                    continue;
                  }

                  final Map<String, dynamic> data = doc.data();
                  data['id'] = doc.id;

                  // تحديث Local DB
                  await _upsertInventoryToLocalDb(data);
                }

                // إرجاع البيانات من Local DB (للاستفادة من الكاش)
                final List<InventoryTableData> rows =
                    await _localDb.select(_localDb.inventoryTable).get();

                return rows
                    .map((InventoryTableData row) => InventoryItem(
                          id: row.id,
                          name: row.name,
                          barcode: row.barcode,
                          wholesalePrice: row.wholesalePrice,
                          retailPrice: row.retailPrice,
                          quantity: row.quantity,
                          originalQuantity: row.originalQuantity,
                          addedDate: safeParseDateTime(row.addedDate),
                          addedTime: safeParseDateTime(row.addedTime),
                        ))
                    .toList();
              },
              operationName: 'inventoryStream',
            );
          } catch (e) {
            debugPrint('❌ خطأ في معالجة Firestore snapshot للمخزون: $e');
            // في حالة الخطأ، إرجاع البيانات من Local DB
            final List<InventoryTableData> rows =
                await _localDb.select(_localDb.inventoryTable).get();
            return rows
                .map((InventoryTableData row) => InventoryItem(
                      id: row.id,
                      name: row.name,
                      barcode: row.barcode,
                      wholesalePrice: row.wholesalePrice,
                      retailPrice: row.retailPrice,
                      quantity: row.quantity,
                      originalQuantity: row.originalQuantity,
                      addedDate: safeParseDateTime(row.addedDate),
                      addedTime: safeParseDateTime(row.addedTime),
                    ))
                .toList();
          }
        }).handleError((Object error) {
          // تجاهل أخطاء الصلاحيات بعد تسجيل الخروج
          if (error.toString().contains('permission-denied') ||
              error
                  .toString()
                  .contains('Missing or insufficient permissions')) {
            debugPrint(
                '⚠️ تم تجاهل خطأ صلاحيات في inventoryStream (تسجيل خروج): $error');
            return <InventoryItem>[];
          }
          debugPrint('❌ خطأ في inventoryStream: $error');
          // ✅ إضافة fallback لتحميل البيانات من قاعدة البيانات المحلية
          return _getInventoryItemsFromLocal();
        });
      });
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء inventoryStream: $e');
      // Fallback: إرجاع stream من Local DB فقط
      return _localDb
          .select(_localDb.inventoryTable)
          .watch()
          .map((List<InventoryTableData> rows) => rows
              .map((InventoryTableData row) => InventoryItem(
                    id: row.id,
                    name: row.name,
                    barcode: row.barcode,
                    wholesalePrice: row.wholesalePrice,
                    retailPrice: row.retailPrice,
                    quantity: row.quantity,
                    originalQuantity: row.originalQuantity,
                    addedDate: safeParseDateTime(row.addedDate),
                    addedTime: safeParseDateTime(row.addedTime),
                  ))
              .toList());
    }
  }

  /// مساعد: تحميل البيانات من قاعدة البيانات المحلية
  Future<List<InventoryItem>> _getInventoryItemsFromLocal() async {
    try {
      debugPrint('🔄 تحميل البيانات من قاعدة البيانات المحلية...');
      final List<InventoryTableData> rows =
          await _localDb.select(_localDb.inventoryTable).get();

      final List<InventoryItem> items = rows
          .map((InventoryTableData row) => InventoryItem(
                id: row.id,
                name: row.name,
                barcode: row.barcode,
                wholesalePrice: row.wholesalePrice,
                retailPrice: row.retailPrice,
                quantity: row.quantity,
                originalQuantity: row.originalQuantity,
                addedDate: safeParseDateTime(row.addedDate),
                addedTime: safeParseDateTime(row.addedTime),
              ))
          .toList();

      debugPrint('✅ تم تحميل ${items.length} عنصر من قاعدة البيانات المحلية');
      return items;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات من قاعدة البيانات المحلية: $e');
      return <InventoryItem>[];
    }
  }

  /// مساعد: تحديث عنصر مخزون في Local DB من Firestore data
  Future<void> _upsertInventoryToLocalDb(Map<String, dynamic> data) async {
    try {
      await _localDb.upsertInventoryItem(InventoryTableCompanion(
        id: Value(data['id']?.toString() ?? ''),
        name: Value(data['name']?.toString() ?? ''),
        barcode: Value(data['barcode']?.toString()),
        wholesalePrice: Value(safeParseInt(data['wholesalePrice'])),
        retailPrice: Value(safeParseInt(data['retailPrice'])),
        quantity: Value(safeParseInt(data['quantity'])),
        originalQuantity: Value(safeParseInt(data['originalQuantity'] ?? 0)),
        addedDate:
            Value(safeParseDateTime(data['addedDate']).toIso8601String()),
        addedTime:
            Value(safeParseDateTime(data['addedTime']).toIso8601String()),
        isSynced: const Value(true),
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث عنصر مخزون في Local DB: $e');
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

  /// إضافة منتج جديد - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<String> addProduct(Product product) async {
    try {
      final String id =
          product.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final Product productWithId = product.copyWith(id: id);

      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الكتابة إلى Firestore مع ضمان platform thread safety
          debugPrint('📤 إضافة منتج إلى Firestore: $id');
          await PlatformThreadSafety.executeFirestoreOperation(
            () async {
              await _firestore
                  .collection('products')
                  .doc(id)
                  .set(<String, dynamic>{
                'id': id,
                'name': productWithId.name,
                'wholesalePrice': productWithId.wholesalePrice,
                'retailPrice': productWithId.retailPrice,
                'savedAt': productWithId.savedAt.toIso8601String(),
                'saved_at': productWithId.savedAt.toIso8601String(),
                'last_modified': firestore.FieldValue.serverTimestamp(),
                'description': productWithId.description,
                'barcode': productWithId.barcode,
                'category': productWithId.category,
                'supplier': productWithId.supplier,
                'status': productWithId.status.name,
                'app_id': 'local_app',
              });
            },
            operationName: 'addProduct',
          );

          debugPrint(
              '✅ تم إضافة المنتج إلى Firestore (Listener سيحدث Local DB)');
          return id;
        } catch (e) {
          debugPrint('⚠️ فشل الكتابة إلى Firestore: $e - الحفظ محلياً');
          // في حالة فشل Firestore، احفظ محلياً وأضف لقائمة الانتظار
          await _addProductOffline(productWithId);
          return id;
        }
      } else {
        // Offline: حفظ محلي + قائمة انتظار
        debugPrint('📴 Offline mode: حفظ المنتج محلياً');
        await _addProductOffline(productWithId);
        return id;
      }
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

  /// إضافة منتج في وضع offline
  Future<void> _addProductOffline(Product product) async {
    // حفظ في Local DB
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

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'addProduct',
      'products',
      product.id!,
      product.toMap(),
    );

    debugPrint('📋 تم حفظ المنتج محلياً وإضافته لقائمة الانتظار');
  }

  /// تحديث منتج موجود - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<void> updateProduct(Product product) async {
    try {
      if (product.id == null) throw ArgumentError('معرف المنتج مطلوب');

      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الكتابة إلى Firestore مباشرة
          debugPrint('📤 تحديث منتج في Firestore: ${product.id}');
          await _firestore
              .collection('products')
              .doc(product.id)
              .update(<Object, Object?>{
            'name': product.name,
            'wholesalePrice': product.wholesalePrice,
            'retailPrice': product.retailPrice,
            'savedAt': product.savedAt.toIso8601String(),
            'saved_at': product.savedAt.toIso8601String(),
            'last_modified': firestore.FieldValue.serverTimestamp(),
            'description': product.description,
            'barcode': product.barcode,
            'category': product.category,
            'supplier': product.supplier,
            'status': product.status.name,
            'app_id': 'local_app',
          });

          debugPrint('✅ تم تحديث المنتج في Firestore');

          // ✅ تحديث Local DB أيضاً لضمان التزامن الفوري
          final ProductsTableCompanion productCompanion =
              ProductsTableCompanion(
            id: Value(product.id!),
            name: Value(product.name),
            wholesalePrice: Value(product.wholesalePrice),
            retailPrice: Value(product.retailPrice),
            savedAt: Value(product.savedAt.toIso8601String()),
            isSynced: const Value(true),
            lastModified: Value(DateTime.now().toIso8601String()),
          );
          await _localDb.upsertProduct(productCompanion);

          debugPrint('✅ تم تحديث المنتج في Local DB');
        } catch (e) {
          debugPrint('⚠️ فشل التحديث في Firestore: $e - الحفظ محلياً');
          await _updateProductOffline(product);
        }
      } else {
        // Offline: حفظ محلي + قائمة انتظار
        debugPrint('📴 Offline mode: تحديث المنتج محلياً');
        await _updateProductOffline(product);
      }
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

  /// تحديث منتج في وضع offline
  Future<void> _updateProductOffline(Product product) async {
    // حفظ في Local DB
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

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'updateProduct',
      'products',
      product.id!,
      product.toMap(),
    );

    debugPrint('📋 تم تحديث المنتج محلياً وإضافته لقائمة الانتظار');
  }

  // ========== عمليات المخزون ==========

  /// إضافة عنصر مخزون جديد - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<String> addInventoryItem(InventoryItem item) async {
    try {
      final String id =
          item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final InventoryItem itemWithId = item.copyWith(id: id);

      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الكتابة إلى Firestore مباشرة
          debugPrint('📤 إضافة عنصر مخزون إلى Firestore: $id');
          await _firestore
              .collection('quantities')
              .doc(id)
              .set(<String, dynamic>{
            'id': id,
            'name': itemWithId.name,
            'barcode': itemWithId.barcode,
            'wholesalePrice': itemWithId.wholesalePrice,
            'retailPrice': itemWithId.retailPrice,
            'quantity': itemWithId.quantity,
            'originalQuantity': itemWithId.originalQuantity,
            'addedDate': itemWithId.addedDate.toIso8601String(),
            'addedTime': itemWithId.addedTime.toIso8601String(),
            'last_modified': firestore.FieldValue.serverTimestamp(),
            'app_id': 'local_app',
          });

          debugPrint(
              '✅ تم إضافة عنصر المخزون إلى Firestore (Listener سيحدث Local DB)');
          return id;
        } catch (e) {
          debugPrint('⚠️ فشل الكتابة إلى Firestore: $e - الحفظ محلياً');
          await _addInventoryOffline(itemWithId);
          return id;
        }
      } else {
        // Offline: حفظ محلي + قائمة انتظار
        debugPrint('📴 Offline mode: حفظ عنصر المخزون محلياً');
        await _addInventoryOffline(itemWithId);
        return id;
      }
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

  /// إضافة عنصر مخزون في وضع offline
  Future<void> _addInventoryOffline(InventoryItem item) async {
    // حفظ في Local DB
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

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'addInventoryItem',
      'quantities',
      item.id!,
      item.toMap(),
    );

    debugPrint('📋 تم حفظ عنصر المخزون محلياً وإضافته لقائمة الانتظار');
  }

  /// تحديث عنصر مخزون موجود - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      if (item.id == null) throw ArgumentError('معرف عنصر المخزون مطلوب');

      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الكتابة إلى Firestore مباشرة
          debugPrint('📤 تحديث عنصر مخزون في Firestore: ${item.id}');
          await _firestore
              .collection('quantities')
              .doc(item.id)
              .update(<Object, Object?>{
            'name': item.name,
            'barcode': item.barcode,
            'wholesalePrice': item.wholesalePrice,
            'retailPrice': item.retailPrice,
            'quantity': item.quantity,
            'originalQuantity': item.originalQuantity,
            'addedDate': item.addedDate.toIso8601String(),
            'addedTime': item.addedTime.toIso8601String(),
            'last_modified': firestore.FieldValue.serverTimestamp(),
            'app_id': 'local_app',
          });

          debugPrint('✅ تم تحديث عنصر المخزون في Firestore');

          // ✅ تحديث Local DB أيضاً لضمان التزامن الفوري
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
            isSynced: const Value(true),
            lastModified: Value(DateTime.now().toIso8601String()),
          );
          await _localDb.upsertInventoryItem(itemCompanion);

          debugPrint('✅ تم تحديث عنصر المخزون في Local DB');
        } catch (e) {
          debugPrint('⚠️ فشل التحديث في Firestore: $e - الحفظ محلياً');
          await _updateInventoryOffline(item);
        }
      } else {
        // Offline: حفظ محلي + قائمة انتظار
        debugPrint('📴 Offline mode: تحديث عنصر المخزون محلياً');
        await _updateInventoryOffline(item);
      }
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

  /// تحديث عنصر مخزون في وضع offline
  Future<void> _updateInventoryOffline(InventoryItem item) async {
    // حفظ في Local DB
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

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'updateInventoryItem',
      'quantities',
      item.id!,
      item.toMap(),
    );

    debugPrint('📋 تم تحديث عنصر المخزون محلياً وإضافته لقائمة الانتظار');
  }

  /// حذف عنصر مخزون - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الحذف من Firestore مباشرة
          debugPrint('📤 حذف عنصر مخزون من Firestore: $itemId');
          await _firestore.collection('quantities').doc(itemId).delete();

          debugPrint('✅ تم حذف عنصر المخزون من Firestore');

          // ✅ حذف من Local DB أيضاً لضمان التزامن الفوري
          await (_localDb.delete(_localDb.inventoryTable)
                ..where(($InventoryTableTable t) => t.id.equals(itemId)))
              .go();

          debugPrint('✅ تم حذف عنصر المخزون من Local DB');
        } catch (e) {
          debugPrint('⚠️ فشل الحذف من Firestore: $e - الحفظ محلياً');
          await _deleteInventoryOffline(itemId);
        }
      } else {
        // Offline: حذف محلي + قائمة انتظار
        debugPrint('📴 Offline mode: حذف عنصر المخزون محلياً');
        await _deleteInventoryOffline(itemId);
      }
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

  /// حذف عنصر مخزون في وضع offline
  Future<void> _deleteInventoryOffline(String itemId) async {
    // حذف من Local DB
    await (_localDb.delete(_localDb.inventoryTable)
          ..where(($InventoryTableTable t) => t.id.equals(itemId)))
        .go();

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'deleteInventoryItem',
      'quantities',
      itemId,
      <String, dynamic>{'id': itemId, 'deleted': true},
    );

    debugPrint('📋 تم حذف عنصر المخزون محلياً وإضافته لقائمة الانتظار');
  }

  /// حذف منتج - يذهب إلى Firestore أولاً
  /// ✅ تطبيق CQRS: Write → Firestore, Read ← Firestore listener → Local DB
  Future<void> deleteProduct(String productId) async {
    try {
      // التحقق من الاتصال
      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = connectivity.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        try {
          // ✅ الحذف من Firestore مباشرة
          debugPrint('📤 حذف منتج من Firestore: $productId');
          await _firestore.collection('products').doc(productId).delete();

          debugPrint('✅ تم حذف المنتج من Firestore');

          // ✅ حذف من Local DB أيضاً لضمان التزامن الفوري
          await (_localDb.delete(_localDb.productsTable)
                ..where(($ProductsTableTable t) => t.id.equals(productId)))
              .go();

          debugPrint('✅ تم حذف المنتج من Local DB');
        } catch (e) {
          debugPrint('⚠️ فشل الحذف من Firestore: $e - الحفظ محلياً');
          await _deleteProductOffline(productId);
        }
      } else {
        // Offline: حذف محلي + قائمة انتظار
        debugPrint('📴 Offline mode: حذف المنتج محلياً');
        await _deleteProductOffline(productId);
      }
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

  /// حذف منتج في وضع offline
  Future<void> _deleteProductOffline(String productId) async {
    // حذف من Local DB
    await (_localDb.delete(_localDb.productsTable)
          ..where(($ProductsTableTable t) => t.id.equals(productId)))
        .go();

    // إضافة لقائمة الانتظار
    await _addToSyncQueue(
      'deleteProduct',
      'products',
      productId,
      <String, dynamic>{'id': productId, 'deleted': true},
    );

    debugPrint('📋 تم حذف المنتج محلياً وإضافته لقائمة الانتظار');
  }

  // ========== طابور المزامنة ==========

  /// تحويل البيانات إلى قيم قابلة للتسلسل (إزالة FieldValue)
  Map<String, dynamic> _makeDataSerializable(Map<String, dynamic> data) {
    final Map<String, dynamic> serializableData = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      try {
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
      } catch (e) {
        debugPrint(
            '❌ خطأ في تحويل المفتاح $key: $e - القيمة: $value (${value.runtimeType})');
        // استخدام قيمة آمنة في حالة الخطأ
        serializableData[key] = value?.toString() ?? 'null';
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
      debugPrint('🔍 إضافة إلى طابور المزامنة: $operation - $recordId');
      debugPrint('🔍 البيانات الأصلية: $data');

      // إضافة توقيتات الخادم الموثوقة
      final Map<String, dynamic> dataWithTimestamp =
          ServerTimestampService.updateDataWithServerTimestamp(data);
      debugPrint('🔍 البيانات مع التوقيت: $dataWithTimestamp');

      // تحويل FieldValue إلى قيم قابلة للتسلسل
      final Map<String, dynamic> serializableData =
          _makeDataSerializable(dataWithTimestamp);
      debugPrint('🔍 البيانات القابلة للتسلسل: $serializableData');

      // تحويل إلى JSON مع معالجة الأخطاء
      String jsonData;
      try {
        jsonData = jsonEncode(serializableData);
        debugPrint('🔍 JSON النهائي: $jsonData');
      } catch (e) {
        debugPrint('❌ خطأ في تحويل البيانات إلى JSON: $e');
        debugPrint('❌ البيانات التي فشل تحويلها: $serializableData');
        // استخدام بيانات مبسطة في حالة الخطأ
        jsonData = jsonEncode(<String, String>{
          'operation': operation,
          'recordId': recordId,
          'error': 'Failed to serialize data: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // إضافة العملية إلى جدول العمليات
      final int result =
          await _localDb.addSyncOperation(SyncOperationsTableCompanion(
        operation: Value(operation),
        targetTable: Value(tableName),
        recordId: Value(recordId),
        data: Value(jsonData),
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
      debugPrint(
          '❌ تفاصيل الخطأ: operation=$operation, recordId=$recordId, data=$data');
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

      // ✅ بناء استعلام Firestore مع platform thread safety
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

      // ✅ تنفيذ الاستعلام مع platform thread safety
      final firestore.QuerySnapshot<Map<String, dynamic>> snapshot =
          await PlatformThreadSafety.executeFirestoreOperation(
        query.get,
        operationName: '_syncProductsDelta_execute',
      );

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

      // ✅ بناء استعلام Firestore مع platform thread safety
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

      // ✅ تنفيذ الاستعلام مع platform thread safety
      final firestore.QuerySnapshot<Map<String, dynamic>> snapshot =
          await PlatformThreadSafety.executeFirestoreOperation(
        query.get,
        operationName: '_syncInventoryDelta_execute',
      );

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
              Value(safeParseInt(repairedData['originalQuantity'] ?? 0)),
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

  // ❌ تم إزالة: _triggerImmediateSyncAfterDelete - لم تعد مطلوبة مع Firestore direct writes
}
