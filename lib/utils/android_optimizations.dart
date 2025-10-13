import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// تحسينات خاصة بمنصة Android
class AndroidOptimizations {
  // ========== إعدادات الأداء ==========

  /// تحسين الأداء للـ Android
  static void optimizeForAndroid() {
    if (Platform.isAndroid) {
      // تحسين الذاكرة
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  // ========== إعدادات التصميم ==========

  /// الحصول على أحجام محسنة لـ Android
  static AndroidSizes getAndroidSizes(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return AndroidSizes(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      isTablet: screenWidth >= 600,
      isLargeScreen: screenWidth >= 900,
      cardPadding: screenWidth >= 600 ? 16.0 : 12.0,
      cardMargin: screenWidth >= 600 ? 12.0 : 8.0,
      fontSize: screenWidth >= 600 ? 16.0 : 14.0,
      iconSize: screenWidth >= 600 ? 24.0 : 20.0,
      buttonHeight: screenWidth >= 600 ? 48.0 : 44.0,
      borderRadius: screenWidth >= 600 ? 12.0 : 8.0,
    );
  }

  // ========== إعدادات الشبكة ==========

  /// الحصول على إعدادات الشبكة محسنة لـ Android
  static AndroidGridSettings getAndroidGridSettings(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 900) {
      return const AndroidGridSettings(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      );
    } else if (screenWidth >= 600) {
      return const AndroidGridSettings(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
      );
    } else {
      return const AndroidGridSettings(
        crossAxisCount: 1,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      );
    }
  }

  // ========== إعدادات الألوان ==========

  /// الحصول على ألوان محسنة لـ Android
  static AndroidColors getAndroidColors() => AndroidColors(
      primary: const Color(0xFF4A90E2),
      primaryLight: const Color(0xFF7BB3F0),
      primaryDark: const Color(0xFF2E5B8A),
      secondary: const Color(0xFF6BCF7F),
      success: const Color(0xFF27AE60),
      warning: const Color(0xFFF39C12),
      error: const Color(0xFFE74C3C),
      background: const Color(0xFFF8F9FA),
      surface: Colors.white,
      text: const Color(0xFF2C3E50),
      textLight: const Color(0xFF7F8C8D),
      border: const Color(0xFFE0E0E0),
      shadow: const Color(0x1A000000),
    );

  // ========== إعدادات الرسوم المتحركة ==========

  /// الحصول على إعدادات الرسوم المتحركة محسنة لـ Android
  static AndroidAnimationSettings getAndroidAnimationSettings() => AndroidAnimationSettings(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      staggerDelay: const Duration(milliseconds: 50),
      slideOffset: 30.0,
      fadeDuration: const Duration(milliseconds: 200),
    );

  // ========== إعدادات الأداء ==========

  /// تحسين الأداء للقوائم
  static Widget buildOptimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) => ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: const BouncingScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

  /// تحسين الأداء للشبكة
  static Widget buildOptimizedGridView({
    required List<Widget> children,
    required AndroidGridSettings gridSettings,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) => GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSettings.crossAxisCount,
        childAspectRatio: gridSettings.childAspectRatio,
        crossAxisSpacing: gridSettings.crossAxisSpacing,
        mainAxisSpacing: gridSettings.mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

  // ========== إعدادات التصميم المتجاوب ==========

  /// الحصول على تصميم متجاوب لـ Android
  static Widget buildResponsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    required BuildContext context,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 900 && desktop != null) {
      return desktop;
    } else if (screenWidth >= 600 && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

/// إعدادات الأحجام لـ Android
class AndroidSizes {

  const AndroidSizes({
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isLargeScreen,
    required this.cardPadding,
    required this.cardMargin,
    required this.fontSize,
    required this.iconSize,
    required this.buttonHeight,
    required this.borderRadius,
  });
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isLargeScreen;
  final double cardPadding;
  final double cardMargin;
  final double fontSize;
  final double iconSize;
  final double buttonHeight;
  final double borderRadius;
}

/// إعدادات الشبكة لـ Android
class AndroidGridSettings {

  const AndroidGridSettings({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
}

/// إعدادات الألوان لـ Android
class AndroidColors {

  const AndroidColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.background,
    required this.surface,
    required this.text,
    required this.textLight,
    required this.border,
    required this.shadow,
  });
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color background;
  final Color surface;
  final Color text;
  final Color textLight;
  final Color border;
  final Color shadow;
}

/// إعدادات الرسوم المتحركة لـ Android
class AndroidAnimationSettings {

  const AndroidAnimationSettings({
    required this.duration,
    required this.curve,
    required this.staggerDelay,
    required this.slideOffset,
    required this.fadeDuration,
  });
  final Duration duration;
  final Curve curve;
  final Duration staggerDelay;
  final double slideOffset;
  final Duration fadeDuration;
}
