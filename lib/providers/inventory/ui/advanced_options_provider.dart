import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider للخيارات المتقدمة
final AutoDisposeProvider<bool> showAdvancedOptionsProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.showAdvancedOptions;
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
