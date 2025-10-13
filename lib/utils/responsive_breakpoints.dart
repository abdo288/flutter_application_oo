import 'package:flutter/material.dart';

/// نقاط التوقف للتصميم المتجاوب
class ResponsiveBreakpoints {
  // نقاط التوقف الأساسية
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
  static const double ultraWide = 1920;

  // نقاط التوقف للشاشات الصغيرة
  static const double smallMobile = 320;
  static const double mediumMobile = 375;
  static const double largeMobile = 414;

  // نقاط التوقف للتابلت
  static const double smallTablet = 600;
  static const double largeTablet = 1024;

  // نقاط التوقف لسطح المكتب
  static const double smallDesktop = 1200;
  static const double mediumDesktop = 1600;
  static const double largeDesktopSize = 1920;

  /// تحديد نوع الجهاز بناءً على عرض الشاشة
  static DeviceType getDeviceType(double width) {
    if (width < mobile) {
      return DeviceType.mobile;
    }
    if (width < tablet) {
      return DeviceType.tablet;
    }
    if (width < desktop) {
      return DeviceType.desktop;
    }
    if (width < largeDesktop) {
      return DeviceType.largeDesktop;
    }
    return DeviceType.ultraWide;
  }

  /// تحديد ما إذا كانت الشاشة كبيرة (تابلت أو أكبر)
  static bool isLargeScreen(double width) => width >= tablet;

  /// تحديد ما إذا كانت الشاشة صغيرة (موبايل)
  static bool isSmallScreen(double width) => width < tablet;

  /// تحديد ما إذا كانت الشاشة متوسطة (تابلت)
  static bool isMediumScreen(double width) =>
      width >= tablet && width < desktop;

  /// تحديد ما إذا كانت الشاشة كبيرة (سطح المكتب)
  static bool isDesktopScreen(double width) => width >= desktop;

  /// تحديد ما إذا كانت الشاشة عريضة جداً
  static bool isUltraWideScreen(double width) => width >= ultraWide;

  /// الحصول على عدد الأعمدة المناسب للشبكة
  static int getGridColumns(double width) {
    if (width < mobile) {
      return 1;
    }
    if (width < tablet) {
      return 2;
    }
    if (width < desktop) {
      return 3;
    }
    if (width < largeDesktop) {
      return 4;
    }
    return 5;
  }

  /// الحصول على المسافات المناسبة
  static double getSpacing(double width) {
    if (width < mobile) {
      return 8.0;
    }
    if (width < tablet) {
      return 12.0;
    }
    if (width < desktop) {
      return 16.0;
    }
    if (width < largeDesktop) {
      return 20.0;
    }
    return 24.0;
  }

  /// الحصول على حجم الخط المناسب
  static double getFontSize(double width, double baseFontSize) {
    if (width < mobile) {
      return baseFontSize * 0.9;
    }
    if (width < tablet) {
      return baseFontSize;
    }
    if (width < desktop) {
      return baseFontSize * 1.1;
    }
    if (width < largeDesktop) {
      return baseFontSize * 1.2;
    }
    return baseFontSize * 1.3;
  }

  /// الحصول على عرض الحاوية الأقصى
  static double getMaxContainerWidth(double width) {
    if (width < tablet) {
      return width;
    }
    if (width < desktop) {
      return tablet;
    }
    if (width < largeDesktop) {
      return desktop;
    }
    return largeDesktop;
  }

  /// الحصول على عدد العناصر في الصف
  static int getItemsPerRow(double width, {double itemWidth = 200}) {
    final int columns = (width / itemWidth).floor();
    return columns.clamp(1, getGridColumns(width));
  }
}

/// أنواع الأجهزة
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
  ultraWide,
}

/// امتداد لـ BuildContext لتسهيل الوصول للتصميم المتجاوب
extension ResponsiveContext on BuildContext {
  /// الحصول على حجم الشاشة
  Size get screenSize => MediaQuery.of(this).size;

  /// الحصول على عرض الشاشة
  double get screenWidth => screenSize.width;

  /// الحصول على ارتفاع الشاشة
  double get screenHeight => screenSize.height;

  /// تحديد نوع الجهاز
  DeviceType get deviceType => ResponsiveBreakpoints.getDeviceType(screenWidth);

  /// تحديد ما إذا كانت الشاشة كبيرة
  bool get isLargeScreen => ResponsiveBreakpoints.isLargeScreen(screenWidth);

  /// تحديد ما إذا كانت الشاشة صغيرة
  bool get isSmallScreen => ResponsiveBreakpoints.isSmallScreen(screenWidth);

  /// تحديد ما إذا كانت الشاشة متوسطة
  bool get isMediumScreen => ResponsiveBreakpoints.isMediumScreen(screenWidth);

  /// تحديد ما إذا كانت الشاشة سطح مكتب
  bool get isDesktopScreen =>
      ResponsiveBreakpoints.isDesktopScreen(screenWidth);

  /// تحديد ما إذا كانت الشاشة عريضة جداً
  bool get isUltraWideScreen =>
      ResponsiveBreakpoints.isUltraWideScreen(screenWidth);

  /// الحصول على عدد الأعمدة المناسب
  int get gridColumns => ResponsiveBreakpoints.getGridColumns(screenWidth);

  /// الحصول على المسافات المناسبة
  double get responsiveSpacing => ResponsiveBreakpoints.getSpacing(screenWidth);

  /// الحصول على حجم الخط المتجاوب
  double responsiveFontSize(double baseFontSize) =>
      ResponsiveBreakpoints.getFontSize(screenWidth, baseFontSize);

  /// الحصول على عرض الحاوية الأقصى
  double get maxContainerWidth =>
      ResponsiveBreakpoints.getMaxContainerWidth(screenWidth);

  /// الحصول على عدد العناصر في الصف
  int itemsPerRow({double itemWidth = 200}) =>
      ResponsiveBreakpoints.getItemsPerRow(screenWidth, itemWidth: itemWidth);

  /// الحصول على constraints مناسبة للديالوجات
  BoxConstraints get dialogConstraints {
    final double screenHeight = MediaQuery.of(this).size.height;

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

  /// الحصول على padding مناسب
  EdgeInsets get responsivePadding {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return const EdgeInsets.all(8.0);
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// تحديد ما إذا كان يجب استخدام layout عمودي
  bool get shouldUseVerticalLayout =>
      screenWidth < ResponsiveBreakpoints.mobile;

  /// تحديد ما إذا كان يجب استخدام layout أفقي
  bool get shouldUseHorizontalLayout =>
      screenWidth >= ResponsiveBreakpoints.tablet;

  /// الحصول على عدد الأعمدة المناسب للشبكة
  int get responsiveGridColumns =>
      ResponsiveBreakpoints.getGridColumns(screenWidth);

  /// الحصول على aspect ratio مناسب للكروت
  double get responsiveAspectRatio {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return 1.2; // أطول للشاشات الصغيرة
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return 1.0; // مربع للتابلت
    } else if (screenWidth < ResponsiveBreakpoints.desktop) {
      return 1.4; // أوسع للشاشات الكبيرة
    } else {
      return 1.6; // أوسع للشاشات الكبيرة جداً (Windows)
    }
  }

  /// الحصول على constraints للصور
  BoxConstraints get imageConstraints {
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
  BoxConstraints get textConstraints {
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
  bool get shouldShowScrollIndicator {
    final double screenHeight = MediaQuery.of(this).size.height;
    return screenHeight < 600; // شاشات قصيرة
  }

  /// الحصول على scroll physics مناسبة
  ScrollPhysics get responsiveScrollPhysics {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return const BouncingScrollPhysics();
    } else {
      return const ClampingScrollPhysics();
    }
  }

  /// تحديد ما إذا كان يجب استخدام Wrap
  bool get shouldUseWrap => screenWidth < ResponsiveBreakpoints.mobile;

  /// الحصول على constraints للفلاتر
  BoxConstraints get filterConstraints {
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
  bool get shouldUseScrollableTabBar =>
      screenWidth < ResponsiveBreakpoints.tablet;

  /// الحصول على ارتفاع AppBar
  double get appBarHeight {
    final double screenHeight = MediaQuery.of(this).size.height;

    if (screenHeight < 600) {
      return 48.0; // AppBar أقصر للشاشات الصغيرة
    } else {
      return kToolbarHeight;
    }
  }

  /// تحديد ما إذا كان يجب استخدام SafeArea
  bool get shouldUseSafeArea {
    final double screenHeight = MediaQuery.of(this).size.height;
    return screenHeight < 600;
  }

  /// الحصول على ارتفاع BottomNavigationBar
  double get bottomNavBarHeight {
    final double screenHeight = MediaQuery.of(this).size.height;

    if (screenHeight < 600) {
      return 56.0; // BottomNavBar أقصر للشاشات الصغيرة
    } else {
      return kBottomNavigationBarHeight;
    }
  }

  /// تحديد ما إذا كان يجب استخدام compact layout
  bool get shouldUseCompactLayout {
    final double screenHeight = MediaQuery.of(this).size.height;
    return screenHeight < 600;
  }

  /// الحصول على constraints للـ Cards
  BoxConstraints get cardConstraints {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.4,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        maxHeight: screenHeight * 0.35,
      );
    } else if (screenWidth < ResponsiveBreakpoints.desktop) {
      return BoxConstraints(
        maxWidth: 400,
        maxHeight: 300,
      );
    } else {
      return BoxConstraints(
        maxWidth: 500,
        maxHeight: 400,
      );
    }
  }

  /// الحصول على constraints آمنة للبطاقات
  BoxConstraints get safeCardConstraints {
    final double availableHeight = screenHeight * 0.8;
    final double availableWidth = screenWidth * 0.9;

    return BoxConstraints(
      maxWidth: availableWidth,
      maxHeight: availableHeight,
    );
  }

  /// الحصول على constraints للبطاقات القابلة للتوسع
  BoxConstraints get expandedCardConstraints {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.6,
        minHeight: 120,
      );
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        maxHeight: screenHeight * 0.5,
        minHeight: 140,
      );
    } else if (screenWidth < ResponsiveBreakpoints.desktop) {
      return BoxConstraints(
        maxWidth: 450,
        maxHeight: 500,
        minHeight: 160,
      );
    } else {
      return BoxConstraints(
        maxWidth: 600,
        maxHeight: 600,
        minHeight: 180,
      );
    }
  }

  /// الحصول على constraints محسنة لـ Windows
  BoxConstraints get windowsCardConstraints {
    if (screenWidth >= ResponsiveBreakpoints.desktop) {
      return BoxConstraints(
        maxWidth: 500,
        maxHeight: 400,
        minHeight: 200,
      );
    }
    return cardConstraints;
  }

  /// الحصول على padding ديناميكي
  EdgeInsets get dynamicPadding {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return EdgeInsets.all(screenWidth * 0.02);
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return EdgeInsets.all(screenWidth * 0.015);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// الحصول على spacing آمن
  double get safeSpacing {
    final double baseSpacing = responsiveSpacing;
    final double availableSpace = screenHeight * 0.1;
    return baseSpacing < availableSpace ? baseSpacing : availableSpace;
  }

  /// تحديد ما إذا كان يجب استخدام single column
  bool get shouldUseSingleColumn => screenWidth < ResponsiveBreakpoints.mobile;

  /// الحصول على constraints للـ input fields
  BoxConstraints get inputConstraints {
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
