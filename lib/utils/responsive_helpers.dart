import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

/// أدوات مساعدة للتصميم المتجاوب
class ResponsiveHelpers {
  /// إنشاء تخطيط متجاوب للشبكة
  static Widget responsiveGrid({
    required List<Widget> children,
    required BuildContext context,
    double? itemWidth,
    double? aspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    EdgeInsets? padding,
  }) {
    final double spacing = context.responsiveSpacing;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns =
            context.isSmallScreen ? 2 : 3; // 2 أعمدة للشاشات الصغيرة، 3 للكبيرة
        final double availableWidth = constraints.maxWidth;
        final double itemWidth = (availableWidth -
                (padding?.horizontal ?? spacing * 2) -
                ((crossAxisSpacing ?? spacing * 0.5) * (columns - 1))) /
            columns;
        final double itemHeight =
            itemWidth * 0.7; // جعل البطاقات مستطيلة (أعرض من ارتفاعها)

        return Wrap(
          spacing: crossAxisSpacing ?? spacing * 0.5,
          runSpacing: mainAxisSpacing ?? spacing * 0.5,
          children: children
              .map((Widget child) => SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: child,
                  ))
              .toList(),
        );
      },
    );
  }

  /// إنشاء تخطيط متجاوب للصفوف
  static Widget responsiveRow({
    required List<Widget> children,
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double? spacing,
  }) {
    final double spacingValue = spacing ?? context.responsiveSpacing;

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children
          .expand((Widget child) => <Widget>[
                child,
                if (child != children.last) SizedBox(width: spacingValue),
              ])
          .toList(),
    );
  }

  /// إنشاء تخطيط متجاوب للأعمدة
  static Widget responsiveColumn({
    required List<Widget> children,
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double? spacing,
  }) {
    final double spacingValue = spacing ?? context.responsiveSpacing;

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children
          .expand((Widget child) => <Widget>[
                child,
                if (child != children.last) SizedBox(height: spacingValue),
              ])
          .toList(),
    );
  }

  /// إنشاء حاوية متجاوبة
  static Widget responsiveContainer({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
    double? minWidth,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    Decoration? decoration,
    double? borderRadius,
    BoxShadow? shadow,
  }) {
    final double maxWidthValue = maxWidth ?? context.maxContainerWidth;
    final double paddingValue = context.responsiveSpacing;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidthValue,
        minWidth: minWidth ?? 0,
      ),
      padding: padding ?? EdgeInsets.all(paddingValue),
      margin: margin,
      decoration: decoration ??
          BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
            boxShadow: shadow != null ? <BoxShadow>[shadow] : null,
          ),
      child: child,
    );
  }

  /// إنشاء نص متجاوب
  static Widget responsiveText(
    String text, {
    required BuildContext context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    TextStyle? style,
  }) {
    final double baseFontSize = fontSize ?? 16;
    final double responsiveFontSize = context.responsiveFontSize(baseFontSize);

    return Text(
      text,
      style: style ??
          TextStyle(
            fontSize: responsiveFontSize,
            fontWeight: fontWeight,
            color: color,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// إنشاء زر متجاوب
  static Widget responsiveButton({
    required String text,
    required VoidCallback onPressed,
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    double? borderRadius,
    Widget? icon,
    bool isOutlined = false,
    bool isFullWidth = false,
  }) {
    final double buttonPadding = context.responsiveSpacing;
    final double buttonBorderRadius = borderRadius ?? 12;

    final Widget buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon,
              SizedBox(width: buttonPadding * 0.5),
              Text(text),
            ],
          )
        : Text(text);

    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? Theme.of(context).primaryColor,
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).primaryColor,
              width: 1.5,
            ),
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: buttonPadding * 1.5,
                  vertical: buttonPadding,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: buttonPadding * 1.5,
                vertical: buttonPadding,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
        child: buttonChild,
      ),
    );
  }

  /// إنشاء بطاقة متجاوبة
  static Widget responsiveCard({
    required Widget child,
    required BuildContext context,
    Color? color,
    double? elevation,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxShadow? shadow,
    VoidCallback? onTap,
  }) {
    final double cardPadding = context.responsiveSpacing;
    final double cardBorderRadius = borderRadius ?? 12;

    Widget cardChild = Container(
      padding: padding ?? EdgeInsets.all(cardPadding),
      child: child,
    );

    if (onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: cardChild,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: shadow != null
            ? <BoxShadow>[shadow]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: cardChild,
    );
  }

  /// إنشاء تخطيط متجاوب للشاشات الكبيرة
  static Widget responsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    required BuildContext context,
  }) {
    if (context.isDesktopScreen && desktop != null) {
      return desktop;
    } else if (context.isMediumScreen && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// إنشاء تخطيط متجاوب للشريط الجانبي
  static Widget responsiveSidebar({
    required Widget mainContent,
    required Widget sidebar,
    required BuildContext context,
    double? sidebarWidth,
    double? spacing,
  }) {
    if (context.isSmallScreen) {
      return mainContent;
    }

    final double sidebarWidthValue = sidebarWidth ?? 300;
    final double spacingValue = spacing ?? context.responsiveSpacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: sidebarWidthValue,
          child: sidebar,
        ),
        SizedBox(width: spacingValue),
        Expanded(child: mainContent),
      ],
    );
  }

  /// إنشاء تخطيط متجاوب للشبكة مع عناصر مختلفة الأحجام
  static Widget responsiveStaggeredGrid({
    required List<Widget> children,
    required BuildContext context,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    EdgeInsets? padding,
  }) {
    final double spacing = context.responsiveSpacing;
    final int columns = context.gridColumns;

    return Padding(
      padding: padding ?? EdgeInsets.all(spacing),
      child: Wrap(
        spacing: crossAxisSpacing ?? spacing * 0.5,
        runSpacing: mainAxisSpacing ?? spacing * 0.5,
        children: children
            .map((Widget child) => SizedBox(
                  width: (context.screenWidth -
                          (spacing * 2) -
                          ((crossAxisSpacing ?? spacing * 0.5) *
                              (columns - 1))) /
                      columns,
                  child: child,
                ))
            .toList(),
      ),
    );
  }
}
