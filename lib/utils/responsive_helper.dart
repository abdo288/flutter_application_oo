import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

/// مساعد شامل للتصميم المتجاوب
class ResponsiveHelper {
  /// الحصول على constraints مناسبة للديالوجات
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.9,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.85,
        maxHeight: screenHeight * 0.8,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 500,
        maxHeight: 600,
      );
    }
  }

  /// الحصول على padding مناسب للشاشة
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return const EdgeInsets.all(8.0);
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// الحصول على spacing مناسب للشاشة
  static double getResponsiveSpacing(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.getSpacing(screenWidth);
  }

  /// الحصول على حجم خط مناسب
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.getFontSize(screenWidth, baseFontSize);
  }

  /// تحديد ما إذا كان يجب استخدام layout عمودي
  static bool shouldUseVerticalLayout(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < ResponsiveBreakpoints.mobile;
  }

  /// تحديد ما إذا كان يجب استخدام layout أفقي
  static bool shouldUseHorizontalLayout(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= ResponsiveBreakpoints.tablet;
  }

  /// الحصول على عدد الأعمدة المناسب للشبكة
  static int getResponsiveGridColumns(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.getGridColumns(screenWidth);
  }

  /// الحصول على aspect ratio مناسب للكروت
  static double getResponsiveAspectRatio(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return 1.2; // أطول للشاشات الصغيرة
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return 1.0; // مربع للتابلت
    } else {
      return 0.8; // أوسع للشاشات الكبيرة
    }
  }

  /// الحصول على constraints للصور
  static BoxConstraints getImageConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return const BoxConstraints(
        maxWidth: 80,
        maxHeight: 80,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return const BoxConstraints(
        maxWidth: 100,
        maxHeight: 100,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 120,
        maxHeight: 120,
      );
    }
  }

  /// الحصول على constraints للنصوص
  static BoxConstraints getTextConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.7,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.6,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 300,
      );
    }
  }

  /// تحديد ما إذا كان يجب إظهار scroll indicator
  static bool shouldShowScrollIndicator(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 600; // شاشات قصيرة
  }

  /// الحصول على scroll physics مناسبة
  static ScrollPhysics getResponsiveScrollPhysics(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return const BouncingScrollPhysics();
    } else {
      return const ClampingScrollPhysics();
    }
  }

  /// تحديد ما إذا كان يجب استخدام Wrap بدلاً من Row
  static bool shouldUseWrap(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < ResponsiveBreakpoints.mobile;
  }

  /// الحصول على constraints للفلاتر
  static BoxConstraints getFilterConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.8,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 400,
      );
    }
  }

  /// تحديد ما إذا كان يجب استخدام TabBar scrollable
  static bool shouldUseScrollableTabBar(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < ResponsiveBreakpoints.tablet;
  }

  /// الحصول على constraints للـ AppBar
  static double getAppBarHeight(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < 600) {
      return 48.0; // AppBar أقصر للشاشات الصغيرة
    } else {
      return kToolbarHeight;
    }
  }

  /// تحديد ما إذا كان يجب استخدام SafeArea
  static bool shouldUseSafeArea(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 600;
  }

  /// الحصول على constraints للـ BottomNavigationBar
  static double getBottomNavBarHeight(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < 600) {
      return 56.0; // BottomNavBar أقصر للشاشات الصغيرة
    } else {
      return kBottomNavigationBarHeight;
    }
  }

  /// تحديد ما إذا كان يجب استخدام compact layout
  static bool shouldUseCompactLayout(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 600;
  }

  /// الحصول على constraints للـ Cards
  static BoxConstraints getCardConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        minHeight: 100,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        minHeight: 120,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 300,
        minHeight: 140,
      );
    }
  }

  /// تحديد ما إذا كان يجب استخدام single column layout
  static bool shouldUseSingleColumn(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < ResponsiveBreakpoints.mobile;
  }

  /// الحصول على constraints للـ input fields
  static BoxConstraints getInputConstraints(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        minHeight: 48,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 300,
        minHeight: 56,
      );
    }
  }
}

