import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/cart_item.dart' as models;
import 'package:profit_calculator/models/sale.dart';

import 'cart_provider.dart';

/// Provider لإدارة المبيعات
class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier() : super(<Sale>[]);

  /// إضافة بيع جديد
  void addSale(Sale sale) {
    state = <Sale>[...state, sale];
  }

  /// إضافة عدة مبيعات (من السلة)
  void addSalesFromCart(List<CartItem> cartItems) {
    if (cartItems.isEmpty) return;

    // تحويل CartItem إلى CartItem من models
    final List<models.CartItem> convertedItems = cartItems
        .map((CartItem item) => models.CartItem(
              productId: item.id,
              name: item.name,
              retailPrice: item.price.toInt(),
              quantity: item.quantity,
              barcode: item.barcode ?? '',
            ))
        .toList();

    final Sale sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: convertedItems,
      totalAmount:
          cartItems.fold(0.0, (double sum, CartItem item) => sum + item.totalPrice).toInt(),
      saleDate: DateTime.now(),
      customerName: 'عميل نهاية اليوم',
      paymentMethod: 'cash',
      totalProfit: cartItems
          .fold(0.0, (double sum, CartItem item) => sum + (item.totalPrice * 0.2))
          .toInt(), // 20% ربح افتراضي
    );

    addSale(sale);
  }

  /// مسح جميع المبيعات
  void clearSales() {
    state = <Sale>[];
  }

  /// حساب إجمالي المبيعات
  double get totalSales => state.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());

  /// عدد المبيعات
  int get salesCount => state.length;

  /// آخر بيع
  Sale? get lastSale {
    if (state.isEmpty) return null;
    return state.last;
  }
}

/// Provider للمبيعات
final StateNotifierProvider<SalesNotifier, List<Sale>> salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((StateNotifierProviderRef<SalesNotifier, List<Sale>> ref) => SalesNotifier());

/// Provider لإجمالي المبيعات
final Provider<double> totalSalesProvider = Provider<double>((ProviderRef<double> ref) => ref.watch(salesProvider.notifier).totalSales);

/// Provider لعدد المبيعات
final Provider<int> salesCountProvider = Provider<int>((ProviderRef<int> ref) => ref.watch(salesProvider.notifier).salesCount);

/// Provider لآخر بيع
final Provider<Sale?> lastSaleProvider = Provider<Sale?>((ProviderRef<Sale?> ref) => ref.watch(salesProvider.notifier).lastSale);
