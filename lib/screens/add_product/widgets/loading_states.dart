import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/add_product_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';

class LoadingStates {
  static Widget buildLoadingState() => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'جاري تحميل بيانات المخزون...',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
        ],
      ),
    );

  static Widget buildNoItemsState(BuildContext context, WidgetRef ref) => Center(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppConstants.lightTextColor,
            ),
            SizedBox(height: context.responsiveSpacing),
            Text(
              AppLocalizations.of(context).noInventoryAvailableTitle,
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Text(
              AppLocalizations.of(context).noInventoryAvailableSubtitle,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing),
            ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(addProductStateProvider.notifier)
                    .initializeData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة تحميل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
