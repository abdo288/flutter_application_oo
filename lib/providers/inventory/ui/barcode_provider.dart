import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider للباركود المولد
final AutoDisposeProvider<String?> generatedBarcodeProvider = Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.generatedBarcode;
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
