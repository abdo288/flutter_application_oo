import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import 'inventory_items_provider.dart';

/// Provider لإحصائيات المخزون
final AutoDisposeProvider<Map<String, dynamic>> inventoryStatsProvider = Provider.autoDispose<Map<String, dynamic>>(
  (AutoDisposeProviderRef<Map<String, dynamic>> ref) {
    final List<InventoryItem> items = ref.watch(inventoryItemsProvider);

    final int totalQuantity = items.fold<int>(
        0, (int total, InventoryItem item) => total + item.quantity);
    final int lowStockCount =
        items.where((InventoryItem item) => item.quantity < 10).length;
    final int totalValue = items.fold<int>(
        0,
        (int total, InventoryItem item) =>
            total + (item.wholesalePrice * item.quantity).round());

    return <String, dynamic>{
      'totalItems': items.length,
      'totalQuantity': totalQuantity,
      'lowStockCount': lowStockCount,
      'totalValue': totalValue,
    };
  },
  dependencies: <ProviderOrFamily>[inventoryItemsProvider],
);
