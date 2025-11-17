import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/inventory_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/validators.dart';
import '../../../widgets/styled_section.dart';

class PriceQuantitySection extends ConsumerWidget {
  const PriceQuantitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);

    return StyledSection(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.attach_money,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).priceQuantity,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          // صف الأسعار والكمية
          Column(
            children: <Widget>[
              // صف الأسعار
              Row(
                children: <Widget>[
                  // سعر الجملة
                  Expanded(
                    child: TextFormField(
                      initialValue: state.wholesalePrice,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).wholesalePriceLabel,
                        hintText: '0',
                        prefixIcon: const Icon(Icons.store,
                            color: AppConstants.primaryColor),
                        suffixText: CurrencyFormatter.formatCurrency(0, context)
                            .split(' ')[1], // "DZ"
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
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: Validators.validateWholesalePrice,
                      textInputAction: TextInputAction.next,
                      onChanged: (String value) {
                        ref
                            .read(inventoryStateProvider.notifier)
                            .updateField('wholesalePrice', value);
                      },
                    ),
                  ),

                  const SizedBox(width: AppConstants.defaultPadding),

                  // سعر التجزئة
                  Expanded(
                    child: TextFormField(
                      initialValue: state.retailPrice,
                      decoration: InputDecoration(
                        labelText: 'سعر التجزئة',
                        hintText: '0',
                        prefixIcon: const Icon(Icons.sell,
                            color: AppConstants.primaryColor),
                        suffixText: CurrencyFormatter.formatCurrency(0, context)
                            .split(' ')[1], // "DZ"
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
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال سعر التجزئة';
                        }
                        final int? price = int.tryParse(value);
                        if (price == null || price < 0) {
                          return 'السعر غير صحيح';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onChanged: (String value) {
                        ref
                            .read(inventoryStateProvider.notifier)
                            .updateField('retailPrice', value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // صف الكمية
              Row(
                children: <Widget>[
                  // الكمية
                  Expanded(
                    child: TextFormField(
                      initialValue: state.quantity,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                            .quantityLabel(0)
                            .replaceAll(': 0', ''),
                        hintText: '0',
                        prefixIcon: const Icon(Icons.inventory,
                            color: AppConstants.primaryColor),
                        suffixText: AppLocalizations.of(context).quantityUnit,
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
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: Validators.validateQuantity,
                      textInputAction: TextInputAction.next,
                      onChanged: (String value) {
                        ref
                            .read(inventoryStateProvider.notifier)
                            .updateField('quantity', value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
