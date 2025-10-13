import 'package:flutter/material.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/constants.dart';

/// مكون مساعد للبطاقات المتجاوبة
/// يوفر تخطيط مرن يتكيف مع حجم المحتوى والشاشة
class ResponsiveCardWrapper extends StatelessWidget {
  const ResponsiveCardWrapper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.preventOverflow = true,
    this.clipBehavior = Clip.antiAlias,
    this.elevation,
    this.shadowColor,
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool preventOverflow;
  final Clip clipBehavior;
  final double? elevation;
  final Color? shadowColor;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب القيود الآمنة بناءً على المساحة المتاحة
        final BoxConstraints safeConstraints = BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );

        Widget content = Container(
          constraints: safeConstraints,
          padding: padding ?? context.responsivePadding,
          margin: margin ?? EdgeInsets.all(context.responsiveSpacing * 0.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius ??
                BorderRadius.circular(context.isSmallScreen ? 8 : 12),
            border: border,
            boxShadow: elevation != null
                ? [
                    BoxShadow(
                      color: shadowColor ?? Colors.black.withValues(alpha: 0.1),
                      blurRadius: elevation!,
                      offset: Offset(0, elevation! / 2),
                    ),
                  ]
                : null,
          ),
          child: preventOverflow
              ? ClipRect(
                  child: child,
                )
              : child,
        );

        if (onTap != null) {
          content = Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius ??
                  BorderRadius.circular(context.isSmallScreen ? 8 : 12),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

/// مكون بطاقة إحصائيات متجاوب
class ResponsiveStatCard extends StatelessWidget {
  const ResponsiveStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.prefix = '',
    this.suffix = '',
    this.trend,
    this.trendValue,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final String prefix;
  final String suffix;
  final String? trend;
  final String? trendValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? AppConstants.primaryColor;

    return ResponsiveCardWrapper(
      onTap: onTap,
      color: isDark
          ? cardColor.withValues(alpha: 0.1)
          : cardColor.withValues(alpha: 0.05),
      border: Border.all(
        color: cardColor.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing * 0.4),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.isSmallScreen ? 6 : 8,
                    ),
                  ),
                  child: Icon(
                    icon!,
                    color: cardColor,
                    size: context.responsiveFontSize(20),
                  ),
                ),
              if (trend != null && trendValue != null)
                _buildTrendIndicator(context, cardColor),
            ],
          ),

          SizedBox(height: context.responsiveSpacing * 0.5),

          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$prefix$value$suffix',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: cardColor,
                fontWeight: AppConstants.fontWeightBold,
                fontSize: context.responsiveFontSize(24),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(height: context.responsiveSpacing * 0.3),

          // Title
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontWeight: AppConstants.fontWeightMedium,
              fontSize: context.responsiveFontSize(12),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, Color color) {
    final isPositive = trend == 'up';
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing * 0.3,
        vertical: context.responsiveSpacing * 0.2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: context.responsiveFontSize(14),
          ),
          SizedBox(width: context.responsiveSpacing * 0.2),
          Text(
            trendValue!,
            style: TextStyle(
              color: color,
              fontSize: context.responsiveFontSize(10),
              fontWeight: AppConstants.fontWeightBold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// مكون بطاقة معلومات متجاوب
class ResponsiveInfoCard extends StatelessWidget {
  const ResponsiveInfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? AppConstants.primaryColor;

    return ResponsiveCardWrapper(
      onTap: onTap,
      color: isDark
          ? cardColor.withValues(alpha: 0.1)
          : cardColor.withValues(alpha: 0.05),
      border: Border.all(
        color: cardColor.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing * 0.4),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  context.isSmallScreen ? 8 : 12,
                ),
              ),
              child: Icon(
                icon!,
                color: cardColor,
                size: context.responsiveFontSize(24),
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
          ],

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontSize: context.responsiveFontSize(12),
              fontWeight: AppConstants.fontWeightMedium,
            ),
          ),

          SizedBox(height: context.responsiveSpacing * 0.3),

          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                fontWeight: AppConstants.fontWeightBold,
                color: cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
