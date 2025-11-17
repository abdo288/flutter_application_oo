import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider لمعايير الفرز
final AutoDisposeProvider<Map<String, dynamic>> sortingProvider = Provider.autoDispose<Map<String, dynamic>>(
  (AutoDisposeProviderRef<Map<String, dynamic>> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, dynamic>{
      'sortBy': state.sortBy,
      'sortAscending': state.sortAscending,
    };
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
