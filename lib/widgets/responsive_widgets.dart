import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/responsive_helpers.dart';
import 'expandable_card.dart';

/// مكونات متجاوبة قابلة لإعادة الاستخدام

/// بطاقة متجاوبة للإحصائيات
class ResponsiveStatsCard extends StatelessWidget {
  const ResponsiveStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = color ?? AppConstants.primaryColor;
    final double spacing = context.responsiveSpacing;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: context.windowsCardConstraints,
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(spacing * 0.8),
          child: Row(
            children: <Widget>[
              // الأيقونة على اليسار
              Container(
                padding: EdgeInsets.all(spacing * 0.5),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: cardColor,
                  size: context.responsiveFontSize(28),
                ),
              ),
              SizedBox(width: spacing * 0.5),
              // النص والقيمة على اليمين
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // العنوان
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(18),
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: spacing * 0.3),
                    // القيمة
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(22),
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: spacing * 0.2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing * 0.4,
                          vertical: spacing * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: cardColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شبكة متجاوبة للإحصائيات
class ResponsiveStatsGrid extends StatelessWidget {
  const ResponsiveStatsGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
  });

  final List<Widget> children;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.5,
              vertical: context.responsiveSpacing * 0.3,
            ),
        child: ResponsiveHelpers.responsiveGrid(
          children: children,
          context: context,
          crossAxisSpacing: crossAxisSpacing ?? context.responsiveSpacing * 0.6,
          mainAxisSpacing: mainAxisSpacing ?? context.responsiveSpacing * 0.6,
          padding: EdgeInsets.zero,
        ),
      );
}

/// زر متجاوب
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveButton(
        text: text,
        onPressed: isLoading ? () {} : onPressed,
        context: context,
        backgroundColor: backgroundColor,
        textColor: textColor,
        isOutlined: isOutlined,
        isFullWidth: isFullWidth,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : icon,
      );
}

/// حاوية متجاوبة للنموذج
class ResponsiveFormContainer extends StatelessWidget {
  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveContainer(
        child: child,
        context: context,
        maxWidth: maxWidth,
        padding: padding,
        margin: margin,
      );
}

/// نص متجاوب
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  });

  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveText(
        text,
        context: context,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
}

/// بطاقة متجاوبة للمنتج
class ResponsiveProductCard extends StatelessWidget {
  const ResponsiveProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
    this.elevation,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveCard(
        context: context,
        onTap: onTap,
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ResponsiveText(
                    title,
                    fontSize: AppConstants.largeFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: context.responsiveSpacing * 0.25),
            ResponsiveText(
              subtitle,
              fontSize: AppConstants.mediumFontSize,
              color: AppConstants.lightTextColor,
            ),
          ],
        ),
      );
}

/// شريط بحث متجاوب
class ResponsiveSearchBar extends StatelessWidget {
  const ResponsiveSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final double spacing = context.responsiveSpacing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: controller.text.isNotEmpty && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: spacing * 0.75),
        ),
      ),
    );
  }
}

/// تخطيط متجاوب للشاشات الكبيرة
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveLayout(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        context: context,
      );
}

/// شريط جانبي متجاوب
class ResponsiveSidebar extends StatelessWidget {
  const ResponsiveSidebar({
    super.key,
    required this.mainContent,
    required this.sidebar,
    this.sidebarWidth,
    this.spacing,
  });

  final Widget mainContent;
  final Widget sidebar;
  final double? sidebarWidth;
  final double? spacing;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveSidebar(
        mainContent: mainContent,
        sidebar: sidebar,
        context: context,
        sidebarWidth: sidebarWidth,
        spacing: spacing,
      );
}

/// قائمة متجاوبة
class ResponsiveList extends StatelessWidget {
  const ResponsiveList({
    super.key,
    required this.children,
    this.spacing,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  final List<Widget> children;
  final double? spacing;
  final EdgeInsets? padding;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    final double spacingValue = spacing ?? context.responsiveSpacing;

    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      padding: padding ?? EdgeInsets.all(spacingValue),
      child: scrollDirection == Axis.vertical
          ? ResponsiveHelpers.responsiveColumn(
              children: children,
              context: context,
              spacing: spacingValue,
            )
          : ResponsiveHelpers.responsiveRow(
              children: children,
              context: context,
              spacing: spacingValue,
            ),
    );
  }
}

/// حاوية متجاوبة للشبكة
class ResponsiveGridContainer extends StatelessWidget {
  const ResponsiveGridContainer({
    super.key,
    required this.children,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
    this.aspectRatio,
  });

  final List<Widget> children;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsets? padding;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) => ResponsiveHelpers.responsiveGrid(
        children: children,
        context: context,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        padding: padding,
        aspectRatio: aspectRatio,
      );
}

/// بطاقة قابلة للتوسع متجاوبة
class ResponsiveExpandableCard extends StatelessWidget {
  const ResponsiveExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.headerColor,
    this.expandedColor,
    this.elevation = 2,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onExpansionChanged,
  });

  final Widget header;
  final Widget expandedContent;
  final bool initiallyExpanded;
  final Color? headerColor;
  final Color? expandedColor;
  final double elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  Widget build(BuildContext context) => ExpandableCard(
      header: header,
      expandedContent: expandedContent,
      initiallyExpanded: initiallyExpanded,
      headerColor: headerColor,
      expandedColor: expandedColor,
      elevation: elevation,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onExpansionChanged: onExpansionChanged,
    );
}
