import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// مساعد تنسيق العملة مع وضع رمز العملة على اليمين
class CurrencyFormatter {
  /// تنسيق العملة مع وضع DZ على اليمين
  static String formatCurrency(double amount, BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;

    // تنسيق الرقم حسب اللغة - استخدام تنسيق رقمي عادي فقط
    String formattedNumber;
    switch (locale) {
      case 'ar':
        // استخدام تنسيق رقمي عادي بدون رمز عملة - استخدام en لتجنب مشاكل العربية
        formattedNumber = NumberFormat('#,##0.00', 'en').format(amount);
        break;
      case 'fr':
        formattedNumber = NumberFormat('#,##0.00', 'fr').format(amount);
        break;
      case 'en':
      default:
        formattedNumber = NumberFormat('#,##0.00', 'en').format(amount);
        break;
    }

    // إضافة DZ على اليمين دائماً
    return '$formattedNumber DZ';
  }

  /// تنسيق العملة بدون كسور عشرية
  static String formatCurrencyNoDecimals(double amount, BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;

    // تنسيق الرقم حسب اللغة - استخدام تنسيق رقمي عادي فقط
    String formattedNumber;
    switch (locale) {
      case 'ar':
        // استخدام تنسيق رقمي عادي بدون رمز عملة - استخدام en لتجنب مشاكل العربية
        formattedNumber = NumberFormat('#,##0', 'en').format(amount);
        break;
      case 'fr':
        formattedNumber = NumberFormat('#,##0', 'fr').format(amount);
        break;
      case 'en':
      default:
        formattedNumber = NumberFormat('#,##0', 'en').format(amount);
        break;
    }

    // إضافة DZ على اليمين دائماً
    return '$formattedNumber DZ';
  }

  /// تنسيق الأرقام العادية مع فواصل الآلاف
  static String formatNumber(int number, BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;

    switch (locale) {
      case 'ar':
        // استخدام en لتجنب مشاكل العربية
        return NumberFormat('#,###', 'en').format(number);
      case 'fr':
        return NumberFormat('#,###', 'fr').format(number);
      case 'en':
      default:
        return NumberFormat('#,###', 'en').format(number);
    }
  }

  /// اختبار تنسيق العملة للتأكد من وضع DZ على اليمين
  static String testCurrencyFormat(double amount, String languageCode) {
    String formattedNumber;
    switch (languageCode) {
      case 'ar':
        // استخدام en لتجنب مشاكل العربية
        formattedNumber = NumberFormat('#,##0.00', 'en').format(amount);
        break;
      case 'fr':
        formattedNumber = NumberFormat('#,##0.00', 'fr').format(amount);
        break;
      case 'en':
      default:
        formattedNumber = NumberFormat('#,##0.00', 'en').format(amount);
        break;
    }

    // إضافة DZ على اليمين دائماً
    return '$formattedNumber DZ';
  }

  /// اختبار شامل للتنسيق في جميع اللغات
  static Map<String, String> testAllLanguages(double amount) =>
      <String, String>{
        'ar': testCurrencyFormat(amount, 'ar'),
        'en': testCurrencyFormat(amount, 'en'),
        'fr': testCurrencyFormat(amount, 'fr'),
      };
}
