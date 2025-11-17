import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/store_display_riverpod_providers.dart';
import '../../../utils/constants.dart';

class SortButton extends ConsumerWidget {
  const SortButton({super.key});

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
            ref.read(inventoryDisplayStateProvider.notifier).setSortBy(value);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem(
              value: 'name',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.sort_by_alpha,
                      color: AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).sortByName),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'quantity',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.inventory,
                      color: AppConstants.secondaryColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).sortByQuantity),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'price',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.attach_money,
                      color: AppConstants.successColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).sortByPrice),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'date',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.calendar_today,
                      color: AppConstants.warningColor),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).sortByDate),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.sort,
                    color: AppConstants.primaryColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  _getSortLabel(context, ref),
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

  String _getSortLabel(BuildContext context, WidgetRef ref) {
    final String sortBy = ref.watch(inventoryDisplayStateProvider).sortBy;
    switch (sortBy) {
      case 'name':
        return AppLocalizations.of(context).sortByName;
      case 'quantity':
        return AppLocalizations.of(context).sortByQuantity;
      case 'price':
        return AppLocalizations.of(context).sortByPrice;
      case 'date':
        return AppLocalizations.of(context).sortByDate;
      default:
        return AppLocalizations.of(context).sortByName;
    }
  }
}
