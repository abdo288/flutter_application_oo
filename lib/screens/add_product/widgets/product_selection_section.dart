import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/inventory_item.dart';
import '../../../providers/add_product_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../widgets/styled_section.dart';

class ProductSelectionSection extends ConsumerWidget {
  const ProductSelectionSection({
    super.key,
    required this.availableItemsMap,
    required this.currentValue,
    required this.onShowSnackbar,
  });

  final Map<String, InventoryItem> availableItemsMap;
  final String? currentValue;
  final void Function(String) onShowSnackbar;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StyledSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).selectProduct,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField2<String>(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).chooseFromInventory,
              hintText: AppLocalizations.of(context).chooseProductHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: const BorderSide(
                    color: AppConstants.primaryColor, width: 2.0),
              ),
              filled: true,
              fillColor: AppConstants.cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: (availableItemsMap.values.map((InventoryItem item) {
              final int sameNameCount = availableItemsMap.values
                  .where((InventoryItem i) =>
                      i.name == item.name && !i.isOutOfStock())
                  .length;
              return DropdownMenuItem<String>(
                value: '${item.name}_${item.id!}',
                child: sameNameCount > 1
                    ? Text('${item.name} (${item.quantity} قطعة)')
                    : Text(item.name),
              );
            }).toList()
              ..sort((DropdownMenuItem<String> a, DropdownMenuItem<String> b) =>
                  a.child.toString().compareTo(b.child.toString()))),
            value: currentValue,
            onChanged: (String? value) {
              ref.read(addProductStateProvider.notifier).selectProduct(value);
              if (value != null) {
                final List<String> parts = value.split('_');
                final String itemId = parts.sublist(1).join('_');
                final InventoryItem? item = availableItemsMap[itemId];
                if (item != null) {
                  onShowSnackbar(
                      '${AppLocalizations.of(context).remainingQuantityLabel}: ${item.quantity}');
                }
              }
            },
            validator: (String? value) => value == null
                ? AppLocalizations.of(context).pleaseSelectProduct
                : null,
          ),
        ],
      ),
    );
}
