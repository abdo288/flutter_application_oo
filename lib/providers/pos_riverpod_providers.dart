import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/drift_database.dart';
import '../models/cart_item.dart';
import '../services/app_event_bus.dart';

/// Re-export providers from riverpod folder for compatibility
export 'riverpod/cart_riverpod_provider.dart';

/// حالة السلة للـ Riverpod
class CartState {
  const CartState({
    required this.cart,
    this.isInitialized = false,
    this.isLoading = false,
    this.errorMessage,
  });
  final List<CartItem> cart;
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;

  CartState copyWith({
    List<CartItem>? cart,
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CartState(
        cart: cart ?? this.cart,
        isInitialized: isInitialized ?? this.isInitialized,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  // Getters للراحة
  bool get isEmpty => cart.isEmpty;
  bool get isNotEmpty => cart.isNotEmpty;
  int get itemCount => cart.length;
  int get totalAmount =>
      cart.fold(0, (int sum, CartItem item) => sum + item.totalPrice);
  int get totalProfit =>
      cart.fold(0, (int sum, CartItem item) => sum + item.totalProfit);
  int get totalQuantity =>
      cart.fold(0, (int sum, CartItem item) => sum + item.quantity);
}

/// CartNotifier لإدارة حالة السلة باستخدام Riverpod
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState(cart: <CartItem>[]));
  // مفاتيح SharedPreferences
  static const String _cartKey = 'cart_items';
  static const String _cartTimestampKey = 'cart_timestamp';

  // متغيرات الحفظ
  SharedPreferences? _prefs;
  StreamSubscription<AppEvent>? _eventSubscription;

  /// تهيئة CartNotifier
  Future<void> initialize() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCartFromStorage();

      // إعداد الاستماع للأحداث
      _setupEventListeners();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );

      debugPrint('🛒 تم تهيئة CartNotifier بنجاح');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تهيئة السلة: $e',
      );
      debugPrint('❌ خطأ في تهيئة CartNotifier: $e');
    }
  }

  /// إعداد الاستماع للأحداث
  void _setupEventListeners() {
    // إلغاء الاشتراك السابق إذا كان موجوداً
    _eventSubscription?.cancel();

    // الاستماع لأحداث المخزون لتحديث السلة
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case InventoryUpdatedEvent:
          _handleInventoryUpdated(event as InventoryUpdatedEvent);
          break;
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
      }
    });
  }

  /// معالجة تحديث المخزون
  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    debugPrint('🔄 CartState: تحديث المخزون - ${event.itemName}');

    // التحقق من وجود المنتج في السلة وتحديث الكمية المتاحة
    final List<CartItem> updatedCart = state.cart.map((CartItem item) {
      if (item.productId == event.itemId) {
        // تحديث الكمية المتاحة في السلة
        return item.copyWith(
          quantity: event.newQuantity,
        );
      }
      return item;
    }).toList();

    if (updatedCart != state.cart) {
      state = state.copyWith(cart: updatedCart);
      _saveCartToStorage();
    }
  }

  /// معالجة إتمام البيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint('🔄 CartState: إتمام بيع - ${event.sale.totalAmount}');

    // مسح السلة بعد إتمام البيع
    clearCart();
  }

  /// حفظ السلة في SharedPreferences
  Future<void> _saveCartToStorage() async {
    if (_prefs == null) return;

    try {
      // تحويل السلة إلى JSON
      final List<Map<String, dynamic>> cartJson =
          state.cart.map((CartItem item) => item.toMap()).toList();
      final String cartString = jsonEncode(cartJson);

      // حفظ السلة والوقت
      await _prefs!.setString(_cartKey, cartString);
      await _prefs!
          .setString(_cartTimestampKey, DateTime.now().toIso8601String());

      debugPrint('💾 تم حفظ السلة في SharedPreferences');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة: $e');
    }
  }

  /// استعادة السلة من SharedPreferences
  Future<void> _loadCartFromStorage() async {
    if (_prefs == null) return;

    try {
      final String? cartString = _prefs!.getString(_cartKey);
      if (cartString != null && cartString.isNotEmpty) {
        final List<dynamic> cartJson = jsonDecode(cartString) as List<dynamic>;
        final List<CartItem> loadedCart = <CartItem>[];

        for (final dynamic itemData in cartJson) {
          final Map<String, dynamic> itemJson =
              itemData as Map<String, dynamic>;
          try {
            final CartItem item = CartItem.fromMap(itemJson);
            loadedCart.add(item);
          } catch (e) {
            debugPrint('❌ خطأ في تحويل عنصر السلة: $e');
          }
        }

        // التحقق من صحة البيانات المحملة
        final List<CartItem> validatedCart =
            await _validateCartItems(loadedCart);

        state = state.copyWith(cart: validatedCart);
        debugPrint('📦 تم استعادة ${validatedCart.length} عنصر من السلة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في استعادة السلة: $e');
    }
  }

  /// التحقق من صحة عناصر السلة
  Future<List<CartItem>> _validateCartItems(List<CartItem> cart) async {
    final List<CartItem> validItems = <CartItem>[];

    for (final CartItem item in cart) {
      try {
        // التحقق من صحة البيانات الأساسية
        if (item.productId.isEmpty ||
            item.name.isEmpty ||
            item.retailPrice <= 0) {
          debugPrint('⚠️ عنصر غير صالح في السلة: ${item.name}');
          continue;
        }

        // التحقق من وجود المنتج في قاعدة البيانات
        final bool productExists = await _checkProductExists(item.productId);
        if (!productExists) {
          debugPrint('⚠️ منتج غير موجود في قاعدة البيانات: ${item.name}');
          continue;
        }

        // التحقق من الكمية المتاحة
        final int availableQuantity =
            await _getAvailableQuantity(item.productId);
        if (item.quantity > availableQuantity) {
          debugPrint(
              '⚠️ كمية غير متاحة للمنتج: ${item.name} (مطلوب: ${item.quantity}, متاح: $availableQuantity)');
          // تعديل الكمية إلى المتاح
          final CartItem adjustedItem = item.copyWith(
            quantity: availableQuantity,
          );
          validItems.add(adjustedItem);
        } else {
          validItems.add(item);
        }
      } catch (e) {
        debugPrint('❌ خطأ في التحقق من العنصر: ${item.name} - $e');
        continue;
      }
    }

    // إذا تغيرت السلة، احفظها
    if (validItems.length != cart.length) {
      debugPrint(
          '🔄 تم تنظيف السلة: ${cart.length} → ${validItems.length} عنصر');
      state = state.copyWith(cart: validItems);
      await _saveCartToStorage();
    }

    return validItems;
  }

  /// التحقق من وجود المنتج
  Future<bool> _checkProductExists(String productId) async {
    try {
      // استخدام Local Database للتحقق من وجود المنتج
      final AppDatabase localDb = AppDatabase.instance;
      final List<ProductsTableData> products =
          await (localDb.select(localDb.productsTable)
                ..where(($ProductsTableTable t) => t.id.equals(productId)))
              .get();
      return products.isNotEmpty;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود المنتج: $e');
      return false;
    }
  }

  /// الحصول على الكمية المتاحة
  Future<int> _getAvailableQuantity(String productId) async {
    try {
      final AppDatabase localDb = AppDatabase.instance;
      final List<InventoryTableData> items =
          await (localDb.select(localDb.inventoryTable)
                ..where(($InventoryTableTable t) => t.id.equals(productId)))
              .get();
      return items.isNotEmpty ? items.first.quantity : 0;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الكمية المتاحة: $e');
      return 0;
    }
  }

  /// مسح السلة المحفوظة
  Future<void> _clearStoredCart() async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove(_cartKey);
      await _prefs!.remove(_cartTimestampKey);
      debugPrint('🗑️ تم مسح السلة المحفوظة');
    } catch (e) {
      debugPrint('❌ خطأ في مسح السلة المحفوظة: $e');
    }
  }

  /// حفظ السلة يدوياً (للاستخدام الخارجي)
  Future<void> saveCartManually() async {
    await _saveCartToStorage();
  }

  /// إضافة عنصر إلى السلة
  void addItem(CartItem item) {
    debugPrint('🛒 CartNotifier.addItem called');
    debugPrint('   - Item: ${item.name}');
    debugPrint('   - Quantity: ${item.quantity}');
    debugPrint('   - Current cart size: ${state.cart.length}');

    final List<CartItem> newCart = List<CartItem>.from(state.cart);

    // البحث عن منتج بنفس productId و نفس الخصم
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      // المنتج موجود بنفس الخصم - زيادة الكمية
      debugPrint('   ✅ Product exists, updating quantity');
      final int oldQuantity = newCart[index].quantity;
      newCart[index] = newCart[index]
          .copyWith(quantity: newCart[index].quantity + item.quantity);
      debugPrint(
          '   - Old quantity: $oldQuantity, New quantity: ${newCart[index].quantity}');
    } else {
      // منتج جديد أو نفس المنتج بخصم مختلف - إضافته كعنصر منفصل
      debugPrint('   ✅ New product, adding to cart');
      newCart.add(item);
    }

    debugPrint('   - New cart size: ${newCart.length}');

    // ✅ تحديث الحالة بنسخة جديدة من القائمة
    final CartState oldState = state;
    state = state.copyWith(cart: newCart);

    debugPrint('   📊 State updated:');
    debugPrint('      - Old state cart length: ${oldState.cart.length}');
    debugPrint('      - New state cart length: ${state.cart.length}');
    debugPrint(
        '      - State hashCode changed: ${oldState.hashCode != state.hashCode}');

    _saveCartToStorage(); // حفظ السلة تلقائياً

    debugPrint('✅ CartNotifier.addItem completed successfully');
  }

  /// تحديث كمية منتج في السلة
  void updateQuantity(String productId, int newQuantity, {int discount = 0}) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == productId && element.discount == discount);

    if (index != -1) {
      if (newQuantity > 0) {
        newCart[index] = newCart[index].copyWith(quantity: newQuantity);
      } else {
        newCart.removeAt(index);
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// تحديث كمية عنصر محدد في السلة
  void updateQuantityForItem(CartItem item, int newQuantity) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      if (newQuantity > 0) {
        newCart[index] = newCart[index].copyWith(quantity: newQuantity);
      } else {
        newCart.removeAt(index);
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = newCart.indexWhere((CartItem element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        if (newQuantity > 0) {
          newCart[barcodeIndex] =
              newCart[barcodeIndex].copyWith(quantity: newQuantity);
        } else {
          newCart.removeAt(barcodeIndex);
        }
        state = state.copyWith(cart: newCart);
        _saveCartToStorage(); // حفظ السلة تلقائياً
      }
    }
  }

  /// تحديث كمية عنصر بناءً على الاسم (للمنتجات المخصومة)
  void updateQuantityForItemByName(String name, int newQuantity) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere(
        (CartItem element) => element.name.toLowerCase() == name.toLowerCase());

    if (index != -1) {
      if (newQuantity > 0) {
        newCart[index] = newCart[index].copyWith(quantity: newQuantity);
      } else {
        newCart.removeAt(index);
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// حذف عنصر من السلة
  void removeItem(String productId, {int discount = 0}) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    newCart.removeWhere((CartItem element) =>
        element.productId == productId && element.discount == discount);
    state = state.copyWith(cart: newCart);
    _saveCartToStorage(); // حفظ السلة تلقائياً
  }

  /// حذف عنصر محدد من السلة
  void removeItemByObject(CartItem item) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      newCart.removeAt(index);
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = newCart.indexWhere((CartItem element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        newCart.removeAt(barcodeIndex);
        state = state.copyWith(cart: newCart);
        _saveCartToStorage(); // حفظ السلة تلقائياً
      }
    }
  }

  /// مسح السلة بالكامل
  void clearCart() {
    state = state.copyWith(cart: <CartItem>[]);
    _saveCartToStorage(); // حفظ السلة تلقائياً
    _clearStoredCart(); // مسح السلة المحفوظة أيضاً
  }

  /// تنظيف الموارد
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// تطبيق خصم على منتج
  void applyDiscount(String productId, int discount) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart
        .indexWhere((CartItem element) => element.productId == productId);
    if (index != -1) {
      final CartItem oldItem = newCart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان الخصم مختلف، نحذف العنصر القديم ونضيف واحد جديد
      if (oldDiscount != discount) {
        newCart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: discount);
        newCart.add(newItem);
      } else {
        // نفس الخصم - تحديث مباشر
        newCart[index] = oldItem.copyWith(discount: discount);
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// تطبيق خصم على عنصر محدد في السلة
  void applyDiscountToItem(CartItem item, int discount) {
    debugPrint('🔍 تطبيق خصم على المنتج: ${item.productId}');
    debugPrint('🔍 اسم المنتج: ${item.name}');
    debugPrint('🔍 الخصم الجديد: $discount');
    debugPrint('🔍 الخصم الحالي: ${item.discount}');

    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    // البحث عن العنصر باستخدام productId فقط (بدون discount و quantity)
    final int index = newCart
        .indexWhere((CartItem element) => element.productId == item.productId);

    debugPrint('🔍 فهرس العنصر الموجود: $index');
    debugPrint('🔍 عدد العناصر في السلة: ${newCart.length}');

    if (index != -1) {
      final CartItem oldItem = newCart[index];
      final int oldDiscount = oldItem.discount;

      debugPrint('🔍 العنصر القديم: ${oldItem.name}');
      debugPrint('🔍 الخصم القديم: $oldDiscount');

      // إذا كان الخصم مختلف، نحذف العنصر القديم ونضيف واحد جديد
      if (oldDiscount != discount) {
        newCart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: discount);
        newCart.add(newItem);
        debugPrint('✅ تم حذف العنصر القديم وإضافة عنصر جديد بالخصم: $discount');
      } else {
        // نفس الخصم - تحديث مباشر
        newCart[index] = oldItem.copyWith(discount: discount);
        debugPrint('✅ تم تحديث الخصم مباشرة: $discount');
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
      debugPrint('✅ تم حفظ السلة بنجاح');
    } else {
      debugPrint('❌ لم يتم العثور على المنتج في السلة');
    }
  }

  /// إلغاء الخصم على منتج
  void removeDiscount(String productId) {
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart
        .indexWhere((CartItem element) => element.productId == productId);
    if (index != -1) {
      final CartItem oldItem = newCart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان هناك خصم، نحذف العنصر القديم ونضيف واحد جديد بدون خصم
      if (oldDiscount > 0) {
        newCart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: 0);
        newCart.add(newItem);
      } else {
        // لا يوجد خصم - تحديث مباشر
        newCart[index] = oldItem.copyWith(discount: 0);
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// إلغاء الخصم على عنصر محدد في السلة
  void removeDiscountFromItem(CartItem item) {
    debugPrint('🗑️ إلغاء خصم من المنتج: ${item.productId}');
    debugPrint('🗑️ اسم المنتج: ${item.name}');
    debugPrint('🗑️ الخصم الحالي: ${item.discount}');
    debugPrint('🗑️ الكمية: ${item.quantity}');

    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    // البحث عن العنصر المحدد باستخدام جميع الخصائص المميزة
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount &&
        element.quantity == item.quantity &&
        element.retailPrice == item.retailPrice);

    debugPrint('🗑️ فهرس العنصر الموجود: $index');
    debugPrint('🗑️ عدد العناصر في السلة: ${newCart.length}');

    if (index != -1) {
      final CartItem oldItem = newCart[index];
      final int oldDiscount = oldItem.discount;

      debugPrint('🗑️ العنصر القديم: ${oldItem.name}');
      debugPrint('🗑️ الخصم القديم: $oldDiscount');

      // إذا كان هناك خصم، نحذف العنصر القديم ونضيف واحد جديد بدون خصم
      if (oldDiscount > 0) {
        newCart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: 0);
        newCart.add(newItem);
        debugPrint('✅ تم حذف العنصر القديم وإضافة عنصر جديد بدون خصم');
      } else {
        // لا يوجد خصم - تحديث مباشر
        newCart[index] = oldItem.copyWith(discount: 0);
        debugPrint('✅ تم تحديث العنصر مباشرة بدون خصم');
      }
      state = state.copyWith(cart: newCart);
      _saveCartToStorage(); // حفظ السلة تلقائياً
      debugPrint('✅ تم حفظ السلة بنجاح');
    } else {
      debugPrint('❌ لم يتم العثور على العنصر المحدد في السلة');
    }
  }

  /// البحث عن عنصر بالمعرف
  CartItem? findItemById(String productId, {int discount = 0}) {
    try {
      return state.cart.firstWhere((CartItem item) =>
          item.productId == productId && item.discount == discount);
    } catch (e) {
      return null;
    }
  }
}

// ========== Riverpod Providers ==========

/// Provider للسلة
final StateNotifierProvider<CartNotifier, CartState> cartStateProvider =
    StateNotifierProvider<CartNotifier, CartState>(
        (StateNotifierProviderRef<CartNotifier, CartState> ref) =>
            CartNotifier());

/// Provider للمبلغ الإجمالي
final Provider<int> totalAmountProvider = Provider<int>((ProviderRef<int> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.totalAmount;
});

/// Provider للربح الإجمالي
final Provider<int> totalProfitProvider = Provider<int>((ProviderRef<int> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.totalProfit;
});

/// Provider للكمية الإجمالية
final Provider<int> totalQuantityProvider =
    Provider<int>((ProviderRef<int> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.totalQuantity;
});

/// Provider لعدد العناصر
final Provider<int> cartItemCountProvider =
    Provider<int>((ProviderRef<int> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.itemCount;
});

/// Provider للتحقق من أن السلة فارغة
final Provider<bool> cartIsEmptyProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.isEmpty;
});

/// Provider للتحقق من أن السلة غير فارغة
final Provider<bool> cartIsNotEmptyProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.isNotEmpty;
});

/// Provider للسلة المفلترة (منتجات مخصومة فقط)
final ProviderFamily<List<CartItem>, bool> filteredCartProvider =
    Provider.family<List<CartItem>, bool>(
        (ProviderRef<List<CartItem>> ref, bool showDiscountedOnly) {
  final CartState cartState = ref.watch(cartStateProvider);

  if (showDiscountedOnly) {
    return cartState.cart.where((CartItem item) => item.discount > 0).toList();
  }

  return cartState.cart;
});

/// Provider للتحقق من وجود منتجات مخصومة
final Provider<bool> hasDiscountedItemsProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.cart.any((CartItem item) => item.discount > 0);
});

/// Provider لعدد المنتجات المخصومة
final Provider<int> discountedItemsCountProvider =
    Provider<int>((ProviderRef<int> ref) {
  final CartState cartState = ref.watch(cartStateProvider);
  return cartState.cart.where((CartItem item) => item.discount > 0).length;
});

/// Provider لتهيئة السلة
final FutureProvider<void> cartInitializationProvider =
    FutureProvider<void>((FutureProviderRef<void> ref) async {
  final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
  await cartNotifier.initialize();
});
