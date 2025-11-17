import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/add_product_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/validators.dart';
import '../../../widgets/styled_section.dart';

class PriceInputSection extends ConsumerWidget {
  const PriceInputSection({
    super.key,
    required this.retailPriceController,
    required this.retailFieldKey,
    required this.wholesalePrice,
  });

  final TextEditingController retailPriceController;
  final GlobalKey<FormFieldState<String>> retailFieldKey;
  final String wholesalePrice;

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
                  color: AppConstants.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  size: 20,
                  color: AppConstants.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).retailPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: retailFieldKey,
            controller: retailPriceController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).retailPrice,
              hintText: 'مثال: 1500',
              prefixIcon: const Icon(Icons.attach_money,
                  color: AppConstants.warningColor),
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
                    color: AppConstants.warningColor, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: const BorderSide(color: AppConstants.errorColor),
              ),
              filled: true,
              fillColor: AppConstants.cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            onChanged: (String value) {
              ref
                  .read(addProductStateProvider.notifier)
                  .updateRetailPrice(value);
            },
            validator: (String? value) => Validators.validatePrices(
              wholesalePrice,
              value,
            ),
          ),
        ],
      ),
    );
}
