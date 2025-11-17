import 'package:flutter/material.dart';
import 'constants.dart';
import 'safe_context_utils.dart';

class SnackbarUtils {
  /// عرض رسالة نجاح
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
        context, message, AppConstants.successColor, Icons.check_circle);
  }

  /// عرض رسالة خطأ
  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.errorColor, Icons.error);
  }

  /// عرض رسالة تحذير
  static void showWarning(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.warningColor, Icons.warning);
  }

  /// عرض رسالة معلومات
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.primaryColor, Icons.info);
  }

  /// عرض رسالة نجاح مع أيقونة
  static void showSuccessWithIcon(BuildContext context, String message,
      {IconData? icon}) {
    _showSnackbarWithIcon(context, message, AppConstants.successColor,
        icon ?? Icons.check_circle);
  }

  /// عرض رسالة خطأ مع أيقونة
  static void showErrorWithIcon(BuildContext context, String message,
      {IconData? icon}) {
    _showSnackbarWithIcon(
        context, message, AppConstants.errorColor, icon ?? Icons.error);
  }

  /// عرض رسالة مخصصة
  static void _showSnackbar(BuildContext context, String message,
      Color backgroundColor, IconData icon) {
    if (!context.mounted) return;

    try {
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      // Widget might have been disposed between the check and the call
      debugPrint('⚠️ Failed to show SnackBar (widget disposed): $e');
    }
  }

  /// عرض رسالة مخصصة مع أيقونة
  static void _showSnackbarWithIcon(BuildContext context, String message,
      Color backgroundColor, IconData icon) {
    if (!context.mounted) return;

    try {
      final SnackBar snackBar = SnackBar(
        content: Row(
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      // Widget might have been disposed between the check and the call
      debugPrint('⚠️ Failed to show SnackBar (widget disposed): $e');
    }
  }

  /// Safe method to show SnackBar with additional safety checks
  static void showSafeSnackBar(BuildContext context, SnackBar snackBar) {
    SafeContextUtils.safeShowSnackBar(context, snackBar);
  }
}
