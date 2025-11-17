import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/snackbar_utils.dart';

/// نافذة خيارات الطباعة
class PrintOptionsDialog {
  /// عرض نافذة خيارات الطباعة
  static Future<PrintOptions?> show(BuildContext context) async {
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    PaperSize selectedSize = PaperSize.roll57;
    bool includeName = true;
    bool includeStockQty = false;

    return showDialog<PrintOptions>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context).printBarcodeQuantityDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(AppLocalizations.of(context)
                  .printBarcodeQuantityDialogContent),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).printBarcodeQuantity,
                  hintText:
                      AppLocalizations.of(context).printBarcodeQuantityHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),
              const SizedBox(height: 16),
              const Text('مقاس الورق',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setSt) =>
                    Column(
                  children: <Widget>[
                    RadioListTile<PaperSize>(
                      value: PaperSize.roll57,
                      groupValue: selectedSize,
                      title: const Text('رول حراري 57mm'),
                      onChanged: (PaperSize? v) =>
                          setSt(() => selectedSize = v ?? PaperSize.roll57),
                    ),
                    RadioListTile<PaperSize>(
                      value: PaperSize.roll80,
                      groupValue: selectedSize,
                      title: const Text('رول حراري 80mm'),
                      onChanged: (PaperSize? v) =>
                          setSt(() => selectedSize = v ?? PaperSize.roll80),
                    ),
                    RadioListTile<PaperSize>(
                      value: PaperSize.a4,
                      groupValue: selectedSize,
                      title: const Text('A4'),
                      onChanged: (PaperSize? v) =>
                          setSt(() => selectedSize = v ?? PaperSize.a4),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      value: includeName,
                      onChanged: (bool? v) =>
                          setSt(() => includeName = v ?? true),
                      title: const Text('إظهار اسم المنتج'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: includeStockQty,
                      onChanged: (bool? v) =>
                          setSt(() => includeStockQty = v ?? false),
                      title: const Text('إظهار الكمية بالمخزن'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
                AppLocalizations.of(context).printBarcodeQuantityDialogCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final int quantity =
                  int.tryParse(quantityController.text.trim()) ?? 0;
              if (quantity < 1 || quantity > 500) {
                SnackbarUtils.showError(context,
                    AppLocalizations.of(context).printBarcodeQuantityError);
                return;
              }
              Navigator.of(context).pop(PrintOptions(
                quantity: quantity,
                size: selectedSize,
                includeName: includeName,
                includeStockQty: includeStockQty,
              ));
            },
            child: Text(
                AppLocalizations.of(context).printBarcodeQuantityDialogConfirm),
          ),
        ],
      ),
    );
  }
}

enum PaperSize { roll57, roll80, a4 }

class PrintOptions {
  const PrintOptions({
    required this.quantity,
    required this.size,
    required this.includeName,
    required this.includeStockQty,
  });
  final int quantity;
  final PaperSize size;
  final bool includeName;
  final bool includeStockQty;
}
