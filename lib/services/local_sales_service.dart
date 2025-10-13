import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/drift_database.dart';
import '../models/cart_item.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../providers/stream_inventory_provider.dart';
import '../repositories/unified_repository.dart';
import '../services/error_handler_service.dart';

/// خدمة المبيعات المحلية - تحفظ المبيعات محلياً أولاً ثم تزامنها
class LocalSalesService {
  static const Uuid _uuid = Uuid();
  final AppDatabase _localDb = AppDatabase.instance;
  final UnifiedRepository _repository = UnifiedRepository();

  /// إتمام عملية بيع من السلة مع حفظ محلي أولاً
  Future<String> completeCartSale({
    required List<CartItem> cart,
    required StreamInventoryProvider inventoryProvider,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    if (cart.isEmpty) {
      throw Exception('السلة فارغة');
    }

    final int totalAmount = calculateCartTotal(cart) - discount;
    final int totalProfit = calculateCartProfit(cart);
    final String saleId = _uuid.v4();

    try {
      // بدء معاملة محلية لضمان الاتساق
      await _localDb.transaction(() async {
        // 1. حفظ عملية البيع محلياً
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
        await _updateInventoryInTransaction(cart, inventoryProvider);

        debugPrint('✅ تم حفظ عملية البيع محلياً: $saleId');
      });

      // 3. إضافة عملية البيع إلى طابور المزامنة
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
        },
      );

      debugPrint('✅ تم إضافة عملية البيع إلى طابور المزامنة: $saleId');
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

  /// تحديث المخزون في معاملة محلية
  Future<void> _updateInventoryInTransaction(
      List<CartItem> cart, StreamInventoryProvider inventoryProvider) async {
    for (final CartItem item in cart) {
      try {
        // البحث عن عنصر المخزون
        final List<InventoryItem> inventoryItems =
            inventoryProvider.inventoryItems;
        final InventoryItem? inventoryItem =
            inventoryItems.cast<InventoryItem?>().firstWhere(
                  (InventoryItem? invItem) => invItem?.name == item.name,
                  orElse: () => null,
                );

        if (inventoryItem != null && inventoryItem.id != null) {
          // تحديث الكمية محلياً
          final int newQuantity = inventoryItem.quantity - item.quantity;
          if (newQuantity >= 0) {
            final InventoryItem updatedItem =
                inventoryItem.copyWith(quantity: newQuantity);

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
            await _repository.addToSyncQueue(
              'updateInventoryItem',
              'quantities',
              inventoryItem.id!,
              updatedItem.toMap(),
            );

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
  int calculateCartTotal(List<CartItem> cart) => cart.fold(0,
      (int total, CartItem item) => total + (item.retailPrice * item.quantity));

  /// حساب إجمالي الربح
  int calculateCartProfit(List<CartItem> cart) => cart.fold(
      0,
      (int total, CartItem item) =>
          total + ((item.retailPrice - item.wholesalePrice) * item.quantity));

  /// الحصول على جميع المبيعات المحلية
  Future<List<Sale>> getAllLocalSales() async {
    try {
      final List<SalesTableData> salesData = await _localDb.getAllSales();
      return salesData.map((SalesTableData data) {
        final List<dynamic> itemsJson = jsonDecode(data.items) as List<dynamic>;
        final List<CartItem> items = itemsJson
            .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList();

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
        final List<dynamic> itemsJson = jsonDecode(data.items) as List<dynamic>;
        final List<CartItem> items = itemsJson
            .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList();

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
}
