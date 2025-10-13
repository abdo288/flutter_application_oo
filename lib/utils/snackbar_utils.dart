import 'package:flutter/material.dart';
import 'constants.dart';

class SnackbarUtils {
  /// عرض رسالة نجاح
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.successColor);
  }

  /// عرض رسالة خطأ
  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.errorColor);
  }

  /// عرض رسالة تحذير
  static void showWarning(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.warningColor);
  }

  /// عرض رسالة معلومات
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, AppConstants.primaryColor);
  }

  /// عرض رسالة مخصصة
  static void _showSnackbar(
      BuildContext context, String message, Color backgroundColor) {
    if (context.mounted) {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
