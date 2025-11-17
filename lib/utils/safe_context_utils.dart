import 'package:flutter/material.dart';

/// Utility class for safe context operations
class SafeContextUtils {
  /// Safely executes a function with context, checking if widget is mounted
  static T? safeExecute<T>(
    BuildContext context,
    T Function() operation, {
    String? errorMessage,
    bool logError = true,
  }) {
    try {
      if (!context.mounted) {
        if (logError) {
          debugPrint(
              '⚠️ Widget not mounted, skipping operation${errorMessage != null ? ': $errorMessage' : ''}');
        }
        return null;
      }
      return operation();
    } catch (e) {
      if (logError) {
        debugPrint(
            '❌ Error in safe context operation${errorMessage != null ? ': $errorMessage' : ''} - $e');
      }
      return null;
    }
  }

  /// Safely executes an async function with context, checking if widget is mounted
  static Future<T?> safeExecuteAsync<T>(
    BuildContext context,
    Future<T?> Function() operation, {
    String? errorMessage,
    bool logError = true,
  }) async {
    try {
      if (!context.mounted) {
        if (logError) {
          debugPrint(
              '⚠️ Widget not mounted, skipping async operation${errorMessage != null ? ': $errorMessage' : ''}');
        }
        return null;
      }
      return await operation();
    } catch (e) {
      if (logError) {
        debugPrint(
            '❌ Error in safe async context operation${errorMessage != null ? ': $errorMessage' : ''} - $e');
      }
      return null;
    }
  }

  /// Safely shows a SnackBar
  static void safeShowSnackBar(BuildContext context, SnackBar snackBar,
      {String? errorMessage}) {
    safeExecute(
      context,
      () => ScaffoldMessenger.of(context).showSnackBar(snackBar),
      errorMessage: errorMessage ?? 'Failed to show SnackBar',
    );
  }

  /// Safely navigates
  static Future<T?> safeNavigate<T>(
    BuildContext context,
    Future<T?> Function() navigation, {
    String? errorMessage,
  }) => safeExecuteAsync(
      context,
      navigation,
      errorMessage: errorMessage ?? 'Failed to navigate',
    );

  /// Safely pops the current route
  static void safePop(BuildContext context, {String? errorMessage}) {
    safeExecute(
      context,
      () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      errorMessage: errorMessage ?? 'Failed to pop route',
    );
  }

  /// Safely pushes a route
  static Future<T?> safePush<T>(
    BuildContext context,
    Route<T> route, {
    String? errorMessage,
  }) => safeExecuteAsync(
      context,
      () => Navigator.of(context).push<T>(route),
      errorMessage: errorMessage ?? 'Failed to push route',
    );

  /// Safely shows a dialog
  static Future<T?> safeShowDialog<T>(
    BuildContext context,
    Future<T?> Function() dialogBuilder, {
    String? errorMessage,
  }) => safeExecuteAsync(
      context,
      dialogBuilder,
      errorMessage: errorMessage ?? 'Failed to show dialog',
    );

  /// Safely shows a modal bottom sheet
  static Future<T?> safeShowModalBottomSheet<T>(
    BuildContext context,
    Future<T?> Function() bottomSheetBuilder, {
    String? errorMessage,
  }) => safeExecuteAsync(
      context,
      bottomSheetBuilder,
      errorMessage: errorMessage ?? 'Failed to show bottom sheet',
    );
}
