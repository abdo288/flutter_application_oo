import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/modern_edit_inventory_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../providers/stream_inventory_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/info_card.dart';

class InventoryItemDetailsScreen extends StatelessWidget {
  const InventoryItemDetailsScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final StreamInventoryProvider provider =
        context.read<StreamInventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, provider),
            tooltip: AppLocalizations.of(context).deleteItem,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editItem(context, provider),
            tooltip: AppLocalizations.of(context).editItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context),
            const SizedBox(height: AppConstants.largePadding),
            _buildDetailsGrid(context),
            const SizedBox(height: AppConstants.largePadding),
            _buildBarcodeSection(context),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, StreamInventoryProvider provider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content:
            Text(AppLocalizations.of(context).confirmDeleteMessage(item.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      final bool success = await provider.deleteInventoryItem(item.id!);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).productDeleted),
              backgroundColor: AppConstants.successColor,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).productDeleteError),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeader(BuildContext context) => Center(
        child: Column(
          children: <Widget>[
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatCurrency(
                  item.wholesalePrice.toDouble(), context),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );

  Widget _buildDetailsGrid(BuildContext context) {
    final bool isLowStock = item.quantity < 10;
    final bool isExpired =
        item.expiryDate != null && item.expiryDate!.isBefore(DateTime.now());

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.defaultPadding,
      mainAxisSpacing: AppConstants.defaultPadding,
      children: <Widget>[
        InfoCard(
          icon: Icons.inventory_2_outlined,
          title: AppLocalizations.of(context).quantity,
          value: item.quantity.toString(),
          valueColor: isLowStock ? AppConstants.warningColor : null,
        ),
        InfoCard(
          icon: Icons.production_quantity_limits,
          title: AppLocalizations.of(context).quantity,
          value: item.originalQuantity.toString(),
        ),
        InfoCard(
          icon: Icons.calendar_today_outlined,
          title: AppLocalizations.of(context).addDate,
          value: item.formattedAddedDate,
        ),
        if (item.expiryDate != null)
          InfoCard(
            icon: Icons.event_busy_outlined,
            title: AppLocalizations.of(context).expiryDate,
            value: item.formattedExpiryDate,
            valueColor: isExpired ? AppConstants.errorColor : null,
          ),
      ],
    );
  }

  Widget _buildBarcodeSection(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppLocalizations.of(context).barcode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Center(
                child: Text(
                  item.barcode ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// فتح نافذة تعديل العنصر
  void _editItem(BuildContext context, StreamInventoryProvider provider) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernEditInventoryDialog(
        item: item,
        onItemUpdated: () async {
          // إعادة تحميل البيانات بعد التعديل
          await provider.loadInventoryItems();
          // تأخير صغير لضمان اكتمال التحديث
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
