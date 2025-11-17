import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نموذج عنصر السلة
class CartItem {

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.barcode,
  });
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? barcode;

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? barcode,
  }) => CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
    );
}

/// Provider لإدارة السلة
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(<CartItem>[]);

  /// إضافة منتج للسلة
  void addItem(CartItem item) {
    final int existingIndex =
        state.indexWhere((CartItem cartItem) => cartItem.id == item.id);

    if (existingIndex != -1) {
      // تحديث الكمية إذا كان المنتج موجود
      final CartItem updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + item.quantity,
      );
      state = <CartItem>[
        ...state.take(existingIndex),
        updatedItem,
        ...state.skip(existingIndex + 1),
      ];
    } else {
      // إضافة منتج جديد
      state = <CartItem>[...state, item];
    }
  }

  /// تحديث كمية منتج
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = state.map((CartItem item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  /// إزالة منتج من السلة
  void removeItem(String itemId) {
    state = state.where((CartItem item) => item.id != itemId).toList();
  }

  /// مسح السلة بالكامل
  void clearCart() {
    state = <CartItem>[];
  }

  /// حساب إجمالي السلة
  double get totalAmount => state.fold(0.0, (double sum, CartItem item) => sum + item.totalPrice);

  /// عدد العناصر في السلة
  int get itemCount => state.fold(0, (int sum, CartItem item) => sum + item.quantity);
}

/// Provider للسلة
final StateNotifierProvider<CartNotifier, List<CartItem>> cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((StateNotifierProviderRef<CartNotifier, List<CartItem>> ref) => CartNotifier());

/// Provider لإجمالي السلة
final Provider<double> cartTotalProvider = Provider<double>((ProviderRef<double> ref) => ref.watch(cartProvider.notifier).totalAmount);

/// Provider لعدد عناصر السلة
final Provider<int> cartItemCountProvider = Provider<int>((ProviderRef<int> ref) => ref.watch(cartProvider.notifier).itemCount);
