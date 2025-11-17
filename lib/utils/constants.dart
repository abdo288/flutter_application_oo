import 'package:flutter/material.dart';

/// ثوابت التطبيق
class AppConstants {
  // ========== Modern Color Palette ==========

  // Primary Colors - Vibrant Blue
  static const Color primaryColor = Color(0xFF2196F3); // Modern vibrant blue
  static const Color primaryLightColor = Color(0xFF64B5F6); // Light blue
  static const Color primaryDarkColor = Color(0xFF1976D2); // Dark blue
  static const Color primaryExtraLight = Color(0xFFBBDEFB); // Extra light blue

  // Secondary Colors - Energetic Purple
  static const Color secondaryColor = Color(0xFF9C27B0); // Purple
  static const Color secondaryLightColor = Color(0xFFBA68C8); // Light purple
  static const Color secondaryDarkColor = Color(0xFF7B1FA2); // Dark purple

  // Accent Colors - Fresh Green
  static const Color accentColor = Color(0xFF4CAF50); // Green
  static const Color accentLightColor = Color(0xFF81C784); // Light green
  static const Color accentDarkColor = Color(0xFF388E3C); // Dark green

  // Semantic Colors
  static const Color errorColor = Color(0xFFEF5350); // Vibrant red
  static const Color errorLightColor = Color(0xFFE57373); // Light red
  static const Color errorDarkColor = Color(0xFFC62828); // Dark red

  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color warningLightColor = Color(0xFFFFB74D); // Light orange
  static const Color warningDarkColor = Color(0xFFF57C00); // Dark orange

  static const Color successColor = Color(0xFF66BB6A); // Success green
  static const Color successLightColor = Color(0xFF81C784); // Light success
  static const Color successDarkColor = Color(0xFF388E3C); // Dark success

  static const Color infoColor = Color(0xFF29B6F6); // Info blue
  static const Color infoLightColor = Color(0xFF4FC3F7); // Light info
  static const Color infoDarkColor = Color(0xFF0288D1); // Dark info

  // Text Colors
  static const Color textColor = Color(0xFF212121); // Primary text
  static const Color textSecondaryColor = Color(0xFF757575); // Secondary text
  static const Color textDisabledColor = Color(0xFFBDBDBD); // Disabled text
  static const Color lightTextColor = Color(0xFF9E9E9E); // Light text

  // Background Colors
  static const Color backgroundColor = Color(0xFFFAFAFA); // App background
  static const Color surfaceColor =
      Color(0xFFFFFFFF); // Surface/Card background
  static const Color cardColor = Color(0xFFFFFFFF); // Card background
  static const Color dividerColor = Color(0xFFE0E0E0); // Divider

  // Shadow & Overlay Colors
  static const Color shadowColor = Color(0x1F000000); // Subtle shadow
  static const Color shadowDarkColor = Color(0x33000000); // Dark shadow
  static const Color overlayColor = Color(0x66000000); // Overlay/backdrop

  // Gradient Colors
  static const List<Color> primaryGradient = <Color>[
    Color(0xFF2196F3),
    Color(0xFF1976D2),
  ];

  static const List<Color> secondaryGradient = <Color>[
    Color(0xFF9C27B0),
    Color(0xFF7B1FA2),
  ];

  static const List<Color> successGradient = <Color>[
    Color(0xFF66BB6A),
    Color(0xFF388E3C),
  ];

  // Glassmorphism Colors
  static const Color glassBackground = Color(0xCCFFFFFF); // Frosted glass light
  static const Color glassDarkBackground =
      Color(0xCC212121); // Frosted glass dark

  // Interactive State Colors
  static const Color hoverColor = Color(0x0A000000); // Hover state
  static const Color pressedColor = Color(0x1F000000); // Pressed state
  static const Color focusColor = Color(0x1F2196F3); // Focus state
  static const Color disabledColor = Color(0x61000000); // Disabled state

  // ========== Spacing System (8px base) ==========

  // Padding & Margins
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Legacy spacing (for backward compatibility)
  static const double smallPadding = spacing8;
  static const double mediumPadding = spacing12;
  static const double defaultPadding = spacing16;
  static const double largePadding = spacing24;
  static const double extraLargePadding = spacing32;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusExtraLarge = 24.0;
  static const double borderRadiusCircular = 999.0;
  static const double largeBorderRadius = 30.0; // Legacy

  // Elevation Levels
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;

  // أحجام الشاشات المتجاوبة
  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  static const double largeDesktopBreakpoint = 1440.0;

  // ========== Typography System ==========

  // Font Sizes
  static const double fontSizeCaption = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeTitleLarge = 24.0;
  static const double fontSizeHeadline = 28.0;
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeDisplayLarge = 36.0;

  // Legacy font sizes (for backward compatibility)
  static const double smallFontSize = fontSizeCaption;
  static const double mediumFontSize = fontSizeBody;
  static const double largeFontSize = fontSizeBodyLarge;
  static const double xlargeFontSize = fontSizeSubtitle;
  static const double xxlargeFontSize = fontSizeTitle;
  static const double titleFontSize = fontSizeTitleLarge;
  static const double headingFontSize = fontSizeHeadline;

  // Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Letter Spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingExtraWide = 1.0;

  // Line Height Multipliers
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  static const double lineHeightLoose = 2.0;

  // ========== Component Sizes ==========

  // Button Heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  static const double buttonHeightExtraLarge = 60.0;

  // Legacy button sizes
  static const double smallButtonHeight = buttonHeightSmall;
  static const double mediumButtonHeight = buttonHeightMedium;
  static const double largeButtonHeight = buttonHeightLarge;
  static const double xlargeButtonHeight = buttonHeightExtraLarge;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeExtraLarge = 32.0;
  static const double iconSizeXXLarge = 40.0;
  static const double iconSizeHuge = 48.0;

  // Legacy icon sizes
  static const double smallIconSize = iconSizeSmall;
  static const double mediumIconSize = iconSizeMedium;
  static const double largeIconSize = iconSizeLarge;
  static const double xlargeIconSize = iconSizeExtraLarge;
  static const double xxlargeIconSize = iconSizeXXLarge;

  // Touch Targets (Minimum 48x48 for accessibility)
  static const double minTouchTarget = 48.0;
  static const double touchTargetPadding = 8.0;

  // Card Padding
  static const double cardPaddingSmall = spacing8;
  static const double cardPaddingMedium = spacing12;
  static const double cardPaddingLarge = spacing16;
  static const double cardPaddingExtraLarge = spacing24;

  // Legacy card padding
  static const double smallCardPadding = cardPaddingSmall;
  static const double mediumCardPadding = cardPaddingMedium;
  static const double largeCardPadding = cardPaddingLarge;
  static const double xlargeCardPadding = cardPaddingExtraLarge;

  // ========== Responsive Grid ==========

  // Grid Columns
  static const int gridColumnsMobile = 1;
  static const int gridColumnsTablet = 2;
  static const int gridColumnsDesktop = 3;
  static const int gridColumnsLargeDesktop = 4;

  // Legacy grid columns
  static const int mobileGridColumns = gridColumnsMobile;
  static const int tabletGridColumns = gridColumnsTablet;
  static const int desktopGridColumns = gridColumnsDesktop;
  static const int largeDesktopGridColumns = gridColumnsLargeDesktop;

  // Container Max Widths
  static const double maxWidthMobile = 480.0;
  static const double maxWidthTablet = 768.0;
  static const double maxWidthDesktop = 1024.0;
  static const double maxWidthLargeDesktop = 1440.0;
  static const double maxWidthContent = 1200.0; // Standard content max width

  // Legacy max widths
  static const double mobileMaxWidth = maxWidthMobile;
  static const double tabletMaxWidth = maxWidthTablet;
  static const double desktopMaxWidth = maxWidthDesktop;
  static const double largeDesktopMaxWidth = maxWidthLargeDesktop;

  // ========== Animation Durations ==========

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // Specific animations
  static const Duration rippleDuration = Duration(milliseconds: 200);
  static const Duration dialogDuration = Duration(milliseconds: 300);
  static const Duration pageDuration = Duration(milliseconds: 350);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // ========== Curves ==========

  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveSharp = Curves.linear;
  static const Curve curveEmphasized = Curves.easeInOutCubic;

  // النصوص
  static const String appTitle = 'حاسبة الأرباح';
  static const String dashboard = 'لوحة التحكم';
  static const String addProduct = 'البيع السريع';
  static const String productList = 'سجل المبيعات';
  static const String inventory = 'المخزون';
  static const String productForm = 'نموذج المنتج';
  static const String storeDisplay = 'المخزون';

  // رسائل الأخطاء
  static const String errorGeneral = 'حدث خطأ غير متوقع';
  static const String errorNetwork = 'خطأ في الاتصال بالإنترنت';
  static const String errorValidation = 'البيانات المدخلة غير صحيحة';
  static const String errorNotFound = 'لم يتم العثور على البيانات المطلوبة';

  // رسائل النجاح
  static const String successAdd = 'تم الإضافة بنجاح';
  static const String successUpdate = 'تم التحديث بنجاح';
  static const String successDelete = 'تم الحذف بنجاح';

  // رسائل التحذير
  static const String warningEmptyFields = 'يرجى ملء جميع الحقول المطلوبة';
  static const String warningOutOfStock = 'نفذت الكمية';
  static const String warningDuplicateName = 'اسم المنتج موجود بالفعل';

  // حدود البيانات
  static const int maxProductNameLength = 50;
  static const int minProductNameLength = 2;
  static const int maxPrice = 1000000;
  static const int maxQuantity = 10000;
  static const int minPrice = 0;
  static const int minQuantity = 0;

  // تنسيقات التاريخ والوقت
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // إعدادات Firebase
  static const int cacheSizeBytes = 104857600; // 100MB
  static const bool persistenceEnabled = true;
}
