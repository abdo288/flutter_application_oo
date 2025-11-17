import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/store_display_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_formatter.dart';

class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> stats = ref.watch(filteredInventoryStatsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppConstants.secondaryColor.withValues(alpha: 0.06),
            AppConstants.secondaryColor.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppConstants.secondaryColor.withValues(alpha: 0.2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppConstants.secondaryColor.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildStatItem(
              context,
              AppLocalizations.of(context).totalItems,
              stats['totalItems'].toString(),
              Icons.inventory_2,
              AppConstants.primaryColor,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              AppLocalizations.of(context).outOfStock,
              stats['outOfStockCount'].toString(),
              Icons.warning,
              AppConstants.errorColor,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              AppLocalizations.of(context).totalValue,
              CurrencyFormatter.formatCurrency(
                  ((stats['totalValue'] as num?) ?? 0).toDouble(), context),
              Icons.attach_money,
              AppConstants.successColor,
            ),
          ),
          // زر اختبار تحميل البيانات
          IconButton(
            onPressed: () => _testDataLoading(context),
            icon: const Icon(Icons.refresh, color: AppConstants.primaryColor),
            tooltip: 'اختبار تحميل البيانات',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
          IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  void _testDataLoading(BuildContext context) {
    // اختبار تحميل البيانات
    debugPrint('🔄 اختبار تحميل البيانات...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم اختبار تحميل البيانات'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
