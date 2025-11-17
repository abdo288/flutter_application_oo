import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/inventory_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../utils/validators.dart';
import '../../../widgets/styled_section.dart';

class BasicInfoSection extends ConsumerWidget {
  const BasicInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String productName = ref.watch(inventoryStateProvider).productName;

    return StyledSection(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Text(
                AppLocalizations.of(context).basicInfo,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          // اسم السلعة
          TextFormField(
            initialValue: productName,
            style: TextStyle(fontSize: context.responsiveFontSize(16)),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).productNameLabel,
              labelStyle: TextStyle(fontSize: context.responsiveFontSize(16)),
              hintText: AppLocalizations.of(context).productNameHint,
              prefixIcon: Icon(Icons.shopping_bag,
                  color: AppConstants.primaryColor,
                  size: context.isSmallScreen ? 20 : 24),
              contentPadding: context.responsivePadding,
              isDense: context.isSmallScreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: const BorderSide(
                    color: AppConstants.primaryColor, width: 2.0),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: Validators.validateProductName,
            textInputAction: TextInputAction.next,
            onChanged: (String value) {
              ref
                  .read(inventoryStateProvider.notifier)
                  .updateField('productName', value);
            },
          ),
        ],
      ),
    );
  }
}
