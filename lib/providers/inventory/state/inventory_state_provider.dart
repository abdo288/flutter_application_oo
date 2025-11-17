import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_notifier.dart';
import 'inventory_state.dart';

/// Provider الرئيسي لحالة تبويب نموذج المنتج
final AutoDisposeStateNotifierProvider<InventoryNotifier, InventoryState> inventoryStateProvider =
    StateNotifierProvider.autoDispose<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
