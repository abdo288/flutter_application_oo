import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/inventory_item.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/quick_inventory_item.dart';
import '../models/sale.dart';
import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';
import 'connectivity_service.dart';
import 'error_handler_service.dart';
import 'local_sales_service.dart';

/// خدمة نقطة البيع (POS)
class POSService {
  static const String _salesCollection = 'sales';
  static const String _quickInventoryCollection = 'quick_inventory';
  static const String _posCollection = 'pos_sessions';
  static const String _posCartsCollection = 'pos_carts';
  static const Uuid _uuid = Uuid();
  static const int defaultPageSize = 20;

  /// البحث عن منتج بالاسم في المخزون فقط
  static Future<Product?> findProductByName(
    StreamProductProvider productProvider,
    StreamInventoryProvider inventoryProvider,
    String name,
  ) async {
    debugPrint('🔍 البحث عن منتج بالاسم في المخزون: $name');
    try {
      // البحث في المخزون فقط
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;

      final InventoryItem? inventoryItem = inventoryItems.firstWhere(
        (InventoryItem item) =>
            item.name.toLowerCase().contains(name.toLowerCase()),
        orElse: () => throw StateError('Inventory item not found'),
      );

      if (inventoryItem != null) {
        // تحويل عنصر المخزون إلى منتج
        final Product productFromInventory = Product(
          id: inventoryItem.id,
          name: inventoryItem.name,
          wholesalePrice: inventoryItem.wholesalePrice,
          retailPrice: inventoryItem.retailPrice,
          savedAt: inventoryItem.addedTime,
          barcode: inventoryItem.barcode,
        );

        debugPrint(
            '✅ تم العثور على المنتج في المخزون بالاسم: ${productFromInventory.name}');
        return productFromInventory;
      }
    } catch (e) {
      debugPrint('❌ لم يتم العثور على عنصر مخزون بالاسم: $name');
    }

    debugPrint('❌ فشل في العثور على المنتج بالاسم: $name');
    return null;
  }

  /// البحث عن منتج بالباركود
  static Future<Product?> findProductByBarcode(
    StreamProductProvider productProvider,
    StreamInventoryProvider inventoryProvider,
    String barcode,
  ) async {
    debugPrint('🔍 البحث عن منتج بالباركود: $barcode');
    try {
      // البحث في المنتجات أولاً - البحث بالباركود الدقيق
      final List<Product> products = productProvider.products;
      final Product product = products.firstWhere(
        (Product p) => p.barcode == barcode,
        orElse: () => throw StateError('Product not found'),
      );

      return product;
    } catch (e) {
      debugPrint('لم يتم العثور على منتج بالباركود: $barcode');

      // البحث البديل بالاسم (للتوافق مع الكود القديم)
      try {
        final List<Product> products = productProvider.products;
        final Product product = products.firstWhere(
          (Product p) => p.name.toLowerCase().contains(barcode.toLowerCase()),
          orElse: () => throw StateError('Product not found by name'),
        );
        debugPrint('تم العثور على منتج بالاسم: ${product.name}');
        return product;
      } catch (e) {
        debugPrint('لم يتم العثور على منتج بالاسم أيضاً: $barcode');
      }
    }

    // البحث في المخزون
    try {
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;

      // البحث الدقيق بالباركود أولاً
      InventoryItem? inventoryItem;
      try {
        inventoryItem = inventoryItems.firstWhere(
          (InventoryItem item) => item.barcode == barcode,
          orElse: () => throw StateError('Inventory item not found'),
        );
      } catch (e) {
        // البحث البديل بالاسم إذا فشل البحث بالباركود
        debugPrint('البحث بالباركود فشل، البحث بالاسم: $barcode');
        inventoryItem = inventoryItems.firstWhere(
          (InventoryItem item) =>
              item.name.toLowerCase().contains(barcode.toLowerCase()),
          orElse: () => throw StateError('Inventory item not found by name'),
        );
      }

      // تحويل عنصر المخزون إلى منتج
      final Product productFromInventory = Product(
        id: inventoryItem.id,
        name: inventoryItem.name,
        wholesalePrice: inventoryItem.wholesalePrice,
        retailPrice: inventoryItem.retailPrice, // استخدام سعر التجزئة
        savedAt: DateTime.now(),
        barcode: inventoryItem.barcode, // إضافة الباركود
      );

      debugPrint(
          '✅ تم العثور على المنتج في المخزون: ${productFromInventory.name}');
      return productFromInventory;
    } catch (e) {
      debugPrint('❌ لم يتم العثور على عنصر مخزون بالباركود: $barcode');
    }

    debugPrint('❌ فشل في العثور على المنتج بالباركود: $barcode');
    return null;
  }

  /// مساعدة في التشخيص: طباعة حالة السلة والمخزون
  static void debugCartAndInventoryState(
    List<CartItem> cart,
    StreamInventoryProvider inventoryProvider,
    String barcode,
  ) {
    debugPrint('🔍 === تشخيص حالة السلة والمخزون ===');
    debugPrint('📦 الباركود: $barcode');

    // حالة السلة
    final List<CartItem> matchingItems =
        cart.where((item) => item.barcode == barcode).toList();
    if (matchingItems.isNotEmpty) {
      final int totalInCart =
          matchingItems.fold(0, (sum, item) => sum + item.quantity);
      debugPrint('🛒 الكمية في السلة: $totalInCart');
      for (final CartItem item in matchingItems) {
        debugPrint('   - ${item.name}: ${item.quantity}');
      }
    } else {
      debugPrint('🛒 المنتج غير موجود في السلة');
    }

    // حالة المخزون
    final List<InventoryItem> inventoryItems = inventoryProvider.inventoryItems;
    final List<InventoryItem> matchingInventory =
        inventoryItems.where((item) => item.barcode == barcode).toList();
    if (matchingInventory.isNotEmpty) {
      for (final InventoryItem item in matchingInventory) {
        debugPrint('📊 المخزون: ${item.name} - الكمية: ${item.quantity}');
      }
    } else {
      debugPrint('📊 المنتج غير موجود في المخزون');
    }

    debugPrint('🔍 === نهاية التشخيص ===');
  }

  /// البحث عن عنصر مخزون بالباركود
  static Future<InventoryItem?> findInventoryItemByBarcode(
    StreamInventoryProvider inventoryProvider,
    String barcode,
  ) async {
    try {
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;
      return inventoryItems.firstWhere(
        (InventoryItem item) => item.barcode == barcode,
        orElse: () => throw StateError('Inventory item not found'),
      );
    } catch (e) {
      debugPrint('لم يتم العثور على عنصر مخزون بالباركود: $barcode');
      return null;
    }
  }

  /// إضافة منتج إلى السلة (للتوافق مع POSTab)
  static Future<CartItem?> addProductToCart(
    StreamProductProvider productProvider,
    StreamInventoryProvider inventoryProvider,
    String barcode,
  ) async {
    final Product? product =
        await findProductByBarcode(productProvider, inventoryProvider, barcode);
    if (product == null) {
      return null;
    }
    return CartItem.fromProduct(product);
  }

  /// إتمام عملية البيع (للتوافق مع POSTab)
  static Future<String> completeSale(
    StreamProductProvider productProvider,
    StreamInventoryProvider inventoryProvider,
    List<CartItem> cart,
    String customerName,
    String paymentMethod,
    int discount,
    String notes,
  ) async =>
      await saveSale(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
        cart: cart,
        customerName: customerName.isEmpty ? null : customerName,
        paymentMethod: paymentMethod,
        discount: discount,
        notes: notes.isEmpty ? null : notes,
      );

  /// حساب CartItem لإضافة منتج إلى السلة (لا يعدل currentCart)
  static Future<CartItem> addToCart({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String barcode,
    required List<CartItem> currentCart,
    int quantity = 1,
  }) async {
    // البحث عن المنتج
    final Product? product =
        await findProductByBarcode(productProvider, inventoryProvider, barcode);
    if (product == null) {
      throw Exception('المنتج غير موجود');
    }

    // التحقق من وجود المنتج في السلة
    final int existingIndex = currentCart.indexWhere(
      (CartItem item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // تحديث الكمية إذا كان المنتج موجود
      final CartItem existingItem = currentCart[existingIndex];
      // ✅ إرجاع عنصر بالكمية المطلوب إضافتها فقط، وليس الإجمالي
      final CartItem itemToAdd = existingItem.copyWith(
        quantity: quantity, // فقط الكمية الجديدة المطلوب إضافتها
      );
      // ✅ لا نعدل currentCart - نترك للمستدعي إدارة السلة
      return itemToAdd;
    } else {
      // إضافة منتج جديد إلى السلة
      final CartItem newItem =
          CartItem.fromProduct(product, quantity: quantity);
      // ✅ لا نعدل currentCart - نترك للمستدعي إدارة السلة
      return newItem;
    }
  }

  /// تحديث كمية منتج في السلة
  static void updateCartItemQuantity({
    required List<CartItem> cart,
    required String productId,
    required int newQuantity,
  }) {
    if (newQuantity <= 0) {
      cart.removeWhere((CartItem item) => item.productId == productId);
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

  /// حفظ عملية البيع
  static Future<String> saveSale({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required List<CartItem> cart,
    String? customerName,
    String? notes,
    String paymentMethod = 'نقدي',
    int discount = 0,
  }) async {
    if (cart.isEmpty) {
      throw Exception('السلة فارغة');
    }

    final int totalAmount = calculateCartTotal(cart);
    final int totalProfit = calculateCartProfit(cart);

    final Sale sale = Sale(
      id: _uuid.v4(),
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
      // حفظ في Firestore
      await FirebaseFirestore.instance
          .collection(_salesCollection)
          .doc(sale.id)
          .set(sale.toMap());

      // لا نحتاج تحديث المخزون هنا لأنه محدث مسبقاً في POS

      debugPrint('تم حفظ عملية البيع بنجاح: ${sale.id}');
      return sale.id!;
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'حفظ عملية البيع في POS',
        context: <String, dynamic>{
          'operation': 'saveSale',
          'cartItems': cart.length,
          'totalAmount': sale.totalAmount,
          'customerName': sale.customerName,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'حفظ عملية البيع في POS',
        context: <String, dynamic>{
          'operation': 'saveSale',
          'cartItems': cart.length,
          'totalAmount': sale.totalAmount,
          'customerName': sale.customerName,
        },
      );
      rethrow;
    }
  }

  /// الحصول على جميع عمليات البيع
  static Future<List<Sale>> getAllSales() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection(_salesCollection)
              .orderBy('saleDate', descending: true)
              .get();

      return snapshot.docs.map(Sale.fromFirestore).toList();
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'جلب جميع عمليات البيع',
        context: <String, dynamic>{
          'operation': 'getAllSales',
        },
      );
      return <Sale>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'جلب جميع عمليات البيع',
        context: <String, dynamic>{
          'operation': 'getAllSales',
        },
      );
      return <Sale>[];
    }
  }

  /// التحميل التدريجي لعمليات البيع
  static Future<PageResult<Sale>> getSalesPage({
    int limit = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(_salesCollection)
          .orderBy('saleDate', descending: true)
          .limit(limit);

      if (startDate != null && endDate != null) {
        query = query
            .where('saleDate', isGreaterThanOrEqualTo: startDate)
            .where('saleDate', isLessThanOrEqualTo: endDate);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<Sale> items = snapshot.docs.map(Sale.fromFirestore).toList();
      final DocumentSnapshot<Map<String, dynamic>>? lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final bool hasMore = snapshot.docs.length == limit;

      return PageResult<Sale>(
        items: items,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'التحميل التدريجي للمبيعات',
        context: <String, dynamic>{
          'operation': 'getSalesPage',
          'limit': limit,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      return PageResult<Sale>(
          items: <Sale>[], lastDocument: null, hasMore: false);
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'التحميل التدريجي للمبيعات',
        context: <String, dynamic>{
          'operation': 'getSalesPage',
          'limit': limit,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      return PageResult<Sale>(
          items: <Sale>[], lastDocument: null, hasMore: false);
    }
  }

  /// الحصول على عمليات البيع لفترة محددة
  static Future<List<Sale>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection(_salesCollection)
              .where('saleDate', isGreaterThanOrEqualTo: startDate)
              .where('saleDate', isLessThanOrEqualTo: endDate)
              .orderBy('saleDate', descending: true)
              .get();

      return snapshot.docs.map(Sale.fromFirestore).toList();
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'جلب عمليات البيع للفترة المحددة',
        context: <String, dynamic>{
          'operation': 'getSalesByDateRange',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return <Sale>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'جلب عمليات البيع للفترة المحددة',
        context: <String, dynamic>{
          'operation': 'getSalesByDateRange',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return <Sale>[];
    }
  }

  /// دمج البيانات المحلية والبعيدة في صفحة واحدة
  static Future<PageResult<Sale>> getCombinedSalesPage({
    int limit = defaultPageSize,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // جلب البيانات المحلية غير المزامنة
      final LocalSalesService localSalesService = LocalSalesService();
      List<Sale> localSales = <Sale>[];

      try {
        if (startDate != null && endDate != null) {
          localSales = await localSalesService.getSalesByDateRange(
            startDate: startDate,
            endDate: endDate,
          );
        } else {
          localSales = await localSalesService.getUnsyncedSales();
        }

        // تعيين isSynced = false للبيانات المحلية
        localSales =
            localSales.map((sale) => sale.copyWith(isSynced: false)).toList();
      } catch (e) {
        debugPrint('خطأ في جلب البيانات المحلية: $e');
        localSales = <Sale>[];
      }

      // جلب البيانات من Firestore إذا كان متصل
      List<Sale> firestoreSales = <Sale>[];
      try {
        if (ConnectivityService.isOnline) {
          final PageResult<Sale> firestorePage = await getSalesPage(
            limit: limit,
            startDate: startDate,
            endDate: endDate,
          );
          firestoreSales = firestorePage.items;
        }
      } catch (e) {
        debugPrint('خطأ في جلب البيانات من Firestore: $e');
        firestoreSales = <Sale>[];
      }

      // دمج وإزالة التكرار بناءً على id
      final Map<String, Sale> salesMap = <String, Sale>{};

      // إضافة البيانات من Firestore أولاً (لها أولوية)
      for (final Sale sale in firestoreSales) {
        if (sale.id != null) {
          salesMap[sale.id!] = sale;
        }
      }

      // إضافة البيانات المحلية إذا لم تكن موجودة في Firestore
      for (final Sale sale in localSales) {
        if (sale.id != null && !salesMap.containsKey(sale.id!)) {
          salesMap[sale.id!] = sale;
        }
      }

      // تحويل إلى قائمة وترتيب حسب التاريخ
      final List<Sale> combinedSales = salesMap.values.toList()
        ..sort((Sale a, Sale b) => b.saleDate.compareTo(a.saleDate));

      // تطبيق الحد الأقصى للصفحة
      final List<Sale> paginatedSales = combinedSales.take(limit).toList();
      final bool hasMore = combinedSales.length > limit;

      return PageResult<Sale>(
        items: paginatedSales,
        lastDocument: null, // لا نحتاج lastDocument للبيانات المدمجة
        hasMore: hasMore,
      );
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'دمج البيانات المحلية والبعيدة',
        context: <String, dynamic>{
          'operation': 'getCombinedSalesPage',
          'limit': limit,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      return PageResult<Sale>(
          items: <Sale>[], lastDocument: null, hasMore: false);
    }
  }

  /// إضافة عنصر إلى الجرد السريع
  static Future<QuickInventoryItem> addToQuickInventory({
    required StreamInventoryProvider inventoryProvider,
    required String barcode,
    required int quantity,
    String? notes,
  }) async {
    // البحث عن المنتج
    final InventoryItem? inventoryItem =
        await findInventoryItemByBarcode(inventoryProvider, barcode);

    final QuickInventoryItem quickItem = QuickInventoryItem(
      id: _uuid.v4(),
      barcode: barcode,
      name: inventoryItem?.name ?? 'منتج غير معروف',
      scannedQuantity: quantity,
      scanDate: DateTime.now(),
      originalQuantity: inventoryItem?.quantity,
      wholesalePrice: inventoryItem?.wholesalePrice.round(),
      retailPrice: inventoryItem?.wholesalePrice.round(),
      isNewProduct: inventoryItem == null,
      notes: notes,
    );

    try {
      // حفظ في Firestore
      await FirebaseFirestore.instance
          .collection(_quickInventoryCollection)
          .doc(quickItem.id)
          .set(quickItem.toMap());

      debugPrint('تم إضافة عنصر إلى الجرد السريع: ${quickItem.barcode}');
      return quickItem;
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'إضافة عنصر إلى الجرد السريع',
        context: <String, dynamic>{
          'operation': 'addToQuickInventory',
          'barcode': barcode,
          'quantity': quantity,
          'itemName': quickItem.name,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'إضافة عنصر إلى الجرد السريع',
        context: <String, dynamic>{
          'operation': 'addToQuickInventory',
          'barcode': barcode,
          'quantity': quantity,
          'itemName': quickItem.name,
        },
      );
      rethrow;
    }
  }

  /// الحصول على جميع عناصر الجرد السريع
  static Future<List<QuickInventoryItem>> getAllQuickInventoryItems() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection(_quickInventoryCollection)
              .orderBy('scanDate', descending: true)
              .get();

      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              QuickInventoryItem.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'جلب عناصر الجرد السريع',
        context: <String, dynamic>{
          'operation': 'getAllQuickInventoryItems',
        },
      );
      return <QuickInventoryItem>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'جلب عناصر الجرد السريع',
        context: <String, dynamic>{
          'operation': 'getAllQuickInventoryItems',
        },
      );
      return <QuickInventoryItem>[];
    }
  }

  /// التحميل التدريجي لعناصر الجرد السريع
  static Future<PageResult<QuickInventoryItem>> getQuickInventoryPage({
    int limit = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(_quickInventoryCollection)
          .orderBy('scanDate', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<QuickInventoryItem> items = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              QuickInventoryItem.fromMap(doc.data()))
          .toList();
      final DocumentSnapshot<Map<String, dynamic>>? lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final bool hasMore = snapshot.docs.length == limit;

      return PageResult<QuickInventoryItem>(
        items: items,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'التحميل التدريجي للجرد السريع',
        context: <String, dynamic>{
          'operation': 'getQuickInventoryPage',
          'limit': limit,
        },
      );
      return PageResult<QuickInventoryItem>(
          items: <QuickInventoryItem>[], lastDocument: null, hasMore: false);
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'التحميل التدريجي للجرد السريع',
        context: <String, dynamic>{
          'operation': 'getQuickInventoryPage',
          'limit': limit,
        },
      );
      return PageResult<QuickInventoryItem>(
          items: <QuickInventoryItem>[], lastDocument: null, hasMore: false);
    }
  }

  /// تحديث المخزون من الجرد السريع
  static Future<void> updateInventoryFromQuickInventory(
    StreamInventoryProvider inventoryProvider,
    List<QuickInventoryItem> items,
  ) async {
    for (final QuickInventoryItem item in items) {
      try {
        if (item.isNewProduct) {
          // إضافة منتج جديد
          final InventoryItem newItem = InventoryItem(
            id: _uuid.v4(),
            name: item.name,
            barcode: item.barcode,
            wholesalePrice: item.wholesalePrice ?? 0,
            retailPrice: item.retailPrice ?? 0,
            quantity: item.scannedQuantity,
            originalQuantity: item.scannedQuantity,
            addedDate: DateTime.now(),
            addedTime: DateTime.now(),
          );

          await inventoryProvider.addInventoryItem(newItem);
        } else {
          // تحديث الكمية الموجودة
          final InventoryItem? existingItem =
              await findInventoryItemByBarcode(inventoryProvider, item.barcode);
          if (existingItem != null) {
            final InventoryItem updatedItem = existingItem.copyWith(
              quantity: item.scannedQuantity,
            );

            await inventoryProvider.updateInventoryItem(updatedItem);
          }
        }
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          userAction: 'تحديث المخزون من الجرد السريع',
          context: <String, dynamic>{
            'operation': 'updateInventoryFromQuickInventory',
            'itemName': item.name,
            'itemBarcode': item.barcode,
            'scannedQuantity': item.scannedQuantity,
            'isNewProduct': item.isNewProduct,
          },
        );
        debugPrint('خطأ في تحديث المخزون من الجرد السريع: $e');
      }
    }
  }

  /// حذف عنصر من الجرد السريع
  static Future<void> deleteQuickInventoryItem(String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_quickInventoryCollection)
          .doc(itemId)
          .delete();

      debugPrint('تم حذف عنصر الجرد السريع: $itemId');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'حذف عنصر من الجرد السريع',
        context: <String, dynamic>{
          'operation': 'deleteQuickInventoryItem',
          'itemId': itemId,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'حذف عنصر من الجرد السريع',
        context: <String, dynamic>{
          'operation': 'deleteQuickInventoryItem',
          'itemId': itemId,
        },
      );
      rethrow;
    }
  }

  /// مسح جميع عناصر الجرد السريع
  static Future<void> clearQuickInventory() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection(_quickInventoryCollection)
              .get();

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('تم مسح جميع عناصر الجرد السريع');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'مسح جميع عناصر الجرد السريع',
        context: <String, dynamic>{
          'operation': 'clearQuickInventory',
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'مسح جميع عناصر الجرد السريع',
        context: <String, dynamic>{
          'operation': 'clearQuickInventory',
        },
      );
      rethrow;
    }
  }

  /// خصم كمية من المخزون فوراً
  static Future<void> decreaseInventoryQuantity(
    StreamInventoryProvider inventoryProvider,
    String barcode,
    int quantity,
  ) async {
    try {
      final InventoryItem? inventoryItem =
          await findInventoryItemByBarcode(inventoryProvider, barcode);

      if (inventoryItem != null) {
        final int newQuantity = inventoryItem.quantity - quantity;
        final InventoryItem updatedItem = inventoryItem.copyWith(
          quantity: newQuantity < 0 ? 0 : newQuantity,
        );

        await inventoryProvider.updateInventoryItem(updatedItem);
        debugPrint('تم خصم $quantity من المخزون للمنتج ${inventoryItem.name}');
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'خصم كمية من المخزون',
        context: <String, dynamic>{
          'operation': 'decreaseInventoryQuantity',
          'barcode': barcode,
          'quantity': quantity,
        },
      );
      rethrow;
    }
  }

  /// خصم كمية من المخزون فوراً بالاسم
  static Future<void> decreaseInventoryQuantityByName(
    StreamInventoryProvider inventoryProvider,
    String name,
    int quantity,
  ) async {
    try {
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;

      final InventoryItem? inventoryItem = inventoryItems.firstWhere(
        (InventoryItem item) =>
            item.name.toLowerCase().contains(name.toLowerCase()),
        orElse: () => throw StateError('Inventory item not found'),
      );

      if (inventoryItem != null) {
        final int newQuantity = inventoryItem.quantity - quantity;
        final InventoryItem updatedItem = inventoryItem.copyWith(
          quantity: newQuantity < 0 ? 0 : newQuantity,
        );
        await inventoryProvider.updateInventoryItem(updatedItem);
        debugPrint(
            'تم خصم $quantity من المخزون للمنتج ${inventoryItem.name} بالاسم');
      }
    } catch (e) {
      debugPrint('❌ خطأ في خصم الكمية بالاسم: $e');
      rethrow;
    }
  }

  /// إرجاع كمية إلى المخزون فوراً
  static Future<void> increaseInventoryQuantity(
    StreamInventoryProvider inventoryProvider,
    String barcode,
    int quantity,
  ) async {
    try {
      final InventoryItem? inventoryItem =
          await findInventoryItemByBarcode(inventoryProvider, barcode);

      if (inventoryItem != null) {
        final int newQuantity = inventoryItem.quantity + quantity;
        final InventoryItem updatedItem = inventoryItem.copyWith(
          quantity: newQuantity,
        );

        await inventoryProvider.updateInventoryItem(updatedItem);
        debugPrint(
            'تم إرجاع $quantity إلى المخزون للمنتج ${inventoryItem.name}');
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'إرجاع كمية إلى المخزون',
        context: <String, dynamic>{
          'operation': 'increaseInventoryQuantity',
          'barcode': barcode,
          'quantity': quantity,
        },
      );
      rethrow;
    }
  }

  /// الحصول على الكمية المتوفرة في المخزون بالباركود
  static Future<int> getAvailableQuantity(
    StreamInventoryProvider inventoryProvider,
    String barcode,
  ) async {
    try {
      final InventoryItem? inventoryItem =
          await findInventoryItemByBarcode(inventoryProvider, barcode);

      if (inventoryItem != null) {
        debugPrint(
            '📊 تفاصيل المخزون: ${inventoryItem.name} - الكمية: ${inventoryItem.quantity}');
        return inventoryItem.quantity;
      }
      debugPrint('⚠️ لم يتم العثور على عنصر مخزون للباركود: $barcode');
      return 0;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'الحصول على الكمية المتوفرة',
        context: <String, dynamic>{
          'operation': 'getAvailableQuantity',
          'barcode': barcode,
        },
      );
      return 0;
    }
  }

  /// الحصول على الكمية المتوفرة في المخزون بالاسم
  static Future<int> getAvailableQuantityByName(
    StreamInventoryProvider inventoryProvider,
    String name,
  ) async {
    try {
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;

      final InventoryItem? inventoryItem = inventoryItems.firstWhere(
        (InventoryItem item) =>
            item.name.toLowerCase().contains(name.toLowerCase()),
        orElse: () => throw StateError('Inventory item not found'),
      );

      if (inventoryItem != null) {
        debugPrint(
            '📊 تفاصيل المخزون بالاسم: ${inventoryItem.name} - الكمية: ${inventoryItem.quantity}');
        return inventoryItem.quantity;
      }
      debugPrint('⚠️ لم يتم العثور على عنصر مخزون بالاسم: $name');
      return 0;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الكمية المتوفرة بالاسم: $e');
      return 0;
    }
  }

  /// إضافة منتج إلى السلة بالاسم مع التحقق من صحة البيانات
  static Future<CartItem?> addProductToCartByNameWithValidation({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String name,
    required List<CartItem> currentCart,
    int quantity = 1,
  }) async {
    try {
      debugPrint('🛒 محاولة إضافة منتج للسلة بالاسم: $name بكمية $quantity');

      // البحث عن المنتج بالاسم
      final Product? product = await findProductByName(
        productProvider,
        inventoryProvider,
        name,
      );

      if (product == null) {
        throw Exception('لم يتم العثور على منتج بالاسم: $name');
      }

      // التحقق من توفر الكمية في المخزون بالاسم
      final int availableQuantity = await getAvailableQuantityByName(
        inventoryProvider,
        name,
      );

      if (availableQuantity < quantity) {
        throw Exception(
          'الكمية المطلوبة ($quantity) غير متوفرة. المتوفر: $availableQuantity',
        );
      }

      // البحث عن المنتج في السلة الحالية
      final CartItem? existingItem =
          currentCart.where((item) => item.productId == product.id).firstOrNull;

      if (existingItem != null) {
        // تحديث الكمية إذا كان المنتج موجود بالفعل
        final CartItem updatedItem = CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          barcode: existingItem.barcode,
          wholesalePrice: existingItem.wholesalePrice,
          retailPrice: existingItem.retailPrice,
          quantity: existingItem.quantity + quantity,
          discount: existingItem.discount,
        );
        debugPrint('✅ تم تحديث كمية المنتج في السلة: ${updatedItem.name}');
        return updatedItem;
      } else {
        // إضافة منتج جديد للسلة
        final CartItem newItem = CartItem(
          productId: product.id ?? 'unknown',
          name: product.name,
          barcode: product.barcode ?? product.id ?? 'unknown',
          wholesalePrice: product.wholesalePrice,
          retailPrice: product.retailPrice,
          quantity: quantity,
          discount: 0,
        );
        debugPrint('✅ تم إضافة منتج جديد للسلة: ${newItem.name}');
        return newItem;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج للسلة بالاسم: $e');
      rethrow;
    }
  }

  /// التحقق من إمكانية إضافة منتج للسلة مع حساب الكمية المطلوبة
  ///
  /// المنطق المحدث:
  /// 1. عند إضافة منتج جديد: نتحقق من أن الكمية المطلوبة متوفرة في المخزون
  /// 2. عند إضافة كمية لمنتج موجود: نتحقق من الكمية الجديدة فقط
  ///    لأن الكمية الموجودة في السلة مخصومة بالفعل من المخزون
  /// 3. إرجاع CartItem جاهز للإضافة - لا يعدل currentCart
  static Future<CartItem?> addProductToCartWithValidation({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required String barcode,
    required List<CartItem> currentCart,
    int quantity = 1,
  }) async {
    try {
      debugPrint('🛒 محاولة إضافة منتج للسلة: $barcode بكمية $quantity');
      debugPrint(
          '🛒 Platform: ${Platform.isWindows ? "Windows" : Platform.isAndroid ? "Android" : "Other"}');

      // البحث عن المنتج أولاً
      final Product? product = await findProductByBarcode(
          productProvider, inventoryProvider, barcode);
      if (product == null) {
        throw Exception('المنتج غير موجود');
      }

      // التحقق من الكمية المتوفرة في المخزون
      final int availableQuantity =
          await getAvailableQuantity(inventoryProvider, barcode);

      if (availableQuantity <= 0) {
        throw Exception('المنتج نفذ من المخزون');
      }

      debugPrint('📦 الكمية المتوفرة في المخزون: $availableQuantity');

      // تسجيل حالة السلة الحالية للمساعدة في التشخيص
      final int currentCartQuantity = currentCart
          .where((item) => item.productId == product.id)
          .fold(0, (sum, item) => sum + item.quantity);
      debugPrint('🛒 الكمية الحالية في السلة: $currentCartQuantity');

      // تشخيص مفصل للحالة
      debugCartAndInventoryState(currentCart, inventoryProvider, barcode);

      // التحقق من وجود المنتج في السلة
      final int existingIndex = currentCart.indexWhere(
        (CartItem item) => item.productId == product.id,
      );

      if (existingIndex != -1) {
        // المنتج موجود بالفعل في السلة
        final CartItem existingItem = currentCart[existingIndex];

        debugPrint('🔄 المنتج موجود في السلة بكمية: ${existingItem.quantity}');
        debugPrint('📦 الكمية المتوفرة في المخزون الآن: $availableQuantity');
        debugPrint('➕ الكمية المطلوب إضافتها: $quantity');

        // ✅ التحقق الصحيح: هل الكمية الجديدة المطلوبة متوفرة في المخزون؟
        // ملاحظة: الكمية الموجودة في السلة مخصومة بالفعل من المخزون
        if (quantity > availableQuantity) {
          throw Exception(
              'الكمية المطلوبة ($quantity) تتجاوز المتوفر ($availableQuantity)\n'
              'ملاحظة: يوجد ${existingItem.quantity} في السلة بالفعل');
        }

        // تحديث الكمية في السلة
        final int newCartQuantity = existingItem.quantity + quantity;
        debugPrint('✅ الكمية الجديدة في السلة ستكون: $newCartQuantity');

        // ✅ إرجاع عنصر جديد من المنتج بالكمية المطلوب إضافتها فقط
        // هذا يضمن عدم وجود مشاكل في المقارنة أو الحالة بين المنصات
        final CartItem itemToAdd =
            CartItem.fromProduct(product, quantity: quantity);
        // ✅ لا نعدل currentCart - نترك للمستدعي إدارة السلة
        debugPrint(
            '🛒 إرجاع CartItem محدث: ${itemToAdd.name} (qty: ${itemToAdd.quantity})');
        return itemToAdd;
      } else {
        // إضافة منتج جديد إلى السلة
        debugPrint('🆕 إضافة منتج جديد إلى السلة بكمية: $quantity');

        // التحقق من توفر الكمية المطلوبة
        if (quantity > availableQuantity) {
          throw Exception(
              'الكمية المطلوبة ($quantity) تتجاوز المتوفر ($availableQuantity)');
        }

        final CartItem newItem =
            CartItem.fromProduct(product, quantity: quantity);
        // ✅ لا نعدل currentCart - نترك للمستدعي إدارة السلة
        debugPrint(
            '🛒 إرجاع CartItem جديد: ${newItem.name} (qty: ${newItem.quantity})');
        return newItem;
      }
    } on Exception catch (e) {
      debugPrint('خطأ في إضافة المنتج للسلة: $e');
      rethrow;
    }
  }

  // ========== دوال Firebase للسلة ==========

  /// حفظ السلة في Firebase
  static Future<void> saveCartToFirebase({
    required List<CartItem> cart,
    required String sessionId,
    String? userId,
  }) async {
    try {
      final Map<String, dynamic> cartData = {
        'sessionId': sessionId,
        'userId': userId,
        'items': cart.map((item) => item.toMap()).toList(),
        'totalAmount': calculateCartTotal(cart),
        'totalProfit': calculateCartProfit(cart),
        'itemCount': cart.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(_posCartsCollection)
          .doc(sessionId)
          .set(cartData, SetOptions(merge: true));

      debugPrint('✅ تم حفظ السلة في Firebase: $sessionId');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.medium,
        userAction: 'حفظ السلة في Firebase',
        context: <String, dynamic>{
          'operation': 'saveCartToFirebase',
          'sessionId': sessionId,
          'itemCount': cart.length,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        userAction: 'حفظ السلة في Firebase',
        context: <String, dynamic>{
          'operation': 'saveCartToFirebase',
          'sessionId': sessionId,
          'itemCount': cart.length,
        },
      );
      rethrow;
    }
  }

  /// استعادة السلة من Firebase
  static Future<List<CartItem>> loadCartFromFirebase({
    required String sessionId,
    String? userId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection(_posCartsCollection)
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        debugPrint('ℹ️ لا توجد سلة محفوظة للجلسة: $sessionId');
        return <CartItem>[];
      }

      final Map<String, dynamic> data = doc.data()!;
      final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];

      final List<CartItem> cart = itemsData
          .map((itemData) => CartItem.fromMap(itemData as Map<String, dynamic>))
          .toList();

      debugPrint('✅ تم استعادة السلة من Firebase: ${cart.length} عنصر');
      return cart;
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.medium,
        userAction: 'استعادة السلة من Firebase',
        context: <String, dynamic>{
          'operation': 'loadCartFromFirebase',
          'sessionId': sessionId,
        },
      );
      return <CartItem>[];
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        userAction: 'استعادة السلة من Firebase',
        context: <String, dynamic>{
          'operation': 'loadCartFromFirebase',
          'sessionId': sessionId,
        },
      );
      return <CartItem>[];
    }
  }

  /// حذف السلة من Firebase
  static Future<void> deleteCartFromFirebase({
    required String sessionId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_posCartsCollection)
          .doc(sessionId)
          .delete();

      debugPrint('✅ تم حذف السلة من Firebase: $sessionId');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        userAction: 'حذف السلة من Firebase',
        context: <String, dynamic>{
          'operation': 'deleteCartFromFirebase',
          'sessionId': sessionId,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        userAction: 'حذف السلة من Firebase',
        context: <String, dynamic>{
          'operation': 'deleteCartFromFirebase',
          'sessionId': sessionId,
        },
      );
      rethrow;
    }
  }

  /// الاستماع لتغييرات السلة في Firebase
  static Stream<List<CartItem>> watchCartFromFirebase({
    required String sessionId,
    String? userId,
  }) {
    return FirebaseFirestore.instance
        .collection(_posCartsCollection)
        .doc(sessionId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists) {
        return <CartItem>[];
      }

      final Map<String, dynamic> data = snapshot.data()!;
      final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];

      return itemsData
          .map((itemData) => CartItem.fromMap(itemData as Map<String, dynamic>))
          .toList();
    });
  }

  /// حفظ جلسة POS في Firebase
  static Future<void> savePOSSession({
    required String sessionId,
    String? userId,
    String? deviceInfo,
    String? platform,
  }) async {
    try {
      final Map<String, dynamic> sessionData = {
        'sessionId': sessionId,
        'userId': userId,
        'deviceInfo': deviceInfo,
        'platform': platform,
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(_posCollection)
          .doc(sessionId)
          .set(sessionData, SetOptions(merge: true));

      debugPrint('✅ تم حفظ جلسة POS في Firebase: $sessionId');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.medium,
        userAction: 'حفظ جلسة POS في Firebase',
        context: <String, dynamic>{
          'operation': 'savePOSSession',
          'sessionId': sessionId,
          'platform': platform,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        userAction: 'حفظ جلسة POS في Firebase',
        context: <String, dynamic>{
          'operation': 'savePOSSession',
          'sessionId': sessionId,
          'platform': platform,
        },
      );
      rethrow;
    }
  }

  /// إنهاء جلسة POS في Firebase
  static Future<void> endPOSSession({
    required String sessionId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_posCollection)
          .doc(sessionId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ تم إنهاء جلسة POS في Firebase: $sessionId');
    } on FirebaseException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        userAction: 'إنهاء جلسة POS في Firebase',
        context: <String, dynamic>{
          'operation': 'endPOSSession',
          'sessionId': sessionId,
        },
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        userAction: 'إنهاء جلسة POS في Firebase',
        context: <String, dynamic>{
          'operation': 'endPOSSession',
          'sessionId': sessionId,
        },
      );
      rethrow;
    }
  }
}
