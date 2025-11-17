import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/responsive_helpers.dart';
import 'safe_bottom_navigation.dart';

/// تنقل متجاوب للتطبيق
class ResponsiveNavigation extends StatelessWidget {
  const ResponsiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ResponsiveNavigationItem>? items;

  @override
  Widget build(BuildContext context) {
    final List<ResponsiveNavigationItem> navigationItems =
        items ?? _getDefaultItems(context);

    if (context.isSmallScreen) {
      return _buildBottomNavigation(context, navigationItems);
    } else {
      return _buildSideNavigation(context, navigationItems);
    }
  }

  /// بناء التنقل السفلي للشاشات الصغيرة مع حماية من الأخطاء
  Widget _buildBottomNavigation(
          BuildContext context, List<ResponsiveNavigationItem> items) =>
      SafeBottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: onTap,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.lightTextColor,
        selectedIconTheme: const IconThemeData(
          color: AppConstants.primaryColor,
          size: 20, // Reduced from largeIconSize
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppConstants.lightTextColor,
          size: 18, // Reduced from mediumIconSize
        ),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10, // Reduced font size
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 9, // Reduced font size
        ),
        items: items
            .map((ResponsiveNavigationItem item) => BottomNavigationBarItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon ?? item.icon,
                  label: _getShortLabel(item.label), // Use shortened labels
                ))
            .toList(),
        onTapErrorHandler: (Object error, StackTrace stackTrace) {
          // معالجة إضافية لأخطاء التنقل إذا لزم الأمر
          debugPrint('خطأ في التنقل السفلي: $error');
        },
      );

  /// بناء التنقل الجانبي للشاشات الكبيرة مع حماية من الأخطاء
  Widget _buildSideNavigation(
          BuildContext context, List<ResponsiveNavigationItem> items) =>
      SafeSideNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        width: 250,
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textColor,
        items: items.map((ResponsiveNavigationItem item) {
          // استخراج IconData من Widget
          IconData iconData = Icons.dashboard; // قيمة افتراضية
          if (item.icon is Icon) {
            iconData = (item.icon as Icon).icon!;
          } else if (item.activeIcon is Icon) {
            iconData = (item.activeIcon as Icon).icon!;
          }
          return SafeNavigationItem(
            icon: iconData,
            label: item.label,
          );
        }).toList(),
        onTapErrorHandler: (Object error, StackTrace stackTrace) {
          // معالجة إضافية لأخطاء التنقل الجانبي إذا لزم الأمر
          debugPrint('خطأ في التنقل الجانبي: $error');
        },
      );

  /// تقصير النصوص للشاشات الصغيرة
  String _getShortLabel(String label) {
    // Map full labels to short versions
    switch (label) {
      case 'لوحة التحكم':
        return 'لوحة';
      case 'البيع السريع':
        return 'بيع';
      case 'نموذج المنتج':
        return 'نموذج';
      case 'سجل المبيعات':
        return 'مبيعات';
      case 'التقارير':
        return 'تقارير';
      case 'نقطة البيع':
        return 'نقطة';
      case 'المخزون':
        return 'مخزون';
      case 'إعدادات التحديثات الفورية':
        return 'إعدادات';
      default:
        // If label is longer than 6 characters, truncate it
        return label.length > 6 ? '${label.substring(0, 6)}...' : label;
    }
  }

  /// الحصول على عناصر التنقل الافتراضية
  List<ResponsiveNavigationItem> _getDefaultItems(BuildContext context) =>
      <ResponsiveNavigationItem>[
        const ResponsiveNavigationItem(
          icon: Icon(Icons.dashboard),
          label: 'لوحة التحكم',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.add_box),
          label: 'البيع السريع',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.inventory_2),
          label: 'نموذج المنتج',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.list),
          label: 'سجل المبيعات',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.analytics),
          label: 'التقارير',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.point_of_sale),
          label: 'نقطة البيع',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.show_chart),
          label: 'المخزون',
        ),
        const ResponsiveNavigationItem(
          icon: Icon(Icons.sync),
          label: 'إعدادات التحديثات الفورية',
        ),
      ];
}

/// عنصر التنقل
class ResponsiveNavigationItem {
  const ResponsiveNavigationItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  final Widget icon;
  final Widget? activeIcon;
  final String label;
  final int? badge;
}

/// شريط علوي متجاوب
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) => AppBar(
        title: ResponsiveHelpers.responsiveText(
          title,
          context: context,
          fontSize: AppConstants.titleFontSize,
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? Colors.white,
        ),
        actions: actions,
        leading: leading,
        backgroundColor: backgroundColor ?? AppConstants.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: elevation ?? 2,
        centerTitle: centerTitle ?? false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                backgroundColor ?? AppConstants.primaryColor,
                (backgroundColor ?? AppConstants.primaryColor)
                    .withValues(alpha: 0.9),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (backgroundColor ?? AppConstants.primaryColor)
                    .withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppConstants.largeBorderRadius),
          ),
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// شريط تنقل متجاوب للشاشات الكبيرة
class ResponsiveTabBar extends StatelessWidget {
  const ResponsiveTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.isScrollable = false,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
  });

  final List<Tab> tabs;
  final TabController controller;
  final bool isScrollable;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) => TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        labelColor: labelColor ?? AppConstants.primaryColor,
        unselectedLabelColor:
            unselectedLabelColor ?? AppConstants.lightTextColor,
        indicatorColor: indicatorColor ?? AppConstants.primaryColor,
        labelStyle: TextStyle(
          fontSize: context.responsiveFontSize(AppConstants.mediumFontSize),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: context.responsiveFontSize(AppConstants.mediumFontSize),
          fontWeight: FontWeight.w500,
        ),
      );
}

/// حاوية متجاوبة للمحتوى
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.backgroundColor,
    this.constraints,
    this.isScrollable = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final Color? backgroundColor;
  final BoxConstraints? constraints;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      constraints: constraints ??
          BoxConstraints(
            maxWidth: maxWidth ?? context.maxContainerWidth,
          ),
      padding: padding ?? EdgeInsets.all(context.responsiveSpacing),
      margin: margin,
      color: backgroundColor,
      child: child,
    );

    if (isScrollable) {
      return SingleChildScrollView(
        child: content,
      );
    }

    return content;
  }
}
