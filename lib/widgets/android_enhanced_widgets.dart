import 'package:flutter/material.dart';
import '../utils/android_optimizations.dart';

/// مكونات محسنة لـ Android
class AndroidEnhancedWidgets {
  /// بناء بطاقة محسنة لـ Android
  static Widget buildAndroidCard({
    required Widget child,
    required BuildContext context,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);
    final AndroidColors colors = AndroidOptimizations.getAndroidColors();

    return Container(
      margin: margin ?? EdgeInsets.all(sizes.cardMargin),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(sizes.borderRadius),
        border: border ?? Border.all(color: colors.border),
        boxShadow: boxShadow ??
            <BoxShadow>[
              BoxShadow(
                color: colors.shadow,
                blurRadius: elevation ?? 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(sizes.borderRadius),
          splashColor: colors.primary.withValues(alpha: 0.1),
          highlightColor: colors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: padding ?? EdgeInsets.all(sizes.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }

  /// بناء زر محسن لـ Android
  static Widget buildAndroidButton({
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double? height,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);
    final AndroidColors colors = AndroidOptimizations.getAndroidColors();

    return SizedBox(
      width: width,
      height: height ?? sizes.buttonHeight,
      child: Material(
        color: isOutlined
            ? Colors.transparent
            : (backgroundColor ?? colors.primary),
        borderRadius: borderRadius ?? BorderRadius.circular(sizes.borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius:
              borderRadius ?? BorderRadius.circular(sizes.borderRadius),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isOutlined
                ? BoxDecoration(
                    borderRadius: borderRadius ??
                        BorderRadius.circular(sizes.borderRadius),
                    border:
                        Border.all(color: backgroundColor ?? colors.primary),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading) ...<Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOutlined
                            ? (backgroundColor ?? colors.primary)
                            : (textColor ?? Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: sizes.iconSize,
                    color: isOutlined
                        ? (backgroundColor ?? colors.primary)
                        : (textColor ?? Colors.white),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined
                        ? (backgroundColor ?? colors.primary)
                        : (textColor ?? Colors.white),
                    fontSize: sizes.fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء حقل إدخال محسن لـ Android
  static Widget buildAndroidTextField({
    required BuildContext context,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLines,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    bool enabled = true,
    bool readOnly = false,
    Color? fillColor,
    Color? borderColor,
    double? borderRadius,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);
    final AndroidColors colors = AndroidOptimizations.getAndroidColors();

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      enabled: enabled,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: sizes.fontSize,
        color: colors.text,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, size: sizes.iconSize) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? colors.background,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? colors.border),
          borderRadius:
              BorderRadius.circular(borderRadius ?? sizes.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
          borderRadius:
              BorderRadius.circular(borderRadius ?? sizes.borderRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error),
          borderRadius:
              BorderRadius.circular(borderRadius ?? sizes.borderRadius),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error, width: 2),
          borderRadius:
              BorderRadius.circular(borderRadius ?? sizes.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: sizes.cardPadding,
          vertical: sizes.cardPadding,
        ),
        isDense: true,
      ),
    );
  }

  /// بناء قائمة محسنة لـ Android
  static Widget buildAndroidListTile({
    required String title,
    required BuildContext context,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
    EdgeInsets? contentPadding,
    bool dense = false,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);
    final AndroidColors colors = AndroidOptimizations.getAndroidColors();

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: sizes.fontSize,
          fontWeight: FontWeight.w500,
          color: colors.text,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: sizes.fontSize - 2,
                color: colors.textLight,
              ),
            )
          : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      tileColor: backgroundColor,
      contentPadding: contentPadding ??
          EdgeInsets.symmetric(
            horizontal: sizes.cardPadding,
            vertical: dense ? 4 : 8,
          ),
      dense: dense,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.borderRadius),
      ),
    );
  }

  /// بناء شريط بحث محسن لـ Android
  static Widget buildAndroidSearchBar({
    required BuildContext context,
    required TextEditingController controller,
    required void Function(String) onChanged,
    String? hintText,
    Widget? suffixIcon,
    bool showFilterButtons = true,
    VoidCallback? onFilterTap,
    VoidCallback? onSortTap,
    VoidCallback? onResetTap,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);
    final AndroidColors colors = AndroidOptimizations.getAndroidColors();

    return Container(
      margin: EdgeInsets.all(sizes.cardMargin),
      padding: EdgeInsets.all(sizes.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(sizes.borderRadius),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(fontSize: sizes.fontSize),
            decoration: InputDecoration(
              hintText: hintText ?? 'البحث...',
              hintStyle: TextStyle(
                fontSize: sizes.fontSize,
                color: colors.textLight,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: sizes.iconSize,
                color: colors.primary,
              ),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: colors.background,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
                borderRadius: BorderRadius.circular(sizes.borderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.primary, width: 2),
                borderRadius: BorderRadius.circular(sizes.borderRadius),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: sizes.cardPadding,
                vertical: sizes.cardPadding,
              ),
              isDense: true,
            ),
          ),
          if (showFilterButtons) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: buildAndroidButton(
                    label: 'ترتيب',
                    onPressed: onSortTap ?? () {},
                    context: context,
                    icon: Icons.sort,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildAndroidButton(
                    label: 'فلترة',
                    onPressed: onFilterTap ?? () {},
                    context: context,
                    icon: Icons.filter_list,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildAndroidButton(
                    label: 'إعادة تعيين',
                    onPressed: onResetTap ?? () {},
                    context: context,
                    icon: Icons.refresh,
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات محسنة لـ Android
  static Widget buildAndroidInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    final AndroidSizes sizes = AndroidOptimizations.getAndroidSizes(context);

    return buildAndroidCard(
      context: context,
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: sizes.iconSize, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: sizes.fontSize - 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: sizes.fontSize + 2,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
