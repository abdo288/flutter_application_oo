import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../../../providers/store_display_riverpod_providers.dart';
import '../../../widgets/modern_inventory_card.dart';
import '../../../widgets/windows_inventory_card.dart';
import 'action_handlers.dart';

class InventoryCard extends ConsumerWidget {
  const InventoryCard({
    super.key,
    required this.item,
  });

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryDisplayState inventoryDisplayState = ref.watch(inventoryDisplayStateProvider);

    // استخدام بطاقة Windows المحسنة إذا كان النظام Windows
    if (Platform.isWindows) {
      return WindowsInventoryCard(
        item: item,
        onEdit: () => InventoryDisplayActionHandlers.showEditDialog(context, item),
        onPrint: () => InventoryDisplayActionHandlers.printBarcode(context, item),
        onDelete: () =>
            InventoryDisplayActionHandlers.confirmAndDeleteItem(context, ref, item),
        isExpanded: inventoryDisplayState.expandedItemId == item.id,
        onExpansionChanged: (bool isExpanded) =>
            _handleCardExpansion(ref, item.id ?? '', isExpanded),
      );
    }

    // استخدام البطاقة العادية للمنصات الأخرى
    return ModernInventoryCard(
      item: item,
      onEdit: () => InventoryDisplayActionHandlers.showEditDialog(context, item),
      onPrint: () => InventoryDisplayActionHandlers.printBarcode(context, item),
      onDelete: () =>
          InventoryDisplayActionHandlers.confirmAndDeleteItem(context, ref, item),
      isExpanded: inventoryDisplayState.expandedItemId == item.id,
      onExpansionChanged: (bool isExpanded) =>
          _handleCardExpansion(ref, item.id ?? '', isExpanded),
    );
  }

  void _handleCardExpansion(WidgetRef ref, String itemId, bool isExpanded) {
    ref.read(inventoryDisplayStateProvider.notifier).handleCardExpansion(
          isExpanded ? itemId : null,
        );
  }
}
