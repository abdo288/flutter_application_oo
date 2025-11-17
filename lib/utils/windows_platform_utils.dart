import 'dart:io';

import 'package:flutter/foundation.dart';

/// أدوات مساعدة خاصة بمنصة Windows
class WindowsPlatformUtils {
  /// التحقق من أن التطبيق يعمل على Windows
  static bool get isWindows => Platform.isWindows;

  /// timeout محسن لـ Windows
  static Duration get windowsTimeout => const Duration(seconds: 30);

  /// timeout قصير للعمليات السريعة
  static Duration get quickTimeout => const Duration(seconds: 10);

  /// timeout متوسط للعمليات العادية
  static Duration get normalTimeout => const Duration(seconds: 20);

  /// معالجة الأخطاء الخاصة بـ Windows
  static void handleWindowsError(String operation, error) {
    if (isWindows) {
      debugPrint('🪟 Windows Error in $operation: $error');

      // معالجة أخطاء خاصة بـ Windows
      if (error.toString().contains('timeout')) {
        debugPrint('⚠️ Windows: تم تجاوز المهلة الزمنية - سيتم المتابعة');
      } else if (error.toString().contains('connection')) {
        debugPrint(
            '⚠️ Windows: مشكلة في الاتصال - سيتم المتابعة في وضع offline');
      } else if (error.toString().contains('permission')) {
        debugPrint('⚠️ Windows: مشكلة في الصلاحيات - سيتم المتابعة');
      }
    } else {
      debugPrint('❌ Error in $operation: $error');
    }
  }

  /// إعدادات محسنة لـ Windows
  static Map<String, dynamic> getWindowsOptimizations() {
    if (!isWindows) return <String, dynamic>{};

    return <String, dynamic>{
      'timeout': windowsTimeout.inSeconds,
      'retryCount': 3,
      'fallbackEnabled': true,
      'offlineMode': true,
      'debugMode': kDebugMode,
    };
  }

  /// رسالة خطأ مخصصة لـ Windows
  static String getWindowsErrorMessage(String operation) {
    if (!isWindows) return 'خطأ في $operation';

    return 'خطأ في $operation على Windows. يرجى المحاولة مرة أخرى أو المتابعة مع البيانات المتاحة.';
  }

  /// رسالة تحذيرية لـ Windows
  static String getWindowsWarningMessage(String operation) {
    if (!isWindows) return 'تحذير: $operation';

    return 'تحذير Windows: $operation. إذا استمرت المشكلة، يرجى إعادة تشغيل التطبيق.';
  }
}
