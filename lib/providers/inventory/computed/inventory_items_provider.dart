import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../../riverpod/stream_app_riverpod_provider.dart';
import '../../riverpod/stream_inventory_riverpod_provider.dart';

/// Provider لعناصر المخزون الكاملة
final AutoDisposeProvider<List<InventoryItem>> inventoryItemsProvider = Provider.autoDispose<List<InventoryItem>>(
  (AutoDisposeProviderRef<List<InventoryItem>> ref) {
    final AppState appState = ref.watch(appControllerProvider);
    final InventoryState inventoryState = ref.watch(inventoryControllerProvider);

    if (!appState.isInitialized || !inventoryState.isInitialized) {
      return <InventoryItem>[];
    }

    return inventoryState.inventoryItems;
  },
  dependencies: <ProviderOrFamily>[appControllerProvider, inventoryControllerProvider],
);
