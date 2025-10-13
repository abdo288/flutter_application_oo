import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/responsive_helpers.dart';
import 'responsive_widgets.dart';

/// مكون اختبار للتصميم المتجاوب
class ResponsiveTestWidget extends StatelessWidget {
  const ResponsiveTestWidget({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.all(context.responsiveSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // معلومات الشاشة
            _buildScreenInfo(context),

            SizedBox(height: context.responsiveSpacing),

            // اختبار البطاقات المتجاوبة
            _buildStatsTest(context),

            SizedBox(height: context.responsiveSpacing),

            // اختبار الأزرار المتجاوبة
            _buildButtonsTest(context),

            SizedBox(height: context.responsiveSpacing),

            // اختبار النصوص المتجاوبة
            _buildTextTest(context),

            SizedBox(height: context.responsiveSpacing),

            // اختبار الشبكة المتجاوبة
            _buildGridTest(context),
          ],
        ),
      );

  /// معلومات الشاشة
  Widget _buildScreenInfo(BuildContext context) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveText(
              AppLocalizations.of(context).screenInfo,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveText(
              '${AppLocalizations.of(context).width}: ${context.screenWidth.toStringAsFixed(0)}px',
              fontSize: AppConstants.mediumFontSize,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).height}: ${context.screenHeight.toStringAsFixed(0)}px',
              fontSize: AppConstants.mediumFontSize,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).deviceType}: ${_getDeviceTypeName(context, context.deviceType)}',
              fontSize: AppConstants.mediumFontSize,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).columnsCount}: ${context.gridColumns}',
              fontSize: AppConstants.mediumFontSize,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).spacing}: ${context.responsiveSpacing.toStringAsFixed(1)}px',
              fontSize: AppConstants.mediumFontSize,
            ),
          ],
        ),
      );

  /// اختبار البطاقات المتجاوبة
  Widget _buildStatsTest(BuildContext context) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveText(
              AppLocalizations.of(context).responsiveCardsTest,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveStatsGrid(
              children: <Widget>[
                ResponsiveStatsCard(
                  title: AppLocalizations.of(context).totalProducts,
                  value: '150',
                  icon: Icons.shopping_cart,
                  color: AppConstants.primaryColor,
                ),
                ResponsiveStatsCard(
                  title: AppLocalizations.of(context).totalValue,
                  value: CurrencyFormatter.formatCurrency(25000.0, context),
                  icon: Icons.attach_money,
                  color: AppConstants.successColor,
                ),
                ResponsiveStatsCard(
                  title: AppLocalizations.of(context).todaySales,
                  value: '25',
                  icon: Icons.today,
                  color: AppConstants.warningColor,
                ),
                ResponsiveStatsCard(
                  title: AppLocalizations.of(context).profits,
                  value: CurrencyFormatter.formatCurrency(5000.0, context),
                  icon: Icons.trending_up,
                  color: AppConstants.secondaryColor,
                ),
              ],
            ),
          ],
        ),
      );

  /// اختبار الأزرار المتجاوبة
  Widget _buildButtonsTest(BuildContext context) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveText(
              AppLocalizations.of(context).responsiveButtonsTest,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveHelpers.responsiveRow(
              children: <Widget>[
                ResponsiveButton(
                  text: AppLocalizations.of(context).normalButton,
                  onPressed: () {},
                  isFullWidth: context.isSmallScreen,
                ),
                ResponsiveButton(
                  text: AppLocalizations.of(context).outlinedButton,
                  onPressed: () {},
                  isOutlined: true,
                  isFullWidth: context.isSmallScreen,
                ),
                ResponsiveButton(
                  text: AppLocalizations.of(context).iconButton,
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  isFullWidth: context.isSmallScreen,
                ),
              ],
              context: context,
            ),
          ],
        ),
      );

  /// اختبار النصوص المتجاوبة
  Widget _buildTextTest(BuildContext context) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveText(
              AppLocalizations.of(context).responsiveTextTest,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveText(
              '${AppLocalizations.of(context).largeText} - ${AppConstants.titleFontSize}px',
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).mediumText} - ${AppConstants.largeFontSize}px',
              fontSize: AppConstants.largeFontSize,
              fontWeight: FontWeight.w600,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).normalText} - ${AppConstants.mediumFontSize}px',
              fontSize: AppConstants.mediumFontSize,
            ),
            ResponsiveText(
              '${AppLocalizations.of(context).smallText} - ${AppConstants.smallFontSize}px',
              fontSize: AppConstants.smallFontSize,
              color: AppConstants.lightTextColor,
            ),
          ],
        ),
      );

  /// اختبار الشبكة المتجاوبة
  Widget _buildGridTest(BuildContext context) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveText(
              AppLocalizations.of(context).responsiveGridTest,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveText(
              '${AppLocalizations.of(context).columnsCount}: ${context.gridColumns}',
              fontSize: AppConstants.mediumFontSize,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            ResponsiveGridContainer(
              children: List.generate(
                8,
                (int index) => ResponsiveHelpers.responsiveCard(
                  context: context,
                  child: Center(
                    child: ResponsiveText(
                      '${AppLocalizations.of(context).item} ${index + 1}',
                      fontSize: AppConstants.mediumFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  /// الحصول على اسم نوع الجهاز
  String _getDeviceTypeName(BuildContext context, DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return AppLocalizations.of(context).mobile;
      case DeviceType.tablet:
        return AppLocalizations.of(context).tablet;
      case DeviceType.desktop:
        return AppLocalizations.of(context).desktop;
      case DeviceType.largeDesktop:
        return AppLocalizations.of(context).largeDesktop;
      case DeviceType.ultraWide:
        return AppLocalizations.of(context).ultraWide;
    }
  }
}
