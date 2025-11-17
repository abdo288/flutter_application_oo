import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/riverpod/stream_product_riverpod_provider.dart';
import '../services/local_sales_service.dart';

/// استثناء المخزون غير الكافي
class InsufficientStockException implements Exception {

  InsufficientStockException(
    this.message, {
    required this.productId,
    required this.requiredQuantity,
    required this.availableQuantity,
  });
  final String message;
  final String productId;
  final int requiredQuantity;
  final int availableQuantity;

  @override
  String toString() => 'InsufficientStockException: $message';
}

/// خدمة المبيعات المحسنة المبسطة
class SimplifiedEnhancedSalesService {

  SimplifiedEnhancedSalesService({required WidgetRef ref}) : _ref = ref;
  static const String _salesCollection = 'sales';
  static const String _quantitiesCollection = 'quantities';
  static const String _inventoryCollection = 'inventory';
  static const Uuid _uuid = Uuid();

  final WidgetRef _ref;
  final LocalSalesService _localSalesService = LocalSalesService();

  /// إتمام عملية بيع محسنة مع Transactions
  Future<String> completeCartSaleWithTransaction({
    required List<CartItem> cart,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    if (cart.isEmpty) {
      throw Exception('السلة فارغة');
    }

    final String saleId = _uuid.v4();
    final int totalAmount = calculateCartTotal(cart) - discount;
    final int totalProfit = calculateCartProfit(cart);

    try {
      // 1. حفظ البيع محلياً أولاً
      await _localSalesService.completeCartSale(
        cart: cart,
        ref: _ref,
        customerName: customerName,
        notes: notes,
        paymentMethod: paymentMethod,
        discount: discount,
      );

      debugPrint('✅ تم حفظ البيع محلياً: $saleId');

      // 2. محاولة المزامنة مع Firebase فوراً إذا كان متصل
      try {
        await _syncSaleWithTransaction(
          saleId: saleId,
          cart: cart,
          totalAmount: totalAmount,
          totalProfit: totalProfit,
          customerName: customerName,
          notes: notes,
          paymentMethod: paymentMethod,
          discount: discount,
        );

        // تمييز البيع كمزامن
        await _localSalesService.markSaleAsSynced(saleId);
        debugPrint('✅ تم مزامنة البيع بنجاح: $saleId');
      } catch (e) {
        debugPrint('⚠️ فشلت المزامنة الفورية، سيتم إعادة المحاولة لاحقاً: $e');
        // لا نرمي الخطأ هنا - البيع محفوظ محلياً
      }

      return saleId;
    } catch (e) {
      debugPrint('❌ فشلت عملية البيع: $e');
      rethrow;
    }
  }

  /// مزامنة البيع مع Firebase باستخدام Transaction
  Future<void> _syncSaleWithTransaction({
    required String saleId,
    required List<CartItem> cart,
    required int totalAmount,
    required int totalProfit,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction(
        (Transaction transaction) async {
          // التحقق من المخزون وتحديثه
          for (final CartItem item in cart) {
            await _updateInventoryInTransaction(transaction, item);
          }

          // حفظ البيع في Firestore
          final Sale sale = Sale(
            id: saleId,
            items: cart,
            totalAmount: totalAmount,
            totalProfit: totalProfit,
            saleDate: DateTime.now(),
            customerName: customerName,
            notes: notes,
            paymentMethod: paymentMethod,
            discount: discount,
          );

          final DocumentReference<Object?> saleRef = FirebaseFirestore.instance
              .collection(_salesCollection)
              .doc(saleId);

          transaction.set(saleRef, sale.toMap());

          debugPrint('✅ تم إعداد Transaction للبيع: $saleId');
        },
        timeout: const Duration(seconds: 10),
      );

      debugPrint('✅ تم مزامنة البيع بنجاح: $saleId');
    } on FirebaseException catch (e) {
      debugPrint('❌ خطأ Firebase في Transaction: ${e.code} - ${e.message}');

      if (e.code == 'aborted') {
        throw InsufficientStockException(
          'تعارض في المخزون - تم إلغاء العملية',
          productId: cart.first.productId,
          requiredQuantity: cart.first.quantity,
          availableQuantity: 0, // سيتم تحديده لاحقاً
        );
      }

      rethrow;
    }
  }

  /// تحديث المخزون داخل Transaction
  Future<void> _updateInventoryInTransaction(
    Transaction transaction,
    CartItem item,
  ) async {
    // البحث عن المنتج في المخزون
    final Product? product = await _findProductById(item.productId);
    if (product == null) {
      throw Exception('المنتج غير موجود: ${item.name}');
    }

    // البحث عن عنصر المخزون في Firestore
    final QuerySnapshot<Map<String, dynamic>> inventoryQuery =
        await FirebaseFirestore.instance
            .collection(_inventoryCollection)
            .where('name', isEqualTo: item.name)
            .limit(1)
            .get();

    if (inventoryQuery.docs.isEmpty) {
      throw Exception('عنصر المخزون غير موجود: ${item.name}');
    }

    final DocumentReference<Object?> inventoryRef =
        inventoryQuery.docs.first.reference;

    final DocumentSnapshot<Object?> inventoryDoc =
        await transaction.get(inventoryRef);

    if (!inventoryDoc.exists) {
      throw Exception('عنصر المخزون غير موجود في Firestore: ${item.name}');
    }

    final Map<String, dynamic> data =
        inventoryDoc.data() as Map<String, dynamic>;
    final int currentQuantity = _parseQuantity(data['quantity']);

    // التحقق من توفر الكمية
    if (currentQuantity < item.quantity) {
      throw InsufficientStockException(
        'المخزون غير كافٍ للمنتج ${item.name}',
        productId: item.productId,
        requiredQuantity: item.quantity,
        availableQuantity: currentQuantity,
      );
    }

    final int newQuantity = currentQuantity - item.quantity;

    // تحديث المخزون
    transaction.update(inventoryRef, <String, dynamic>{
      'quantity': newQuantity,
      'lastModified': FieldValue.serverTimestamp(),
    });

    // تحديث مجموعة quantities أيضاً
    final DocumentReference<Object?> quantityRef = FirebaseFirestore.instance
        .collection(_quantitiesCollection)
        .doc(item.productId);

    transaction.update(quantityRef, <String, dynamic>{
      'quantity': newQuantity,
      'lastModified': FieldValue.serverTimestamp(),
    });

    debugPrint(
        '📦 تم تحديث المخزون في Transaction: ${item.name} من $currentQuantity إلى $newQuantity');
  }

  /// البحث عن منتج بالمعرف
  Future<Product?> _findProductById(String productId) async {
    try {
      final List<Product> products =
          _ref.read(productsControllerProvider).products;
      return products.cast<Product?>().firstWhere(
            (Product? p) => p?.id == productId,
            orElse: () => null,
          );
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن المنتج: $e');
      return null;
    }
  }

  /// حساب إجمالي السلة
  int calculateCartTotal(List<CartItem> cart) => cart.fold(
        0,
        (int sum, CartItem item) => sum + item.totalPrice.round(),
      );

  /// حساب إجمالي الربح
  int calculateCartProfit(List<CartItem> cart) => cart.fold(
        0,
        (int sum, CartItem item) => sum + item.totalProfit.round(),
      );

  /// تحليل كمية المخزون
  int _parseQuantity(Object? quantity) {
    if (quantity is int) return quantity;
    if (quantity is String) {
      if (quantity == 'نفذت الكمية') return 0;
      return int.tryParse(quantity) ?? 0;
    }
    return 0;
  }

  /// إعادة محاولة مزامنة المبيعات غير المزامنة
  Future<void> retryFailedSyncs() async {
    try {
      final List<Sale> unsyncedSales =
          await _localSalesService.getUnsyncedSales();

      for (final Sale sale in unsyncedSales) {
        try {
          await _syncSaleWithTransaction(
            saleId: sale.id ?? const Uuid().v4(),
            cart: sale.items,
            totalAmount: sale.totalAmount,
            totalProfit: sale.totalProfit,
            customerName: sale.customerName ?? '',
            notes: sale.notes ?? '',
            paymentMethod: sale.paymentMethod,
            discount: sale.discount,
          );

          await _localSalesService
              .markSaleAsSynced(sale.id ?? const Uuid().v4());
          debugPrint('✅ تم مزامنة البيع المتأخر: ${sale.id}');
        } catch (e) {
          debugPrint('❌ فشلت مزامنة البيع المتأخر ${sale.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في إعادة محاولة المزامنة: $e');
    }
  }

  /// الحصول على إحصائيات المزامنة
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final List<Sale> unsyncedSales =
          await _localSalesService.getUnsyncedSales();
      final List<Sale> allSales = await _localSalesService.getAllLocalSales();

      return <String, dynamic>{
        'totalSales': allSales.length,
        'unsyncedSales': unsyncedSales.length,
        'syncedSales': allSales.length - unsyncedSales.length,
        'syncRate': allSales.isEmpty
            ? 0.0
            : (allSales.length - unsyncedSales.length) / allSales.length,
        'lastSyncAttempt': DateTime.now().toIso8601String(),
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
}
