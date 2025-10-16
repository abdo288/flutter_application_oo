import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// حالة السلة للـ Riverpod
class CartState {
  final List<CartItem> cart;
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    required this.cart,
    this.isInitialized = false,
    this.isLoading = false,
    this.errorMessage,
  });

  CartState copyWith({
    List<CartItem>? cart,
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Getters للراحة
  bool get isEmpty => cart.isEmpty;
  bool get isNotEmpty => cart.isNotEmpty;
  int get itemCount => cart.length;
  int get totalAmount => cart.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalProfit => cart.fold(0, (sum, item) => sum + item.totalProfit);
  int get totalQuantity => cart.fold(0, (sum, item) => sum + item.quantity);
}

/// CartNotifier لإدارة حالة السلة باستخدام Riverpod
class CartNotifier extends StateNotifier<CartState> {
  // مفاتيح SharedPreferences
  static const String _cartKey = 'cart_items';
  static const String _cartTimestampKey = 'cart_timestamp';

  // متغيرات الحفظ
  SharedPreferences? _prefs;

  CartNotifier() : super(const CartState(cart: []));

  /// تهيئة CartNotifier
  Future<void> initialize() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCartFromStorage();

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

        state = state.copyWith(cart: loadedCart);
        debugPrint('📦 تم استعادة ${loadedCart.length} عنصر من السلة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في استعادة السلة: $e');
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
    final List<CartItem> newCart = List<CartItem>.from(state.cart);

    // البحث عن منتج بنفس productId و نفس الخصم
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      // المنتج موجود بنفس الخصم - زيادة الكمية
      newCart[index] = newCart[index]
          .copyWith(quantity: newCart[index].quantity + item.quantity);
    } else {
      // منتج جديد أو نفس المنتج بخصم مختلف - إضافته كعنصر منفصل
      newCart.add(item);
    }

    state = state.copyWith(cart: newCart);
    _saveCartToStorage(); // حفظ السلة تلقائياً
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
    state = state.copyWith(cart: []);
    _saveCartToStorage(); // حفظ السلة تلقائياً
    _clearStoredCart(); // مسح السلة المحفوظة أيضاً
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
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount &&
        element.quantity == item.quantity);

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
    final List<CartItem> newCart = List<CartItem>.from(state.cart);
    final int index = newCart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount &&
        element.quantity == item.quantity);

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
final cartStateProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// Provider للمبلغ الإجمالي
final totalAmountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.totalAmount;
});

/// Provider للربح الإجمالي
final totalProfitProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.totalProfit;
});

/// Provider للكمية الإجمالية
final totalQuantityProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.totalQuantity;
});

/// Provider لعدد العناصر
final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.itemCount;
});

/// Provider للتحقق من أن السلة فارغة
final cartIsEmptyProvider = Provider<bool>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.isEmpty;
});

/// Provider للتحقق من أن السلة غير فارغة
final cartIsNotEmptyProvider = Provider<bool>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.isNotEmpty;
});

/// Provider للسلة المفلترة (منتجات مخصومة فقط)
final filteredCartProvider =
    Provider.family<List<CartItem>, bool>((ref, showDiscountedOnly) {
  final cartState = ref.watch(cartStateProvider);

  if (showDiscountedOnly) {
    return cartState.cart.where((item) => item.discount > 0).toList();
  }

  return cartState.cart;
});

/// Provider للتحقق من وجود منتجات مخصومة
final hasDiscountedItemsProvider = Provider<bool>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.cart.any((item) => item.discount > 0);
});

/// Provider لعدد المنتجات المخصومة
final discountedItemsCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartStateProvider);
  return cartState.cart.where((item) => item.discount > 0).length;
});

/// Provider لتهيئة السلة
final cartInitializationProvider = FutureProvider<void>((ref) async {
  final cartNotifier = ref.read(cartStateProvider.notifier);
  await cartNotifier.initialize();
});
