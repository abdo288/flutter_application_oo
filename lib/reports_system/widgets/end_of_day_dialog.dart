import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/sale.dart';

import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';

/// حوار إنهاء اليوم
class EndOfDayDialog extends ConsumerWidget {
  const EndOfDayDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CartItem> cartItems = ref.watch(cartProvider);
    final double totalSavedSales = ref.watch(totalSalesProvider);
    final double cartTotal = ref.watch(cartTotalProvider);
    final int salesCount = ref.watch(salesCountProvider);
    final Sale? lastSale = ref.watch(lastSaleProvider);

    final double totalSales = totalSavedSales + cartTotal;
    final bool hasUnsavedItems = cartItems.isNotEmpty;

    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('إنهاء اليوم'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'أنت على وشك إنهاء يوم العمل وإغلاق دفتر المبيعات',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // تحذير المنتجات غير المحفوظة
            if (hasUnsavedItems)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: لديك ${cartItems.length} منتج في السلة لم يتم حفظه',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ملخص المبيعات
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ملخص المبيعات اليوم',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('إجمالي المبيعات اليوم',
                      '${totalSales.toStringAsFixed(2)} DZ'),
                  _buildSummaryRow('عدد المنتجات المباعة', '$salesCount'),
                  _buildSummaryRow('منتجات غير محفوظة', '${cartItems.length}'),
                  _buildSummaryRow(
                      'آخر عملية بيع',
                      lastSale != null
                          ? '${lastSale.totalAmount.toStringAsFixed(2)} DZ'
                          : 'لا توجد'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                border: Border.all(color: Colors.yellow[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إنشاء تقرير نهاية اليوم وإعادة تصغير العدادات',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // حفظ السلة أولاً
            _saveCartFirst(ref);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.shopping_cart),
          label: const Text('حفظ السلة أولاً'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _endDay(ref);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('إنهاء اليوم'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

  void _saveCartFirst(WidgetRef ref) {
    final List<CartItem> cartItems = ref.read(cartProvider);
    if (cartItems.isNotEmpty) {
      // حفظ عناصر السلة كمبيعات
      ref.read(salesProvider.notifier).addSalesFromCart(cartItems);
      // مسح السلة
      ref.read(cartProvider.notifier).clearCart();

      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text('تم حفظ ${cartItems.length} منتج في السلة')),
      );
    }
  }

  void _endDay(WidgetRef ref) {
    final List<CartItem> cartItems = ref.read(cartProvider);

    if (cartItems.isNotEmpty) {
      // حفظ السلة أولاً
      ref.read(salesProvider.notifier).addSalesFromCart(cartItems);
      ref.read(cartProvider.notifier).clearCart();
    }

    // إنشاء تقرير نهاية اليوم
    final double totalSales = ref.read(totalSalesProvider);

    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text(
            'تم إنهاء اليوم - إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} DZ'),
        duration: const Duration(seconds: 3),
      ),
    );

    // TODO: إنشاء تقرير PDF
    // ref.read(exportDataProvider)(sales, exportOptions);
  }
}
