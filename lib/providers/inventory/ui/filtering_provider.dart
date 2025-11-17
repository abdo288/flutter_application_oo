import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider لمعايير الفلترة
final AutoDisposeProvider<Map<String, dynamic>> filteringProvider = Provider.autoDispose<Map<String, dynamic>>(
  (AutoDisposeProviderRef<Map<String, dynamic>> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, dynamic>{
      'filterCriteria': state.filterCriteria,
      'filterDate': state.filterDate,
    };
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
