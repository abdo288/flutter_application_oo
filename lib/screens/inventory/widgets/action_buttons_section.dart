import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/inventory_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../widgets/styled_section.dart';

class ActionButtonsSection extends ConsumerWidget {
  const ActionButtonsSection({
    super.key,
    required this.onAddItem,
    required this.onClearFields,
    required this.onBulkAdd,
  });

  final VoidCallback onAddItem;
  final VoidCallback onClearFields;
  final VoidCallback onBulkAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoading = ref.watch(inventoryLoadingProvider);
    final bool isFormValid = ref.watch(formValidProvider);

    return StyledSection(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        children: <Widget>[
          // زر الإضافة الرئيسي
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isLoading || !isFormValid ? null : onAddItem,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle, size: 24),
              label: Text(
                isLoading
                    ? AppLocalizations.of(context).addingItem
                    : AppLocalizations.of(context).addItemToInventory,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                elevation: 3,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // أزرار مساعدة
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClearFields,
                  icon: const Icon(Icons.clear_all),
                  label: Text(AppLocalizations.of(context).clearFormButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.warningColor,
                    side: const BorderSide(color: AppConstants.warningColor),
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
                  onPressed: onBulkAdd,
                  icon: const Icon(Icons.add_box),
                  label: Text(AppLocalizations.of(context).bulkAddButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.secondaryColor,
                    side: const BorderSide(color: AppConstants.secondaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
