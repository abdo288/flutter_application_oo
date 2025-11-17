import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';
import 'end_of_day_dialog.dart';

/// Widget لاختبار نظام إنهاء اليوم
class TestEndOfDayWidget extends ConsumerWidget {
  const TestEndOfDayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CartItem> cartItems = ref.watch(cartProvider);
    final double cartTotal = ref.watch(cartTotalProvider);
    final double totalSales = ref.watch(totalSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام إنهاء اليوم'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // إحصائيات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'الإحصائيات الحالية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'المبيعات المحفوظة: ${totalSales.toStringAsFixed(2)} DZ'),
                    Text('عناصر السلة: ${cartItems.length}'),
                    Text('إجمالي السلة: ${cartTotal.toStringAsFixed(2)} DZ'),
                    Text(
                        'المجموع الكلي: ${(totalSales + cartTotal).toStringAsFixed(2)} DZ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // أزرار التحكم
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () => _addTestItem(ref),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج للسلة'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _clearCart(ref),
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح السلة'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _clearSales(ref),
                  icon: const Icon(Icons.delete),
                  label: const Text('مسح المبيعات'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // قائمة السلة
            if (cartItems.isNotEmpty) ...<Widget>[
              const Text(
                'عناصر السلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CartItem item = cartItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle:
                            Text('السعر: ${item.price.toStringAsFixed(2)} DZ'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('الكمية: ${item.quantity}'),
                            const SizedBox(width: 8),
                            Text(
                                'المجموع: ${item.totalPrice.toStringAsFixed(2)} DZ'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...<Widget>[
              const Expanded(
                child: Center(
                  child: Text(
                    'السلة فارغة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],

            // زر إنهاء اليوم
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEndOfDayDialog(context),
                icon: const Icon(Icons.event),
                label: const Text('إنهاء اليوم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTestItem(WidgetRef ref) {
    final CartItem item = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'منتج تجريبي ${ref.read(cartProvider).length + 1}',
      price: 100.0 + (ref.read(cartProvider).length * 50),
      quantity: 1,
      barcode: '1234567890',
    );
    ref.read(cartProvider.notifier).addItem(item);
  }

  void _clearCart(WidgetRef ref) {
    ref.read(cartProvider.notifier).clearCart();
  }

  void _clearSales(WidgetRef ref) {
    ref.read(salesProvider.notifier).clearSales();
  }

  void _showEndOfDayDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => const EndOfDayDialog(),
    );
  }
}
