import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';
import '../repositories/unified_repository.dart';
import '../services/error_handler_service.dart';
import '../services/local_sales_service.dart';
import '../services/server_timestamp_service.dart';

/// خدمة المبيعات الموحدة - المصدر الوحيد لجميع عمليات البيع
class UnifiedSalesService {
  UnifiedSalesService({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  })  : _productProvider = productProvider,
        _inventoryProvider = inventoryProvider;
  static const String _salesCollection = 'sales';
  static const Uuid _uuid = Uuid();

  final StreamProductProvider _productProvider;
  final StreamInventoryProvider _inventoryProvider;

  /// إتمام عملية بيع من السلة (POSTab)
  Future<String> completeCartSale({
    required List<CartItem> cart,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    if (cart.isEmpty) {
      throw Exception('السلة فارغة');
    }

    try {
      // استخدام الخدمة المحلية الجديدة للحفظ المحلي أولاً
      final LocalSalesService localSalesService = LocalSalesService();
      final String saleId = await localSalesService.completeCartSale(
        cart: cart,
        inventoryProvider: _inventoryProvider,
        customerName: customerName,
        notes: notes,
        paymentMethod: paymentMethod,
        discount: discount,
      );

      debugPrint('تم حفظ عملية البيع محلياً بنجاح: $saleId');
      return saleId;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إتمام عملية بيع من السلة',
        context: <String, dynamic>{
          'operation': 'completeCartSale',
          'cartItems': cart.length,
          'totalAmount': calculateCartTotal(cart) - discount,
          'customerName': customerName,
          'paymentMethod': paymentMethod,
        },
      );
      rethrow;
    }
  }

  /// التحقق من وجود المنتج في Firestore وإضافته تلقائياً إذا لم يكن موجوداً
  static Future<bool> ensureProductExistsInFirestore({
    required String itemId,
    required Product product,
    required int actualQuantity, // الكمية الفعلية من التبويب
  }) async {
    try {
      debugPrint(
          '🔍 التحقق من وجود المنتج في Firestore - itemId: $itemId, quantity: $actualQuantity');

      // التحقق من وجود المنتج في مجموعة quantities
      final DocumentSnapshot<Object?> quantitySnap = await FirebaseFirestore
          .instance
          .collection('quantities')
          .doc(itemId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (quantitySnap.exists) {
        debugPrint('✅ المنتج موجود في مجموعة quantities');
        return true;
      }

      // التحقق من وجود المنتج في مجموعة inventory
      final DocumentSnapshot<Object?> inventorySnap = await FirebaseFirestore
          .instance
          .collection('inventory')
          .doc(itemId)
          .get();

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

  /// إتمام عملية بيع منتج واحد (AddProductTab)
  static Future<String> completeSingleProductSale({
    required String itemId,
    required Product product,
  }) async {
    try {
      if (itemId.trim().isEmpty) {
        throw ArgumentError('معرف العنصر لا يمكن أن يكون فارغاً');
      }
      if (!product.isValid()) {
        throw ArgumentError('بيانات المنتج غير صحيحة');
      }

      // الحصول على الكمية الفعلية من المخزون المحلي
      final UnifiedRepository repository = UnifiedRepository();
      final List<InventoryItem> inventoryItems =
          await repository.inventoryStream.first;
      final InventoryItem? inventoryItem = inventoryItems
          .where((InventoryItem item) => item.id == itemId)
          .firstOrNull;

      final int actualQuantity = inventoryItem?.quantity ?? 1;
      debugPrint('📊 الكمية الفعلية من المخزون المحلي: $actualQuantity');

      // التحقق من وجود المنتج في Firestore
      final bool productExists = await ensureProductExistsInFirestore(
        itemId: itemId,
        product: product,
        actualQuantity: actualQuantity,
      );

      if (!productExists) {
        throw Exception(
            'هذا المنتج غير موجود في المخزون. يرجى إضافة المخزون أولاً من تبويب المخزون');
      }

      // Windows-specific: Use sequential operations instead of transaction
      if (Platform.isWindows) {
        debugPrint('🪟 Windows: استخدام عمليات متسلسلة بدلاً من Transaction');

        try {
          // 1. Get current quantity
          final DocumentReference<Object?> itemRef =
              FirebaseFirestore.instance.collection('quantities').doc(itemId);
          final DocumentSnapshot<Object?> itemSnap =
              await itemRef.get().timeout(const Duration(seconds: 5));

          if (!itemSnap.exists) {
            throw Exception('عذرًا، هذا المنتج لم يعد متوفرًا في المخزون');
          }

          final Map<String, dynamic> data =
              itemSnap.data() as Map<String, dynamic>;
          final int currentQuantity = _parseQuantity(data['quantity']);

          if (currentQuantity <= 0) {
            throw Exception('عذرًا، نفذت كمية هذا المنتج من المخزون');
          }

          final int newQuantity = currentQuantity - 1;

          // 2. Update quantity first
          await itemRef.update(ServerTimestampService
              .updateDataWithServerTimestamp(<String, dynamic>{
            'quantity': newQuantity,
          }));

          // Small delay between operations
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // 3. Create sale record
          final String saleId = _uuid.v4();
          final DocumentReference<Object?> saleRef =
              FirebaseFirestore.instance.collection('products').doc(saleId);
          final Product saleProduct = product.copyWith(id: saleId);
          await saleRef.set(
              ServerTimestampService.createDataWithServerTimestamp(
                  saleProduct.toMap()));

          debugPrint(
              '✅ Windows: تمت العملية بنجاح بدون Transaction - itemId: $itemId, currentQuantity: $currentQuantity, newQuantity: $newQuantity');
        } catch (e) {
          debugPrint('❌ Windows: خطأ في العملية المتسلسلة: $e');
          rethrow;
        }
      } else {
        // Other platforms: Use transaction as before
        try {
          await FirebaseFirestore.instance.runTransaction(
            (Transaction transaction) async {
              final DocumentReference<Object?> itemRef = FirebaseFirestore
                  .instance
                  .collection('quantities')
                  .doc(itemId);
              final DocumentSnapshot<Object?> transactionItemSnap =
                  await transaction.get(itemRef);

              if (!transactionItemSnap.exists) {
                throw Exception('عذرًا، هذا المنتج لم يعد متوفرًا في المخزون');
              }

              final Map<String, dynamic> data =
                  transactionItemSnap.data() as Map<String, dynamic>;
              final int currentQuantity = _parseQuantity(data['quantity']);

              // التحقق من توفر الكمية
              if (currentQuantity <= 0) {
                throw Exception('عذرًا، نفذت كمية هذا المنتج من المخزون');
              }

              final int newQuantity = currentQuantity - 1;

              // تحديث الكمية مع توقيت الخادم
              final Map<String, dynamic> updateData = ServerTimestampService
                  .updateDataWithServerTimestamp(<String, dynamic>{
                'quantity': newQuantity,
              });
              transaction.update(itemRef, updateData);

              // إنشاء سجل البيع في مجموعة المنتجات مع توقيت الخادم
              final String saleId = _uuid.v4();
              final DocumentReference<Object?> saleRef =
                  FirebaseFirestore.instance.collection('products').doc(saleId);
              final Product saleProduct = product.copyWith(id: saleId);
              final Map<String, dynamic> saleData =
                  ServerTimestampService.createDataWithServerTimestamp(
                      saleProduct.toMap());
              transaction.set(saleRef, saleData);

              // تحديث المنتج في مجموعة quantities للعرض في StoreDisplayTab
              final DocumentReference<Object?> quantityRef = FirebaseFirestore
                  .instance
                  .collection('quantities')
                  .doc(itemId);
              final Map<String, dynamic> quantityUpdateData =
                  ServerTimestampService
                      .updateDataWithServerTimestamp(<String, dynamic>{
                'quantity': newQuantity,
              });
              transaction.update(quantityRef, quantityUpdateData);

              debugPrint(
                  '✅ تم إعداد المعاملة بنجاح - itemId: $itemId, currentQuantity: $currentQuantity, newQuantity: $newQuantity');
            },
            timeout: const Duration(seconds: 5),
          );
        } on FirebaseException catch (e) {
          debugPrint('❌ خطأ في المعاملة: ${e.code} - ${e.message}');
          rethrow;
        }
      }

      debugPrint('تم تنفيذ عملية البيع بنجاح للعنصر: $itemId');

      // تحديث StreamInventoryProvider لإظهار التغييرات فوراً
      try {
        debugPrint('🔄 إشعار تحديث المخزون...');

        // Windows-specific: Use delayed sync to avoid threading issues
        if (Platform.isWindows) {
          debugPrint('🪟 Windows: تأجيل المزامنة لتجنب مشاكل Threading');
          // Don't sync immediately - let periodic sync handle it
          Future.delayed(const Duration(seconds: 2), () async {
            try {
              final UnifiedRepository repository = UnifiedRepository();
              await repository.syncFromFirestore();
              debugPrint('✅ تم تحديث المخزون بنجاح (Windows delayed sync)');
            } catch (e) {
              debugPrint('⚠️ Windows delayed sync error: $e');
            }
          });
        } else {
          final UnifiedRepository repository = UnifiedRepository();
          await repository.syncFromFirestore();
          debugPrint('✅ تم تحديث المخزون بنجاح');
        }
      } catch (e) {
        debugPrint('⚠️ فشل في تحديث المخزون: $e');
        // Don't rethrow - sale was successful
      }

      return itemId;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('❌ خطأ Firebase في عملية البيع: ${e.code} - ${e.message}');
      debugPrint('❌ تفاصيل الخطأ: itemId=$itemId, productName=${product.name}');
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'إتمام عملية بيع منتج واحد',
        context: <String, dynamic>{
          'operation': 'completeSingleProductSale',
          'itemId': itemId,
          'productName': product.name,
          'productId': product.id,
          'firebaseCode': e.code,
          'firebaseMessage': e.message,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      debugPrint('❌ خطأ عام في عملية البيع: $e');
      debugPrint('❌ تفاصيل الخطأ: itemId=$itemId, productName=${product.name}');
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إتمام عملية بيع منتج واحد',
        context: <String, dynamic>{
          'operation': 'completeSingleProductSale',
          'itemId': itemId,
          'productName': product.name,
          'productId': product.id,
        },
      );
      rethrow;
    }
  }

  /// البحث عن منتج بالباركود
  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      // البحث في المنتجات أولاً
      final List<Product> products = _productProvider.products;
      final Product? product = products.cast<Product?>().firstWhere(
            (Product? p) =>
                p?.name.toLowerCase().contains(barcode.toLowerCase()) ?? false,
            orElse: () => null,
          );

      if (product != null) {
        return product;
      }
    } on Exception catch (_) {
      debugPrint('لم يتم العثور على منتج بالباركود: $barcode');
    }

    // البحث في المخزون
    try {
      final List<InventoryItem> inventoryItems =
          _inventoryProvider.inventoryItems;
      final InventoryItem? inventoryItem =
          inventoryItems.cast<InventoryItem?>().firstWhere(
                (InventoryItem? item) => item?.barcode == barcode,
                orElse: () => null,
              );

      if (inventoryItem != null) {
        // تحويل عنصر المخزون إلى منتج
        return Product(
          id: inventoryItem.id,
          name: inventoryItem.name,
          wholesalePrice: inventoryItem.wholesalePrice,
          retailPrice: inventoryItem.retailPrice, // استخدام سعر التجزئة
          savedAt: DateTime.now(),
        );
      }
    } on Exception catch (_) {
      debugPrint('لم يتم العثور على عنصر مخزون بالباركود: $barcode');
    }

    return null;
  }

  /// إضافة منتج إلى السلة
  Future<CartItem?> addProductToCart(String barcode) async {
    final Product? product = await findProductByBarcode(barcode);
    if (product == null) {
      return null;
    }
    return CartItem.fromProduct(product);
  }

  /// تحديث كمية منتج في السلة
  static void updateCartItemQuantity({
    required List<CartItem> cart,
    required String productId,
    required int newQuantity,
  }) {
    if (newQuantity <= 0) {
      removeFromCart(cart: cart, productId: productId);
      return;
    }

    final int index =
        cart.indexWhere((CartItem item) => item.productId == productId);
    if (index != -1) {
      cart[index] = cart[index].copyWith(quantity: newQuantity);
    }
  }

  /// حذف منتج من السلة
  static void removeFromCart({
    required List<CartItem> cart,
    required String productId,
  }) {
    cart.removeWhere((CartItem item) => item.productId == productId);
  }

  /// مسح السلة
  static void clearCart(List<CartItem> cart) {
    cart.clear();
  }

  /// حساب إجمالي السلة
  static int calculateCartTotal(List<CartItem> cart) => cart.fold(
        0,
        (int sum, CartItem item) => sum + item.totalPrice.round(),
      );

  /// حساب إجمالي الربح
  static int calculateCartProfit(List<CartItem> cart) => cart.fold(
        0,
        (int sum, CartItem item) => sum + item.totalProfit.round(),
      );

  /// حساب المبلغ الإجمالي مع الخصم
  static int calculateTotalWithDiscount(List<CartItem> cart, int discount) =>
      calculateCartTotal(cart) - discount;

  /// التحقق من صحة السلة
  static bool validateCart(List<CartItem> cart) {
    if (cart.isEmpty) return false;

    for (final CartItem item in cart) {
      if (item.quantity <= 0) return false;
      if (item.retailPrice <= 0) return false;
    }

    return true;
  }

  /// الحصول على إحصائيات السلة
  static Map<String, dynamic> getCartStatistics(List<CartItem> cart) {
    if (cart.isEmpty) {
      return <String, dynamic>{
        'totalItems': 0,
        'totalQuantity': 0,
        'totalAmount': 0,
        'totalProfit': 0,
        'averageItemPrice': 0,
        'averageProfit': 0,
      };
    }

    final int totalItems = cart.length;
    final int totalQuantity =
        cart.fold(0, (int sum, CartItem item) => sum + item.quantity);
    final int totalAmount = calculateCartTotal(cart);
    final int totalProfit = calculateCartProfit(cart);
    final double averageItemPrice = totalAmount / totalQuantity;
    final double averageProfit = totalProfit / totalQuantity;

    return <String, dynamic>{
      'totalItems': totalItems,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'totalProfit': totalProfit,
      'averageItemPrice': averageItemPrice,
      'averageProfit': averageProfit,
    };
  }

  /// تحليل كمية المخزون
  static int _parseQuantity(Object? quantity) {
    if (quantity is int) return quantity;
    if (quantity is String) {
      if (quantity == 'نفذت الكمية') return 0;
      return int.tryParse(quantity) ?? 0;
    }
    return 0;
  }

  /// الحصول على تقرير المبيعات
  static Future<Map<String, dynamic>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(_salesCollection)
              .where('saleDate', isGreaterThanOrEqualTo: startDate)
              .where('saleDate', isLessThanOrEqualTo: endDate)
              .get();

      final List<Sale> sales = querySnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Sale.fromMap(doc.data()))
          .toList();

      final double totalRevenue = sales.fold<double>(
          0, (double sum, Sale sale) => sum + sale.totalAmount);
      final double totalProfit = sales.fold<double>(
          0, (double sum, Sale sale) => sum + sale.totalProfit);
      final int totalTransactions = sales.length;

      return <String, dynamic>{
        'sales': sales,
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
        'totalTransactions': totalTransactions,
        'averageTransactionValue':
            totalTransactions > 0 ? totalRevenue / totalTransactions : 0,
        'startDate': startDate,
        'endDate': endDate,
      };
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'الحصول على تقرير المبيعات',
        context: <String, dynamic>{
          'operation': 'getSalesReport',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'الحصول على تقرير المبيعات',
        context: <String, dynamic>{
          'operation': 'getSalesReport',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  /// الحصول على أفضل المنتجات مبيعاً
  static Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(_salesCollection)
              .where('saleDate', isGreaterThanOrEqualTo: startDate)
              .where('saleDate', isLessThanOrEqualTo: endDate)
              .get();

      final List<Sale> sales = querySnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Sale.fromMap(doc.data()))
          .toList();

      final Map<String, Map<String, dynamic>> productStats =
          <String, Map<String, dynamic>>{};

      for (final Sale sale in sales) {
        for (final CartItem item in sale.items) {
          if (productStats.containsKey(item.name)) {
            final Map<String, dynamic> stats = productStats[item.name]!;
            stats['quantity'] = (stats['quantity'] as int) + item.quantity;
            stats['revenue'] = (stats['revenue'] as double) + item.totalPrice;
            stats['profit'] = (stats['profit'] as double) + item.totalProfit;
          } else {
            productStats[item.name] = <String, dynamic>{
              'name': item.name,
              'quantity': item.quantity,
              'revenue': item.totalPrice,
              'profit': item.totalProfit,
            };
          }
        }
      }

      final List<Map<String, dynamic>> topProducts = productStats.values
          .toList()
        ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            (b['quantity'] as int).compareTo(a['quantity'] as int));

      return topProducts.take(limit).toList();
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'الحصول على أفضل المنتجات مبيعاً',
        context: <String, dynamic>{
          'operation': 'getTopSellingProducts',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'limit': limit,
        },
      );
      return <Map<String, dynamic>>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'الحصول على أفضل المنتجات مبيعاً',
        context: <String, dynamic>{
          'operation': 'getTopSellingProducts',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'limit': limit,
        },
      );
      return <Map<String, dynamic>>[];
    }
  }

  /// الحصول على إحصائيات المبيعات اليومية
  static Future<List<Map<String, dynamic>>> getDailySalesStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(_salesCollection)
              .where('saleDate', isGreaterThanOrEqualTo: startDate)
              .where('saleDate', isLessThanOrEqualTo: endDate)
              .orderBy('saleDate')
              .get();

      final List<Sale> sales = querySnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Sale.fromMap(doc.data()))
          .toList();

      final Map<String, Map<String, dynamic>> dailyStats =
          <String, Map<String, dynamic>>{};

      for (final Sale sale in sales) {
        final String dateKey =
            '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';

        if (dailyStats.containsKey(dateKey)) {
          final Map<String, dynamic> stats = dailyStats[dateKey]!;
          stats['revenue'] = (stats['revenue'] as double) + sale.totalAmount;
          stats['profit'] = (stats['profit'] as double) + sale.totalProfit;
          stats['transactions'] = (stats['transactions'] as int) + 1;
        } else {
          dailyStats[dateKey] = <String, dynamic>{
            'date': dateKey,
            'revenue': sale.totalAmount.toDouble(),
            'profit': sale.totalProfit.toDouble(),
            'transactions': 1,
          };
        }
      }

      return dailyStats.values.toList()
        ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            (a['date'] as String).compareTo(b['date'] as String));
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'الحصول على إحصائيات المبيعات اليومية',
        context: <String, dynamic>{
          'operation': 'getDailySalesStatistics',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return <Map<String, dynamic>>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'الحصول على إحصائيات المبيعات اليومية',
        context: <String, dynamic>{
          'operation': 'getDailySalesStatistics',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return <Map<String, dynamic>>[];
    }
  }

  /// التحقق من توفر المنتج في المخزون
  Future<bool> checkProductAvailability(
      String productName, int requiredQuantity) async {
    try {
      final List<InventoryItem> inventoryItems =
          _inventoryProvider.inventoryItems;
      final InventoryItem? inventoryItem =
          inventoryItems.cast<InventoryItem?>().firstWhere(
                (InventoryItem? item) => item?.name == productName,
                orElse: () => null,
              );

      return inventoryItem != null &&
          inventoryItem.quantity >= requiredQuantity;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        userAction: 'التحقق من توفر المنتج في المخزون',
        context: <String, dynamic>{
          'operation': 'checkProductAvailability',
          'productName': productName,
          'requiredQuantity': requiredQuantity,
        },
      );
      return false;
    }
  }

  /// الحصول على تحليل الربحية
  static Future<Map<String, dynamic>> getProfitabilityAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final Map<String, dynamic> salesReport = await getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      final double totalRevenue = salesReport['totalRevenue'] as double;
      final double totalProfit = salesReport['totalProfit'] as double;
      final int totalTransactions = salesReport['totalTransactions'] as int;

      final double profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
      final double averageProfitPerTransaction =
          totalTransactions > 0 ? totalProfit / totalTransactions : 0;

      return <String, dynamic>{
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
        'profitMargin': profitMargin,
        'averageProfitPerTransaction': averageProfitPerTransaction,
        'totalTransactions': totalTransactions,
        'startDate': startDate,
        'endDate': endDate,
      };
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحليل الربحية',
        context: <String, dynamic>{
          'operation': 'getProfitabilityAnalysis',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  // ========== دوال ثابتة للتوافق مع الكود الحالي ==========

  /// إنشاء مثيل من الخدمة مع المزودات المطلوبة
  static UnifiedSalesService create({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) =>
      UnifiedSalesService(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

  /// إتمام عملية بيع من السلة (دالة ثابتة للتوافق)
  static Future<String> completeCartSaleStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required List<CartItem> cart,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    final UnifiedSalesService service = UnifiedSalesService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.completeCartSale(
      cart: cart,
      customerName: customerName,
      notes: notes,
      paymentMethod: paymentMethod,
      discount: discount,
    );
  }

  /// البحث عن منتج بالباركود (دالة ثابتة للتوافق)
  static Future<Product?> findProductByBarcodeStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String barcode,
  }) async {
    final UnifiedSalesService service = UnifiedSalesService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.findProductByBarcode(barcode);
  }

  /// إضافة منتج إلى السلة (دالة ثابتة للتوافق)
  static Future<CartItem?> addProductToCartStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String barcode,
  }) async {
    final UnifiedSalesService service = UnifiedSalesService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.addProductToCart(barcode);
  }

  /// التحقق من توفر المنتج في المخزون (دالة ثابتة للتوافق)
  static Future<bool> checkProductAvailabilityStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String productName,
    required int requiredQuantity,
  }) async {
    final UnifiedSalesService service = UnifiedSalesService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.checkProductAvailability(
        productName, requiredQuantity);
  }
}
