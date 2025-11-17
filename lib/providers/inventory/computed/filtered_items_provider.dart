import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';
import 'inventory_items_provider.dart';

/// Provider للعناصر المفلترة والمفروزة
final AutoDisposeProvider<List<InventoryItem>> filteredInventoryItemsProvider =
    Provider.autoDispose<List<InventoryItem>>(
  (AutoDisposeProviderRef<List<InventoryItem>> ref) {
    final List<InventoryItem> items = ref.watch(inventoryItemsProvider);
    final InventoryState state = ref.watch(inventoryStateProvider);

    List<InventoryItem> filtered = List.from(items);

    // تطبيق الفلترة
    if (state.filterCriteria.isNotEmpty) {
      final String searchLower = state.filterCriteria.toLowerCase().trim();
      filtered = filtered.where((InventoryItem item) {
        // البحث في الاسم
        if (item.name.toLowerCase().contains(searchLower)) {
          return true;
        }
        // البحث في الباركود
        if (item.barcode != null &&
            item.barcode!.isNotEmpty &&
            item.barcode!.toLowerCase().contains(searchLower)) {
          return true;
        }
        return false;
      }).toList();
    } else if (state.filterDate != null) {
      filtered = filtered
          .where((InventoryItem item) =>
              item.addedTime.year == state.filterDate!.year &&
              item.addedTime.month == state.filterDate!.month &&
              item.addedTime.day == state.filterDate!.day)
          .toList();
    }

    // تطبيق الفرز
    filtered.sort((InventoryItem a, InventoryItem b) {
      int comparison;
      switch (state.sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'price':
          comparison = a.wholesalePrice.compareTo(b.wholesalePrice);
          break;
        case 'date':
          comparison = a.addedDate.compareTo(b.addedDate);
          break;
        default:
          comparison = 0;
      }
      return state.sortAscending ? comparison : -comparison;
    });

    return filtered;
  },
  dependencies: <ProviderOrFamily>[inventoryItemsProvider, inventoryStateProvider],
);
