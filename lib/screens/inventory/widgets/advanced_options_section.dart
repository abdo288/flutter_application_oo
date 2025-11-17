import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/inventory_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../widgets/styled_section.dart';

class AdvancedOptionsSection extends ConsumerWidget {
  const AdvancedOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showAdvancedOptions = ref.watch(showAdvancedOptionsProvider);
    final String? generatedBarcode = ref.watch(generatedBarcodeProvider);
    final String expiryDate = ref.watch(inventoryStateProvider).expiryDate;

    return StyledSection(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.settings,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).advancedOptions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref
                      .read(inventoryStateProvider.notifier)
                      .toggleAdvancedOptions();
                },
                icon: Icon(
                  showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          if (showAdvancedOptions) ...<Widget>[
            const SizedBox(height: AppConstants.defaultPadding),

            // تاريخ الانتهاء
            TextFormField(
              initialValue: expiryDate,
              readOnly: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).expiryDateLabel,
                hintText: AppLocalizations.of(context).expiryDateHint,
                prefixIcon: const Icon(Icons.calendar_today,
                    color: AppConstants.primaryColor),
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
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month,
                      color: AppConstants.primaryColor),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final String formattedDate =
                          DateFormat(AppConstants.dateFormat).format(picked);
                      ref
                          .read(inventoryStateProvider.notifier)
                          .updateField('expiryDate', formattedDate);
                    }
                  },
                ),
              ),
              onChanged: (String value) {
                ref
                    .read(inventoryStateProvider.notifier)
                    .updateField('expiryDate', value);
              },
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // أزرار الباركود
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scanBarcode(context),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(AppLocalizations.of(context).scanBarcodeButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generateBarcodePreview(context, ref),
                    icon: const Icon(Icons.qr_code),
                    label: Text(
                        AppLocalizations.of(context).generateBarcodeButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: const BorderSide(color: AppConstants.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // عرض الباركود المولد أو الممسوح
            if (generatedBarcode != null) ...<Widget>[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                      color: AppConstants.successColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.qr_code, color: AppConstants.successColor),
                        const SizedBox(width: 8),
                        Text(
                          'الباركود: $generatedBarcode',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _scanBarcode(BuildContext context) {
    // سيتم تنفيذ وظيفة مسح الباركود في الخدمات المنفصلة
    debugPrint('Scan barcode');
  }

  void _generateBarcodePreview(BuildContext context, WidgetRef ref) {
    // سيتم تنفيذ وظيفة توليد الباركود في الخدمات المنفصلة
    debugPrint('Generate barcode preview');
  }
}
