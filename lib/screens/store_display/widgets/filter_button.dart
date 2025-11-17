import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/store_display_riverpod_providers.dart';
import '../../../utils/constants.dart';

class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.3)),
        ),
        child: PopupMenuButton<String>(
          onSelected: (String value) {
            ref
                .read(inventoryDisplayStateProvider.notifier)
                .setSortAscending(value == 'asc');
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem(
              value: 'asc',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.arrow_upward,
                      color: AppConstants.successColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).ascending),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'desc',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.arrow_downward,
                      color: AppConstants.errorColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).descending),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  ref.watch(inventoryDisplayStateProvider).sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  ref.watch(inventoryDisplayStateProvider).sortAscending
                      ? AppLocalizations.of(context).ascending
                      : AppLocalizations.of(context).descending,
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
