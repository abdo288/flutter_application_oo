import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/inventory_item.dart';
import '../../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../../../providers/riverpod/stream_product_riverpod_provider.dart';
import '../../../screens/alerts_tab_riverpod.dart';
import '../../../screens/settings_tab_riverpod.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../widgets/alert_badge.dart';
import '../../../widgets/sync_status_indicator.dart';

class MobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const MobileAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  final int currentIndex;
  final void Function(int) onTabTapped;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calculate,
                  color: Colors.white, size: context.isSmallScreen ? 18 : 20),
            ),
            SizedBox(width: context.responsiveSpacing * 0.8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).appTitle,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Consumer(
                    builder:
                        (BuildContext context, WidgetRef ref, Widget? child) {
                      try {
                        final AppState appController =
                            ref.watch(appControllerProvider);

                        // التحقق من أن Provider مهيأ ومتاح
                        if (!appController.isInitialized ||
                            appController.isLoading) {
                          return Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(12),
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          );
                        }

                        final ProductsState productsState =
                            ref.watch(productsControllerProvider);
                        final InventoryState inventoryState =
                            ref.watch(inventoryControllerProvider);
                        final int productCount = productsState.products.length;

                        // حساب العناصر المتاحة فقط (غير النافذة)
                        final List<InventoryItem> availableItems =
                            inventoryState.inventoryItems
                                .where((InventoryItem item) =>
                                    !item.isOutOfStock() && item.quantity > 0)
                                .toList();
                        final int inventoryCount = availableItems.length;

                        return Text(
                          '$productCount منتج • $inventoryCount مخزون',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        );
                      } catch (e) {
                        debugPrint('خطأ في عرض الإحصائيات: $e');
                        return Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: _buildMobileAppBarActions(context, ref),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      );

  /// بناء أزرار شريط التطبيق للموبايل
  List<Widget> _buildMobileAppBarActions(BuildContext context, WidgetRef ref) =>
      <Widget>[
        // ✅ مؤشر المزامنة
        Container(
          margin: EdgeInsets.only(
              right: context.responsiveSpacing * 0.4,
              top: context.responsiveSpacing * 0.5,
              bottom: context.responsiveSpacing * 0.5),
          child: const InteractiveSyncIndicator(),
        ),
        // زر الإعدادات
        Container(
          margin: EdgeInsets.only(
              right: context.responsiveSpacing * 0.4,
              top: context.responsiveSpacing * 0.5,
              bottom: context.responsiveSpacing * 0.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      const SettingsTabRiverpod(), // Riverpod version
                ),
              );
            },
            icon: const Icon(Icons.settings, color: Colors.white, size: 18),
            tooltip: AppLocalizations.of(context).settings,
            splashRadius: 16,
            padding: const EdgeInsets.all(8),
          ),
        ),
        // أيقونة التنبيهات مع شارة
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: AlertBadge(
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const AlertsTabRiverpod(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications,
                  color: Colors.white, size: 18),
              tooltip: AppLocalizations.of(context).notifications,
              splashRadius: 16,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ];
}
