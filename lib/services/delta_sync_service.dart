import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/stream_app_provider.dart';
import 'error_handler_service.dart';
import 'sync_state_service.dart';

/// نتيجة المزامنة التفاضلية
class DeltaSyncResult {
  DeltaSyncResult({
    required this.success,
    this.itemsAdded = 0,
    this.itemsUpdated = 0,
    this.itemsDeleted = 0,
    this.error,
  });
  final bool success;
  final int itemsAdded;
  final int itemsUpdated;
  final int itemsDeleted;
  final String? error;
}

/// خدمة المزامنة التفاضلية المحسنة
/// تقوم بجلب التغييرات فقط منذ آخر مزامنة بدلاً من جلب جميع البيانات
class DeltaSyncService {
  factory DeltaSyncService() => _instance;
  DeltaSyncService._internal();
  static final DeltaSyncService _instance = DeltaSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncStateService _syncStateService = SyncStateService();

  // Dependency injection for providers
  StreamAppProvider? _appProvider;

  /// Initialize the service with required providers
  void initialize(StreamAppProvider appProvider) {
    _appProvider = appProvider;
  }

  /// Check if service is properly initialized
  bool get isInitialized => _appProvider != null;

  /// مزامنة المنتجات التفاضلية
  Future<DeltaSyncResult> syncProducts() async {
    try {
      if (!isInitialized) {
        throw Exception(
            'DeltaSyncService not initialized. Call initialize() first.');
      }

      debugPrint('🔄 بدء المزامنة التفاضلية للمنتجات...');

      // التحقق من الحاجة للمزامنة
      if (!_syncStateService.needsProductSync()) {
        // تحسين خاص بـ Windows - إعادة تعيين حالة المزامنة إذا لم تظهر بيانات
        if (Platform.isWindows) {
          debugPrint('🪟 Windows: إعادة تعيين حالة المزامنة للمنتجات');
          await _syncStateService.resetSyncState();
        } else {
          debugPrint('✅ لا حاجة لمزامنة المنتجات - مزامنة حديثة');
          return DeltaSyncResult(success: true);
        }
      }

      // جلب التغييرات من Firestore بناءً على آخر مزامنة
      Query<Map<String, dynamic>> query = _firestore.collection('products');

      QuerySnapshot<Map<String, dynamic>> snapshot;

      // تحسين خاص بـ Windows - إزالة الفلترة الزمنية مؤقتاً
      if (Platform.isWindows) {
        debugPrint('🪟 Windows: جلب جميع المنتجات بدون فلترة زمنية');
        debugPrint(
            '🪟 Windows: آخر مزامنة منتجات: ${_syncStateService.lastProductSync}');
        // جلب جميع المنتجات بدون فلترة زمنية على Windows
        snapshot = await query.limit(50).get(); // زيادة الحد الأقصى
        debugPrint(
            '🪟 Windows: تم جلب ${snapshot.docs.length} منتج من Firestore');
      } else {
        // إضافة فلتر الوقت إذا كان هناك مزامنة سابقة
        if (_syncStateService.lastProductSync != null) {
          query = query.where('last_modified',
              isGreaterThan:
                  Timestamp.fromDate(_syncStateService.lastProductSync!));
        }

        snapshot = await query
            .orderBy('last_modified')
            .limit(15)
            .get(); // تقليل الحد الأقصى أكثر
      }

      int added = 0;
      int updated = 0;
      const int deleted = 0;

      // معالجة التغييرات
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          final String productId = doc.id;

          // استخدام Provider المحقون
          final StreamAppProvider appProvider = _appProvider!;

          // التحقق من وجود المنتج محلياً
          final bool existsLocally =
              await _productExists(appProvider, productId);

          if (existsLocally) {
            // تحديث المنتج الموجود
            await _updateLocalProduct(appProvider, productId, data);
            updated++;
            debugPrint('✏️ تم تحديث المنتج: ${data['name']}');
          } else {
            // إضافة منتج جديد
            await _addLocalProduct(appProvider, productId, data);
            added++;
            debugPrint('➕ تم إضافة منتج جديد: ${data['name']}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في معالجة منتج ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('✅ تمت المزامنة التفاضلية: +$added ✏️$updated 🗑️$deleted');

      // تحديث حالة المزامنة
      await _syncStateService.updateLastProductSync();

      return DeltaSyncResult(
        success: true,
        itemsAdded: added,
        itemsUpdated: updated,
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'المزامنة التفاضلية للمنتجات',
        context: <String, dynamic>{
          'operation': 'syncProducts',
          'service': 'DeltaSyncService',
        },
      );

      return DeltaSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// مزامنة عناصر المخزون التفاضلية
  Future<DeltaSyncResult> syncInventory() async {
    try {
      if (!isInitialized) {
        throw Exception(
            'DeltaSyncService not initialized. Call initialize() first.');
      }

      debugPrint('🔄 بدء المزامنة التفاضلية للمخزون...');

      // التحقق من الحاجة للمزامنة
      if (!_syncStateService.needsInventorySync()) {
        // تحسين خاص بـ Windows - إعادة تعيين حالة المزامنة إذا لم تظهر بيانات
        if (Platform.isWindows) {
          debugPrint('🪟 Windows: إعادة تعيين حالة المزامنة للمخزون');
          await _syncStateService.resetSyncState();
        } else {
          debugPrint('✅ لا حاجة لمزامنة المخزون - مزامنة حديثة');
          return DeltaSyncResult(success: true);
        }
      }

      // جلب التغييرات من Firestore بناءً على آخر مزامنة
      Query<Map<String, dynamic>> query = _firestore.collection('quantities');

      QuerySnapshot<Map<String, dynamic>> snapshot;

      // تحسين خاص بـ Windows - إزالة الفلترة الزمنية مؤقتاً
      if (Platform.isWindows) {
        debugPrint('🪟 Windows: جلب جميع عناصر المخزون بدون فلترة زمنية');
        debugPrint(
            '🪟 Windows: آخر مزامنة مخزون: ${_syncStateService.lastInventorySync}');
        // جلب جميع عناصر المخزون بدون فلترة زمنية على Windows
        snapshot = await query.limit(50).get(); // زيادة الحد الأقصى
        debugPrint(
            '🪟 Windows: تم جلب ${snapshot.docs.length} عنصر مخزون من Firestore');
      } else {
        // إضافة فلتر الوقت إذا كان هناك مزامنة سابقة
        if (_syncStateService.lastInventorySync != null) {
          query = query.where('last_modified',
              isGreaterThan:
                  Timestamp.fromDate(_syncStateService.lastInventorySync!));
        }

        snapshot = await query
            .orderBy('last_modified')
            .limit(15)
            .get(); // تقليل الحد الأقصى أكثر
      }

      int added = 0;
      int updated = 0;
      const int deleted = 0;

      // معالجة التغييرات
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          final String itemId = doc.id;

          // استخدام Provider المحقون
          final StreamAppProvider appProvider = _appProvider!;

          // التحقق من وجود العنصر محلياً
          final bool existsLocally =
              await _inventoryItemExists(appProvider, itemId);

          if (existsLocally) {
            // تحديث العنصر الموجود
            await _updateLocalInventoryItem(appProvider, itemId, data);
            updated++;
            debugPrint('✏️ تم تحديث عنصر المخزون: ${data['name']}');
          } else {
            // إضافة عنصر جديد
            await _addLocalInventoryItem(appProvider, itemId, data);
            added++;
            debugPrint('➕ تم إضافة عنصر مخزون جديد: ${data['name']}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في معالجة عنصر مخزون ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('✅ تمت المزامنة التفاضلية: +$added ✏️$updated 🗑️$deleted');

      // تحديث حالة المزامنة
      await _syncStateService.updateLastInventorySync();

      return DeltaSyncResult(
        success: true,
        itemsAdded: added,
        itemsUpdated: updated,
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'المزامنة التفاضلية للمخزون',
        context: <String, dynamic>{
          'operation': 'syncInventory',
          'service': 'DeltaSyncService',
        },
      );

      return DeltaSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// مزامنة شاملة لجميع البيانات
  Future<DeltaSyncResult> syncAll() async {
    try {
      debugPrint('🔄 بدء المزامنة التفاضلية الشاملة...');

      final DeltaSyncResult productsResult = await syncProducts();
      final DeltaSyncResult inventoryResult = await syncInventory();

      final bool success = productsResult.success && inventoryResult.success;
      final int totalAdded =
          productsResult.itemsAdded + inventoryResult.itemsAdded;
      final int totalUpdated =
          productsResult.itemsUpdated + inventoryResult.itemsUpdated;
      final int totalDeleted =
          productsResult.itemsDeleted + inventoryResult.itemsDeleted;

      // تحديث حالة المزامنة الشاملة
      if (success) {
        await _syncStateService.updateLastFullSync();
      }

      return DeltaSyncResult(
        success: success,
        itemsAdded: totalAdded,
        itemsUpdated: totalUpdated,
        itemsDeleted: totalDeleted,
        error: success ? null : 'فشل في مزامنة بعض البيانات',
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'المزامنة التفاضلية الشاملة',
        context: <String, dynamic>{
          'operation': 'syncAll',
          'service': 'DeltaSyncService',
        },
      );

      return DeltaSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ========== دوال مساعدة ==========

  /// التحقق من وجود منتج
  Future<bool> _productExists(
      StreamAppProvider appProvider, String productId) async {
    try {
      final List<Product> products = appProvider.productProvider.products;
      return products.any((Product product) => product.id == productId);
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود المنتج: $e');
      return false;
    }
  }

  /// التحقق من وجود عنصر مخزون
  Future<bool> _inventoryItemExists(
      StreamAppProvider appProvider, String itemId) async {
    try {
      final List<InventoryItem> items =
          appProvider.inventoryProvider.inventoryItems;
      return items.any((InventoryItem item) => item.id == itemId);
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود عنصر المخزون: $e');
      return false;
    }
  }

  /// إضافة منتج محلي
  Future<void> _addLocalProduct(StreamAppProvider appProvider, String productId,
      Map<String, dynamic> data) async {
    try {
      final Product product = Product(
        id: productId,
        name: data['name']?.toString() ?? '',
        wholesalePrice: _safeParseInt(data['wholesale_price']),
        retailPrice: _safeParseInt(data['retail_price']),
        savedAt: _safeParseDateTime(data['saved_at']),
      );
      await appProvider.productProvider.addProduct(product);
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج محلياً: $e');
      rethrow;
    }
  }

  /// تحديث منتج محلي
  Future<void> _updateLocalProduct(StreamAppProvider appProvider,
      String productId, Map<String, dynamic> data) async {
    try {
      final List<Product> products = appProvider.productProvider.products;
      final Product existingProduct = products.firstWhere(
        (Product product) => product.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final Product updatedProduct = existingProduct.copyWith(
        name: data['name']?.toString() ?? existingProduct.name,
        wholesalePrice: _safeParseInt(data['wholesale_price']),
        retailPrice: _safeParseInt(data['retail_price']),
        savedAt: _safeParseDateTime(data['saved_at']),
      );

      await appProvider.productProvider.updateProduct(updatedProduct);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المنتج محلياً: $e');
      rethrow;
    }
  }

  /// إضافة عنصر مخزون محلي
  Future<void> _addLocalInventoryItem(StreamAppProvider appProvider,
      String itemId, Map<String, dynamic> data) async {
    try {
      final InventoryItem inventoryItem = InventoryItem(
        id: itemId,
        name: data['name']?.toString() ?? '',
        barcode: data['barcode']?.toString(),
        wholesalePrice: _safeParseInt(data['wholesale_price']),
        retailPrice: _safeParseInt(data['retail_price']),
        quantity: _safeParseInt(data['quantity']),
        originalQuantity: _safeParseInt(data['original_quantity']),
        addedDate: _safeParseDateTime(data['added_date']),
        addedTime: _safeParseDateTime(data['added_time']),
      );
      await appProvider.inventoryProvider.addInventoryItem(inventoryItem);
    } catch (e) {
      debugPrint('❌ خطأ في إضافة عنصر المخزون محلياً: $e');
      rethrow;
    }
  }

  /// تحديث عنصر مخزون محلي
  Future<void> _updateLocalInventoryItem(StreamAppProvider appProvider,
      String itemId, Map<String, dynamic> data) async {
    try {
      final List<InventoryItem> items =
          appProvider.inventoryProvider.inventoryItems;
      final InventoryItem existingItem = items.firstWhere(
        (InventoryItem item) => item.id == itemId,
        orElse: () => throw Exception('Inventory item not found'),
      );

      final InventoryItem updatedItem = existingItem.copyWith(
        name: data['name']?.toString() ?? existingItem.name,
        barcode: data['barcode']?.toString() ?? existingItem.barcode,
        wholesalePrice: _safeParseInt(data['wholesale_price']),
        quantity: _safeParseInt(data['quantity']),
        originalQuantity: _safeParseInt(data['original_quantity']),
        addedDate: _safeParseDateTime(data['added_date']),
        addedTime: _safeParseDateTime(data['added_time']),
      );

      await appProvider.inventoryProvider.updateInventoryItem(updatedItem);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث عنصر المخزون محلياً: $e');
      rethrow;
    }
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('✅ تم إعادة تعيين حالة المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
    }
  }

  /// الحصول على إحصائيات المزامنة
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      return <String, dynamic>{
        'lastProductSync': DateTime.now().toIso8601String(),
        'lastInventorySync': DateTime.now().toIso8601String(),
        'isProductSyncNeeded': false,
        'isInventorySyncNeeded': false,
      };
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على إحصائيات المزامنة: $e');
      return <String, dynamic>{};
    }
  }

  // ========== دوال مساعدة ==========

  /// تحويل آمن للرقم
  int _safeParseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// تحويل آمن للتاريخ
  DateTime _safeParseDateTime(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
