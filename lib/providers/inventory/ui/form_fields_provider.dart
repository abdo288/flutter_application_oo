import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider لحقول النموذج
final AutoDisposeProvider<Map<String, String>> formFieldsProvider = Provider.autoDispose<Map<String, String>>(
  (AutoDisposeProviderRef<Map<String, String>> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, String>{
      'productName': state.productName,
      'wholesalePrice': state.wholesalePrice,
      'retailPrice': state.retailPrice,
      'quantity': state.quantity,
      'expiryDate': state.expiryDate,
    };
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
