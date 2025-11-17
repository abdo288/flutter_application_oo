import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/drift_database.dart';
import '../models/cart_item.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../repositories/unified_repository.dart';
import '../services/app_event_bus.dart';
import '../services/error_handler_service.dart';
// import '../services/enhanced_sync_manager.dart';

/// خدمة المبيعات المحلية - تحفظ المبيعات محلياً أولاً ثم تزامنها
class LocalSalesService {
  static const Uuid _uuid = Uuid();
  final AppDatabase _localDb = AppDatabase.instance;
  final UnifiedRepository _repository = UnifiedRepository();
  // final EnhancedSyncManager _syncManager = EnhancedSyncManager();

  /// إتمام عملية بيع من السلة مع حفظ محلي أولاً
  Future<String> completeCartSale({
    required List<CartItem> cart,
    required WidgetRef ref,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    if (cart.isEmpty) {
      throw Exception('السلة فارغة');
    }

    // التحقق من صحة السلة قبل الحساب
    for (final CartItem item in cart) {
      // فحص القيم السالبة
      if (item.retailPrice < 0 ||
          item.wholesalePrice < 0 ||
          item.quantity < 0) {
        throw Exception(
            'بيانات السلة غير صحيحة: ${item.name} - retailPrice: ${item.retailPrice}, wholesalePrice: ${item.wholesalePrice}, quantity: ${item.quantity}');
      }

      debugPrint(
          '✅ فحص عنصر السلة: ${item.name} - retailPrice: ${item.retailPrice}, quantity: ${item.quantity}');
    }

    // ✅ التحقق النهائي من المخزون قبل بدء المعاملة (حل مشكلة Race Condition)
    await _validateInventoryAvailability(cart, ref);

    final int totalAmount = calculateCartTotal(cart) - discount;
    final int totalProfit = calculateCartProfit(cart);
    final String saleId = _uuid.v4();

    // إنشاء كائن البيع خارج المعاملة لاستخدامه في إرسال الحدث
    final Sale sale = Sale(
      id: saleId,
      items: List<CartItem>.from(cart),
      totalAmount: totalAmount,
      totalProfit: totalProfit,
      saleDate: DateTime.now(),
      customerName: customerName,
      notes: notes,
      paymentMethod: paymentMethod,
      discount: discount,
    );

    try {
      // بدء معاملة محلية لضمان الاتساق
      await _localDb.transaction(() async {
        // 1. حفظ عملية البيع محلياً

        await _localDb.upsertSale(SalesTableCompanion(
          id: Value(saleId),
          items: Value(jsonEncode(
              sale.items.map((CartItem item) => item.toMap()).toList())),
          totalAmount: Value(totalAmount),
          totalProfit: Value(totalProfit),
          saleDate: Value(sale.saleDate.toIso8601String()),
          customerName: Value(customerName),
          notes: Value(notes),
          paymentMethod: Value(paymentMethod),
          discount: Value(discount),
          userId: const Value(null), // سيتم تعيينه لاحقاً
          isSynced: const Value(false),
          lastModified: Value(DateTime.now().toIso8601String()),
        ));

        // 2. تحديث المخزون محلياً في نفس المعاملة
        await _updateInventoryInTransaction(cart, ref);

        debugPrint('✅ تم حفظ عملية البيع محلياً: $saleId');
      });

      // 3. إضافة عملية البيع إلى طابور المزامنة مع إعادة المحاولة
      await _addSaleToSyncQueueWithRetry(saleId, cart, totalAmount, totalProfit,
          customerName ?? '', notes ?? '', paymentMethod, discount);

      // 4. إرسال حدث إتمام البيع لتحديث التقارير فورياً
      AppEventBus.fire(
          SaleCompletedEvent(sale, cart, sourceTab: 'LocalSalesService'));

      debugPrint('✅ تم إرسال حدث إتمام البيع: ${sale.totalAmount} دج');

      return saleId;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إتمام عملية بيع محلياً',
        context: <String, dynamic>{
          'operation': 'completeCartSale',
          'cartItems': cart.length,
          'totalAmount': totalAmount,
          'customerName': customerName,
          'paymentMethod': paymentMethod,
        },
      );
      rethrow;
    }
  }

  /// التحقق النهائي من توفر المخزون قبل إتمام البيع
  /// هذا يحل مشكلة Race Condition عندما يتغير المخزون بين إضافة المنتج للسلة وإتمام البيع
  Future<void> _validateInventoryAvailability(
      List<CartItem> cart, WidgetRef ref) async {
    debugPrint('🔍 بدء التحقق النهائي من توفر المخزون...');
    
    final InventoryState inventoryState =
        ref.read(inventoryControllerProvider);
    final List<InventoryItem> inventoryItems =
        inventoryState.inventoryItems;

    for (final CartItem item in cart) {
      // البحث عن عنصر المخزون الحالي (من مصدر الحقيقة)
      final InventoryItem? inventoryItem =
          inventoryItems.cast<InventoryItem?>().firstWhere(
                (InventoryItem? invItem) => invItem?.name == item.name,
                orElse: () => null,
              );

      if (inventoryItem == null) {
        throw Exception(
            'المنتج "${item.name}" غير موجود في المخزون. يرجى تحديث السلة.');
      }

      if (inventoryItem.id == null) {
        throw Exception(
            'عنصر المخزون "${item.name}" لا يحتوي على معرف صالح.');
      }

      // التحقق من توفر الكمية المطلوبة
      if (inventoryItem.quantity < item.quantity) {
        throw Exception(
            'الكمية غير كافية للمنتج "${item.name}".\n'
            'المطلوب: ${item.quantity}\n'
            'المتوفر: ${inventoryItem.quantity}\n'
            'يرجى تحديث السلة أو تعديل الكمية.');
      }

      debugPrint(
          '✅ التحقق من ${item.name}: المطلوب=${item.quantity}, المتوفر=${inventoryItem.quantity}');
    }

    debugPrint('✅ اكتمل التحقق النهائي من المخزون - جميع الكميات متوفرة');
  }

  /// تحديث المخزون في معاملة محلية
  Future<void> _updateInventoryInTransaction(
      List<CartItem> cart, WidgetRef ref) async {
    for (final CartItem item in cart) {
      try {
        // البحث عن عنصر المخزون
        final InventoryState inventoryState =
            ref.read(inventoryControllerProvider);
        final List<InventoryItem> inventoryItems =
            inventoryState.inventoryItems;
        final InventoryItem? inventoryItem =
            inventoryItems.cast<InventoryItem?>().firstWhere(
                  (InventoryItem? invItem) => invItem?.name == item.name,
                  orElse: () => null,
                );

        if (inventoryItem != null && inventoryItem.id != null) {
          // فحص القيم قبل الحساب
          debugPrint(
              '🔍 تحديث مخزون: ${item.name} - inventoryQuantity: ${inventoryItem.quantity}, cartQuantity: ${item.quantity}');

          // ✅ التحقق مرة أخرى داخل المعاملة (Double-check locking pattern)
          if (inventoryItem.quantity < item.quantity) {
            throw Exception(
                'الكمية غير كافية للمنتج "${item.name}" في المعاملة.\n'
                'المطلوب: ${item.quantity}\n'
                'المتوفر: ${inventoryItem.quantity}');
          }

          // تحديث الكمية محلياً
          final int newQuantity = inventoryItem.quantity - item.quantity;
          if (newQuantity >= 0) {
            final InventoryItem updatedItem =
                inventoryItem.copyWith(quantity: newQuantity);

            // فحص القيم قبل الحفظ
            debugPrint(
                '🔍 قيم updatedItem: wholesalePrice=${updatedItem.wholesalePrice}, originalQuantity=${updatedItem.originalQuantity}');

            // حفظ التحديث محلياً
            await _localDb.upsertInventoryItem(InventoryTableCompanion(
              id: Value(inventoryItem.id!),
              name: Value(updatedItem.name),
              barcode: Value(updatedItem.barcode),
              wholesalePrice: Value(updatedItem.wholesalePrice),
              quantity: Value(updatedItem.quantity),
              originalQuantity: Value(updatedItem.originalQuantity),
              addedDate: Value(updatedItem.addedDate.toIso8601String()),
              addedTime: Value(updatedItem.addedTime.toIso8601String()),
              userId: const Value(null),
              isSynced: const Value(false), // سيتم مزامنته لاحقاً
              lastModified: Value(DateTime.now().toIso8601String()),
            ));

            // إضافة تحديث المخزون إلى طابور المزامنة
            try {
              debugPrint(
                  '🔍 إضافة تحديث المخزون إلى طابور المزامنة: ${inventoryItem.id}');
              debugPrint('🔍 updatedItem قبل toMap: ${updatedItem.toString()}');
              final Map<String, dynamic> itemMap = updatedItem.toMap();
              debugPrint('🔍 بيانات المخزون بعد toMap: $itemMap');
              debugPrint('🔍 بدء استدعاء addToSyncQueue...');
              await _repository.addToSyncQueue(
                'updateInventoryItem',
                'quantities',
                inventoryItem.id!,
                itemMap,
              );
              debugPrint('✅ تم إضافة تحديث المخزون إلى طابور المزامنة');
            } catch (e, stackTrace) {
              debugPrint('❌ خطأ في إضافة تحديث المخزون إلى طابور المزامنة: $e');
              debugPrint('❌ Stack trace: $stackTrace');
              // لا نعيد رمي الخطأ هنا لأن التحديث المحلي تم بنجاح
            }

            debugPrint('✅ تم تحديث مخزون ${item.name} محلياً: $newQuantity');
          }
        }
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          userAction: 'تحديث المخزون في المعاملة',
          context: <String, dynamic>{
            'operation': '_updateInventoryInTransaction',
            'itemName': item.name,
            'itemQuantity': item.quantity,
          },
        );
        debugPrint('❌ خطأ في تحديث مخزون ${item.name}: $e');
        rethrow; // إعادة رمي الخطأ لإلغاء المعاملة بالكامل
      }
    }
  }

  /// حساب إجمالي السلة
  int calculateCartTotal(List<CartItem> cart) =>
      cart.fold(0, (int total, CartItem item) {
        final int itemTotal = item.retailPrice * item.quantity;
        debugPrint(
            'حساب عنصر: ${item.name} - price: ${item.retailPrice}, qty: ${item.quantity}, total: $itemTotal');
        return total + itemTotal;
      });

  /// حساب إجمالي الربح
  int calculateCartProfit(List<CartItem> cart) =>
      cart.fold(0, (int total, CartItem item) {
        final int profit = (item.retailPrice - item.wholesalePrice) * item.quantity;
        debugPrint(
            'حساب ربح عنصر: ${item.name} - retail: ${item.retailPrice}, wholesale: ${item.wholesalePrice}, qty: ${item.quantity}, profit: $profit');
        return total + profit;
      });

  /// الحصول على جميع المبيعات المحلية
  Future<List<Sale>> getAllLocalSales() async {
    try {
      final List<SalesTableData> salesData = await _localDb.getAllSales();
      return salesData.map((SalesTableData data) {
        try {
          final List<dynamic> itemsJson =
              jsonDecode(data.items) as List<dynamic>;
          final List<CartItem> items = itemsJson.map((item) {
            try {
              return CartItem.fromMap(item as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ خطأ في تحويل عنصر السلة: $e - البيانات: $item');
              // إنشاء عنصر افتراضي آمن
              return CartItem(
                productId: (item['productId'] as String?) ?? 'unknown',
                name: (item['name'] as String?) ?? 'منتج غير معروف',
                barcode: (item['barcode'] as String?) ?? '',
                retailPrice: _safeParseInt(item['retailPrice']),
                wholesalePrice: _safeParseInt(item['wholesalePrice']),
                quantity: _safeParseInt(item['quantity'], defaultValue: 1),
                discount: _safeParseInt(item['discount']),
              );
            }
          }).toList();

          return Sale(
            id: data.id,
            items: items,
            totalAmount: data.totalAmount,
            totalProfit: data.totalProfit,
            saleDate: DateTime.parse(data.saleDate),
            customerName: data.customerName,
            notes: data.notes,
            paymentMethod: data.paymentMethod,
            discount: data.discount,
          );
        } catch (e) {
          debugPrint('❌ خطأ في تحويل بيانات البيع: $e - ID: ${data.id}');
          // إرجاع عملية بيع فارغة بدلاً من إيقاف العملية
          return Sale(
            id: data.id,
            items: <CartItem>[],
            totalAmount: 0,
            totalProfit: 0,
            saleDate: DateTime.now(),
            customerName: data.customerName,
            notes: data.notes,
            paymentMethod: data.paymentMethod,
            discount: data.discount,
          );
        }
      }).toList();
    } on Exception catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات المحلية: $e');
      return <Sale>[];
    }
  }

  /// الحصول على المبيعات غير المزامنة
  Future<List<Sale>> getUnsyncedSales() async {
    try {
      final List<SalesTableData> salesData = await _localDb.getUnsyncedSales();
      return salesData.map((SalesTableData data) {
        try {
          final List<dynamic> itemsJson =
              jsonDecode(data.items) as List<dynamic>;
          final List<CartItem> items = itemsJson.map((item) {
            try {
              return CartItem.fromMap(item as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ خطأ في تحويل عنصر السلة: $e - البيانات: $item');
              // إنشاء عنصر افتراضي آمن
              return CartItem(
                productId: (item['productId'] as String?) ?? 'unknown',
                name: (item['name'] as String?) ?? 'منتج غير معروف',
                barcode: (item['barcode'] as String?) ?? '',
                retailPrice: _safeParseInt(item['retailPrice']),
                wholesalePrice: _safeParseInt(item['wholesalePrice']),
                quantity: _safeParseInt(item['quantity'], defaultValue: 1),
                discount: _safeParseInt(item['discount']),
              );
            }
          }).toList();

          return Sale(
            id: data.id,
            items: items,
            totalAmount: data.totalAmount,
            totalProfit: data.totalProfit,
            saleDate: DateTime.parse(data.saleDate),
            customerName: data.customerName,
            notes: data.notes,
            paymentMethod: data.paymentMethod,
            discount: data.discount,
          );
        } catch (e) {
          debugPrint('❌ خطأ في تحويل بيانات البيع: $e - ID: ${data.id}');
          // إرجاع عملية بيع فارغة بدلاً من إيقاف العملية
          return Sale(
            id: data.id,
            items: <CartItem>[],
            totalAmount: 0,
            totalProfit: 0,
            saleDate: DateTime.now(),
            customerName: data.customerName,
            notes: data.notes,
            paymentMethod: data.paymentMethod,
            discount: data.discount,
          );
        }
      }).toList();
    } on Exception catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات غير المزامنة: $e');
      return <Sale>[];
    }
  }

  /// تمييز عملية بيع كمزامنة
  Future<void> markSaleAsSynced(String saleId) async {
    try {
      await _localDb.markSaleAsSynced(saleId);
      debugPrint('✅ تم تمييز عملية البيع كمزامنة: $saleId');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تمييز عملية البيع كمزامنة: $e');
    }
  }

  /// الحصول على المبيعات المحلية لفترة محددة
  Future<List<Sale>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final List<Sale> allSales = await getUnsyncedSales();
      return allSales
          .where((Sale sale) =>
              sale.saleDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              sale.saleDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    } on Exception catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات المحلية للفترة المحددة: $e');
      return <Sale>[];
    }
  }

  /// الحصول على إحصائيات المزامنة البسيطة
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final List<Sale> unsyncedSales = await getUnsyncedSales();
      final List<Sale> allSales = await getAllLocalSales();

      return <String, dynamic>{
        'totalSales': allSales.length,
        'unsyncedSales': unsyncedSales.length,
        'syncedSales': allSales.length - unsyncedSales.length,
        'syncRate': allSales.isEmpty
            ? 0.0
            : (allSales.length - unsyncedSales.length) / allSales.length,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات المزامنة: $e');
      return <String, dynamic>{
        'totalSales': 0,
        'unsyncedSales': 0,
        'syncedSales': 0,
        'syncRate': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// تحويل آمن للقيم إلى int
  static int _safeParseInt(Object? value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// إضافة عملية البيع إلى طابور المزامنة مع إعادة المحاولة
  Future<void> _addSaleToSyncQueueWithRetry(
    String saleId,
    List<CartItem> cart,
    int totalAmount,
    int totalProfit,
    String customerName,
    String notes,
    String paymentMethod,
    int discount,
  ) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
            '🔍 إضافة عملية البيع إلى طابور المزامنة: $saleId (محاولة ${retryCount + 1})');

        await _repository.addToSyncQueue(
          'addSale',
          'sales',
          saleId,
          <String, dynamic>{
            'id': saleId,
            'items': cart.map((CartItem item) => item.toMap()).toList(),
            'totalAmount': totalAmount,
            'totalProfit': totalProfit,
            'saleDate': DateTime.now().toIso8601String(),
            'customerName': customerName,
            'notes': notes,
            'paymentMethod': paymentMethod,
            'discount': discount,
            'retryCount': retryCount,
            'priority': 'high', // أولوية عالية للمبيعات
          },
        );

        debugPrint('✅ تم إضافة عملية البيع إلى طابور المزامنة: $saleId');
        return; // نجح، اخرج من الحلقة
      } catch (e) {
        retryCount++;
        debugPrint(
            '❌ خطأ في إضافة عملية البيع إلى طابور المزامنة (محاولة $retryCount): $e');

        if (retryCount >= maxRetries) {
          debugPrint(
              '❌ فشل في إضافة عملية البيع إلى طابور المزامنة بعد $maxRetries محاولات');
          // إضافة إلى قائمة انتظار منفصلة للعمليات الفاشلة
          await _addToFailedSyncQueue(saleId, cart, totalAmount, totalProfit,
              customerName, notes, paymentMethod, discount);
          return;
        }

        // انتظار قبل إعادة المحاولة (exponential backoff)
        final int delaySeconds = retryCount * 2;
        debugPrint('⏳ انتظار $delaySeconds ثانية قبل إعادة المحاولة...');
        await Future<void>.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// إضافة إلى قائمة انتظار العمليات الفاشلة
  Future<void> _addToFailedSyncQueue(
    String saleId,
    List<CartItem> cart,
    int totalAmount,
    int totalProfit,
    String customerName,
    String notes,
    String paymentMethod,
    int discount,
  ) async {
    try {
      // حفظ في جدول منفصل للعمليات الفاشلة
      await _localDb.upsertSale(SalesTableCompanion(
        id: Value(saleId),
        items: Value(
            jsonEncode(cart.map((CartItem item) => item.toMap()).toList())),
        totalAmount: Value(totalAmount),
        totalProfit: Value(totalProfit),
        saleDate: Value(DateTime.now().toIso8601String()),
        customerName: Value(customerName),
        notes: Value(notes),
        paymentMethod: Value(paymentMethod),
        discount: Value(discount),
        userId: const Value(null),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().toIso8601String()),
        // syncFailed: const Value(true), // علامة على فشل المزامنة - غير متوفر في الجدول
      ));

      debugPrint('📋 تم إضافة عملية البيع إلى قائمة العمليات الفاشلة: $saleId');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة عملية البيع إلى قائمة العمليات الفاشلة: $e');
    }
  }
}
