import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/inventory_item.dart';

import '../../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../../../providers/riverpod/stream_product_riverpod_provider.dart';
import '../../../utils/currency_formatter.dart';
import 'stat_item_widget.dart';

class QuickStatsWidget extends ConsumerWidget {
  const QuickStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final AppState appController = ref.watch(appControllerProvider);

      // التحقق من أن Provider مهيأ ومتاح
      if (!appController.isInitialized || appController.isLoading) {
        return Row(
          children: <Widget>[
            StatItemWidget(
              context: context,
              icon: Icons.inventory,
              value: '...',
              label: 'منتج',
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            StatItemWidget(
              context: context,
              icon: Icons.storage,
              value: '...',
              label: 'مخزون',
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            StatItemWidget(
              context: context,
              icon: Icons.trending_up,
              value: '...',
              label: 'قيمة',
              color: Colors.orange,
            ),
          ],
        );
      }

      final ProductsState productsState = ref.watch(productsControllerProvider);
      final InventoryState inventoryState =
          ref.watch(inventoryControllerProvider);
      final int productCount = productsState.products.length;

      // حساب العناصر المتاحة فقط (غير النافذة)
      final List<InventoryItem> availableItems = inventoryState.inventoryItems
          .where(
              (InventoryItem item) => !item.isOutOfStock() && item.quantity > 0)
          .toList();
      final int inventoryCount = availableItems.length;

      final double totalValue = availableItems.fold<double>(
        0.0,
        (double sum, InventoryItem item) =>
            sum + (item.retailPrice * item.quantity),
      );

      return Row(
        children: <Widget>[
          StatItemWidget(
            context: context,
            icon: Icons.inventory,
            value: productCount.toString(),
            label: 'منتج',
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          StatItemWidget(
            context: context,
            icon: Icons.storage,
            value: inventoryCount.toString(),
            label: 'مخزون',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          StatItemWidget(
            context: context,
            icon: Icons.trending_up,
            value: CurrencyFormatter.formatCurrencyNoDecimals(
                totalValue / 100, context),
            label: 'قيمة',
            color: Colors.orange,
          ),
        ],
      );
    } catch (e) {
      debugPrint('خطأ في عرض الإحصائيات السريعة: $e');
      return Row(
        children: <Widget>[
          StatItemWidget(
            context: context,
            icon: Icons.inventory,
            value: '...',
            label: 'منتج',
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          StatItemWidget(
            context: context,
            icon: Icons.storage,
            value: '...',
            label: 'مخزون',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          StatItemWidget(
            context: context,
            icon: Icons.trending_up,
            value: '...',
            label: 'قيمة',
            color: Colors.orange,
          ),
        ],
      );
    }
  }
}
