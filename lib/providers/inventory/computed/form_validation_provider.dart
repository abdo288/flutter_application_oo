import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/validators.dart';
import '../state/inventory_state.dart';
import '../state/inventory_state_provider.dart';

/// Provider للتحقق من صحة النموذج
final AutoDisposeProvider<bool> formValidProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);

    if (state.productName.trim().isEmpty) return false;
    if (state.wholesalePrice.trim().isEmpty) return false;
    if (state.retailPrice.trim().isEmpty) return false;
    if (state.quantity.trim().isEmpty) return false;

    final int? wholesale = int.tryParse(state.wholesalePrice.trim());
    final int? retail = int.tryParse(state.retailPrice.trim());
    final int? qty = int.tryParse(state.quantity.trim());

    if (wholesale == null || retail == null || qty == null) return false;
    if (wholesale <= 0 || retail <= 0 || qty < 0) return false;

    // التحقق من صحة الأسعار
    final String? validationError = Validators.validatePrices(
      state.wholesalePrice.trim(),
      state.retailPrice.trim(),
    );
    return validationError == null;
  },
  dependencies: <ProviderOrFamily>[inventoryStateProvider],
);
