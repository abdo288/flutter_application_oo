import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider للتحقق من حالة التحميل
final AutoDisposeProvider<bool> inventoryLoadingProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.isLoading;
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
