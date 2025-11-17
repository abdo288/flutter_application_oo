import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item.dart';
import '../../services/pos_service.dart';

part 'cart_riverpod_provider.g.dart';

/// State class للسلة
class CartState {
  const CartState({
    required this.items,
    required this.isInitialized,
    this.isSaving = false,
  });

  factory CartState.initial() => const CartState(
        items: <CartItem>[],
        isInitialized: false,
      );
  final List<CartItem> items;
  final bool isInitialized;
  final bool isSaving;

  CartState copyWith({
    List<CartItem>? items,
    bool? isInitialized,
    bool? isSaving,
  }) =>
      CartState(
        items: items ?? this.items,
        isInitialized: isInitialized ?? this.isInitialized,
        isSaving: isSaving ?? this.isSaving,
      );

  // ✅ جميع الـ getters من الكود الأصلي
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;

  // ✅ جميع الحسابات
  int getTotalAmount() =>
      items.fold(0, (int sum, CartItem item) => sum + item.totalPrice);
  int getTotalProfit() =>
      items.fold(0, (int sum, CartItem item) => sum + item.totalProfit);
  int getTotalQuantity() =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);
}

/// SharedPreferences Provider
@riverpod
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async =>
    await SharedPreferences.getInstance();

/// Cart Controller مع جميع الوظائف
@riverpod
class CartController extends _$CartController {
  static const String _cartKey = 'cart_items';
  static const String _cartTimestampKey = 'cart_timestamp';

  @override
  Future<CartState> build() async {
    // التهيئة التلقائية
    final SharedPreferences prefs =
        await ref.watch(sharedPreferencesProvider.future);
    final List<CartItem> items = await _loadFromStorage(prefs);

    debugPrint('🛒 تم تهيئة CartController بنجاح: ${items.length} عنصر');

    return CartState(
      items: items,
      isInitialized: true,
    );
  }

  /// ✅ استعادة السلة من SharedPreferences
  Future<List<CartItem>> _loadFromStorage(SharedPreferences prefs) async {
    try {
      final String? cartString = prefs.getString(_cartKey);
      if (cartString == null || cartString.isEmpty) return <CartItem>[];

      final List<dynamic> cartJson = jsonDecode(cartString) as List<dynamic>;
      final List<CartItem> items = cartJson
          .map((itemData) {
            try {
              return CartItem.fromMap(itemData as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ خطأ في تحويل عنصر السلة: $e');
              return null;
            }
          })
          .whereType<CartItem>()
          .toList();

      debugPrint('📦 تم استعادة ${items.length} عنصر من السلة');
      return items;
    } catch (e) {
      debugPrint('❌ خطأ في استعادة السلة: $e');
      return <CartItem>[];
    }
  }

  /// ✅ حفظ السلة في SharedPreferences
  Future<void> _saveToStorage(List<CartItem> items) async {
    try {
      final SharedPreferences prefs =
          await ref.read(sharedPreferencesProvider.future);
      final List<Map<String, dynamic>> cartJson =
          items.map((CartItem item) => item.toMap()).toList();
      final String cartString = jsonEncode(cartJson);

      await prefs.setString(_cartKey, cartString);
      await prefs.setString(
          _cartTimestampKey, DateTime.now().toIso8601String());

      debugPrint('💾 تم حفظ السلة في SharedPreferences: ${items.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة: $e');
    }
  }

  /// ✅ إضافة عنصر إلى السلة
  Future<void> addItem(CartItem item) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = List<CartItem>.from(currentState.items);

      // البحث عن منتج بنفس productId و نفس الخصم
      final int index = newItems.indexWhere((CartItem element) =>
          element.productId == item.productId &&
          element.discount == item.discount);

      if (index != -1) {
        // المنتج موجود بنفس الخصم - زيادة الكمية
        newItems[index] = newItems[index].copyWith(
          quantity: newItems[index].quantity + item.quantity,
        );
      } else {
        // منتج جديد
        newItems.add(item);
      }

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ تحديث كمية منتج
  Future<void> updateQuantity(String productId, int newQuantity,
      {int discount = 0}) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = List<CartItem>.from(currentState.items);

      final int index = newItems.indexWhere((CartItem element) =>
          element.productId == productId && element.discount == discount);

      if (index != -1) {
        if (newQuantity > 0) {
          newItems[index] = newItems[index].copyWith(quantity: newQuantity);
        } else {
          newItems.removeAt(index);
        }
      }

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ تحديث كمية عنصر محدد
  Future<void> updateQuantityForItem(CartItem item, int newQuantity) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = List<CartItem>.from(currentState.items);

      int index = newItems.indexWhere((CartItem element) =>
          element.productId == item.productId &&
          element.discount == item.discount);

      if (index == -1) {
        // جرب البحث بالباركود
        index = newItems.indexWhere((CartItem element) =>
            element.barcode == item.barcode &&
            element.discount == item.discount);
      }

      if (index != -1) {
        if (newQuantity > 0) {
          newItems[index] = newItems[index].copyWith(quantity: newQuantity);
        } else {
          newItems.removeAt(index);
        }
      }

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ حذف عنصر من السلة
  Future<void> removeItem(String productId, {int discount = 0}) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = currentState.items
          .where((CartItem element) =>
              !(element.productId == productId && element.discount == discount))
          .toList();

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ حذف عنصر محدد
  Future<void> removeItemByObject(CartItem item) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = List<CartItem>.from(currentState.items);

      int index = newItems.indexWhere((CartItem element) =>
          element.productId == item.productId &&
          element.discount == item.discount);

      if (index == -1) {
        index = newItems.indexWhere((CartItem element) =>
            element.barcode == item.barcode &&
            element.discount == item.discount);
      }

      if (index != -1) {
        newItems.removeAt(index);
      }

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ مسح السلة بالكامل
  Future<void> clearCart() async {
    state = await AsyncValue.guard(() async {
      final SharedPreferences prefs =
          await ref.read(sharedPreferencesProvider.future);
      await prefs.remove(_cartKey);
      await prefs.remove(_cartTimestampKey);

      // مسح السلة من Firebase أيضاً
      await _clearCartFromFirebase();

      debugPrint('🗑️ تم مسح السلة محلياً ومن Firebase');
      return CartState.initial().copyWith(isInitialized: true);
    });
  }

  /// مسح السلة من Firebase
  Future<void> _clearCartFromFirebase() async {
    try {
      // مسح السلة من Firebase إذا كان متصلاً
      await POSService.clearCartFromFirebase();
      debugPrint('🗑️ تم مسح السلة من Firebase');
    } catch (e) {
      debugPrint('❌ خطأ في مسح السلة من Firebase: $e');
      // لا نرمي الخطأ هنا لأن مسح السلة المحلية كافي
    }
  }

  /// ✅ تطبيق خصم على منتج
  Future<void> applyDiscount(String productId, int discount) async {
    state = await AsyncValue.guard(() async {
      final CartState currentState = state.valueOrNull ?? CartState.initial();
      final List<CartItem> newItems = List<CartItem>.from(currentState.items);

      final int index = newItems
          .indexWhere((CartItem element) => element.productId == productId);

      if (index != -1) {
        final CartItem oldItem = newItems[index];
        if (oldItem.discount != discount) {
          newItems.removeAt(index);
          newItems.add(oldItem.copyWith(discount: discount));
        }
      }

      await _saveToStorage(newItems);
      return currentState.copyWith(items: newItems);
    });
  }

  /// ✅ إلغاء الخصم
  Future<void> removeDiscount(String productId) async {
    await applyDiscount(productId, 0);
  }

  /// ✅ حفظ يدوي
  Future<void> saveCartManually() async {
    final CartState? currentState = state.valueOrNull;
    if (currentState != null) {
      await _saveToStorage(currentState.items);
    }
  }

  /// ✅ البحث عن عنصر بالمعرف
  CartItem? findItemById(String productId, {int discount = 0}) {
    final CartState? currentState = state.valueOrNull;
    if (currentState == null) return null;

    try {
      return currentState.items.firstWhere(
        (CartItem item) =>
            item.productId == productId && item.discount == discount,
      );
    } catch (e) {
      return null;
    }
  }
}

/// ✅ Helper Providers للحسابات
@riverpod
int cartTotalAmount(CartTotalAmountRef ref) =>
    ref.watch(cartControllerProvider).maybeWhen(
          data: (CartState state) => state.getTotalAmount(),
          orElse: () => 0,
        );

@riverpod
int cartTotalProfit(CartTotalProfitRef ref) =>
    ref.watch(cartControllerProvider).maybeWhen(
          data: (CartState state) => state.getTotalProfit(),
          orElse: () => 0,
        );

@riverpod
int cartItemCount(CartItemCountRef ref) =>
    ref.watch(cartControllerProvider).maybeWhen(
          data: (CartState state) => state.itemCount,
          orElse: () => 0,
        );

@riverpod
bool cartIsEmpty(CartIsEmptyRef ref) =>
    ref.watch(cartControllerProvider).maybeWhen(
          data: (CartState state) => state.isEmpty,
          orElse: () => true,
        );
