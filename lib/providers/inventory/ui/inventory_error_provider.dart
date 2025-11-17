import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider لرسالة الخطأ
final AutoDisposeProvider<String?> inventoryErrorProvider = Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.errorMessage;
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
