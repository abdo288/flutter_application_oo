import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/add_product_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../widgets/barcode_scanner_view.dart';
import '../../../widgets/styled_section.dart';

class BarcodeSection extends ConsumerWidget {
  const BarcodeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => StyledSection(
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).fastBarcodeHint,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onSubmitted: (String code) {
                if (code.trim().isEmpty) return;
                ref
                    .read(addProductStateProvider.notifier)
                    .handleBarcodeScanned(code.trim());
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                final String? code = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const BarcodeScannerView(),
                  ),
                );
                if (code == null || code.trim().isEmpty) return;
                ref
                    .read(addProductStateProvider.notifier)
                    .handleBarcodeScanned(code.trim());
              },
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(
                AppLocalizations.of(context).scanBarcode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                elevation: 2,
                shadowColor: AppConstants.shadowColor,
              ),
            ),
          ),
        ],
      ),
    );
}
