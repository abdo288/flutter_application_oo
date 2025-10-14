import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class AppTheme {
  // إعدادات النسق المشتركة
  static const Duration _animationDuration = Duration(milliseconds: 300);

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      primary: AppConstants.primaryColor,
      primaryContainer: AppConstants.primaryLightColor,
      secondary: AppConstants.secondaryColor,
      secondaryContainer: AppConstants.secondaryLightColor,
      error: AppConstants.errorColor,
      surface: AppConstants.surfaceColor,
      background: AppConstants.backgroundColor,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
      platform: TargetPlatform.android,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Enhanced animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.cardColor,
        labelStyle: const TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide:
              const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: AppConstants.elevation2,
          shadowColor: AppConstants.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
            vertical: AppConstants.spacing16,
          ),
          minimumSize: const Size(0, AppConstants.buttonHeightMedium),
          textStyle: const TextStyle(
            fontWeight: AppConstants.fontWeightSemiBold,
            fontSize: AppConstants.fontSizeBodyLarge,
            letterSpacing: AppConstants.letterSpacingWide,
          ),
          animationDuration: AppConstants.animationNormal,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.1),
          ),
          elevation: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return AppConstants.elevation6;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppConstants.elevation4;
            }
            return AppConstants.elevation2;
          }),
        ),
      ),

      // تحسينات أزرار إضافية
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          animationDuration: _animationDuration,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          animationDuration: _animationDuration,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0, // إزالة الارتفاع الافتراضي
        shadowColor: AppConstants.shadowColor,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: AppConstants.elevation2,
        shadowColor: AppConstants.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing12,
          vertical: AppConstants.spacing8,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.textColor,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.lightTextColor,
        selectedIconTheme:
            IconThemeData(color: AppConstants.primaryColor, size: 26),
        unselectedIconTheme:
            IconThemeData(color: AppConstants.lightTextColor, size: 24),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.lightTextColor,
        indicatorColor: AppConstants.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // Enhanced FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: AppConstants.elevation6,
        focusElevation: AppConstants.elevation8,
        hoverElevation: AppConstants.elevation8,
        highlightElevation: AppConstants.elevation12,
        splashColor: Colors.white24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
        iconSize: AppConstants.iconSizeLarge,
      ),

      // تحسينات Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.backgroundColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        disabledColor: Colors.grey.shade300,
        labelStyle: const TextStyle(
          color: AppConstants.textColor,
          fontWeight: FontWeight.w500,
        ),
        // selectedLabelStyle تم إزالتها في أحدث إصدار
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        elevation: 1,
        pressElevation: 3,
      ),

      // تحسينات Switch و Checkbox
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.shade300;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // تحسينات ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primaryColor,
        linearTrackColor: AppConstants.backgroundColor,
        circularTrackColor: AppConstants.backgroundColor,
      ),

      textTheme: _localizedGoogleTextTheme(base.textTheme, Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    const Color background = Color(0xFF121416);
    const Color surface = Color(0xFF1A1D20);
    const Color onSurface = Color(0xFFE3E6EA);

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
      surface: surface,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
      platform: TargetPlatform.android,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF171A1D),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF23272B),
        labelStyle: TextStyle(
          color: AppConstants.primaryLightColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide:
              const BorderSide(color: AppConstants.primaryLightColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          animationDuration: _animationDuration,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF171A1D),
        selectedItemColor: AppConstants.primaryLightColor,
        unselectedItemColor: Colors.white70,
        selectedIconTheme:
            IconThemeData(color: AppConstants.primaryLightColor, size: 26),
        unselectedIconTheme: IconThemeData(color: Colors.white70, size: 24),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white10,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF23272B),
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        disabledColor: Colors.white12,
        labelStyle:
            const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        elevation: 0,
        pressElevation: 1,
      ),
      textTheme:
          _localizedGoogleTextTheme(base.textTheme, Brightness.dark).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
    );
  }

  // يطبق GoogleFonts Cairo عالميًا (يدعم العربية) ويمكن تبديله لاحقًا حسب اللغة من خلال MaterialApp locale
  static TextTheme _localizedGoogleTextTheme(
      TextTheme base, Brightness brightness) {
    final TextTheme cairoBase = GoogleFonts.cairoTextTheme(base);
    return cairoBase.copyWith(
      titleLarge: cairoBase.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
      titleMedium: cairoBase.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      bodyLarge: cairoBase.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: cairoBase.bodyMedium?.copyWith(fontSize: 14, height: 1.3),
      bodySmall: cairoBase.bodySmall?.copyWith(fontSize: 12, height: 1.2),
    );
  }

  // خط محلي حسب اللغة: عربي Cairo، غير ذلك Poppins
  static TextTheme localizedTextThemeFor(TextTheme base, Locale? locale,
      {String fontKey = 'auto'}) {
    // fontKey priority: explicit key > locale auto-detect
    TextTheme themed;
    switch (fontKey) {
      case 'cairo':
        themed = GoogleFonts.cairoTextTheme(base);
        break;
      case 'tajawal':
        themed = GoogleFonts.tajawalTextTheme(base);
        break;
      case 'poppins':
        themed = GoogleFonts.poppinsTextTheme(base);
        break;
      case 'lato':
        themed = GoogleFonts.latoTextTheme(base);
        break;
      case 'auto':
      default:
        final bool isArabic =
            (locale?.languageCode.toLowerCase() ?? 'ar') == 'ar';
        themed = isArabic
            ? GoogleFonts.cairoTextTheme(base)
            : GoogleFonts.poppinsTextTheme(base);
        break;
    }
    return themed.copyWith(
      titleLarge: themed.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
      titleMedium: themed.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      bodyLarge: themed.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: themed.bodyMedium?.copyWith(fontSize: 14, height: 1.3),
      bodySmall: themed.bodySmall?.copyWith(fontSize: 12, height: 1.2),
    );
  }
}
