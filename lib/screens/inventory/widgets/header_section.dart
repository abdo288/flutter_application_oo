import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../widgets/styled_section.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) => StyledSection(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppConstants.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).addInventoryHeader,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  Text(
                    AppLocalizations.of(context).addInventorySubtitle,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
