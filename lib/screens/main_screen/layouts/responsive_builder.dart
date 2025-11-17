import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/responsive_breakpoints.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';

class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
    required this.onPageChanged,
    required this.pageController,
    this.pendingScannedBarcode,
    this.initializationFuture,
  });

  final int currentIndex;
  final void Function(int) onTabTapped;
  final void Function(int) onPageChanged;
  final PageController pageController;
  final String? pendingScannedBarcode;
  final Future<void>? initializationFuture;

  @override
  Widget build(BuildContext context) {
    // إضافة debug logging لتتبع تغيير حجم الشاشة
    debugPrint(
        '🔄 ResponsiveLayoutBuilder - Screen width: ${context.screenWidth}');
    debugPrint(
        '🔄 ResponsiveLayoutBuilder - isSmallScreen: ${context.isSmallScreen}');
    debugPrint('🔄 ResponsiveLayoutBuilder - Current index: $currentIndex');

    return context.isSmallScreen
        ? MobileLayout(
            currentIndex: currentIndex,
            onTabTapped: onTabTapped,
            onPageChanged: onPageChanged,
            pageController: pageController,
            pendingScannedBarcode: pendingScannedBarcode,
            initializationFuture: initializationFuture,
          )
        : DesktopLayout(
            currentIndex: currentIndex,
            onTabTapped: onTabTapped,
            onPageChanged: onPageChanged,
            pageController: pageController,
            pendingScannedBarcode: pendingScannedBarcode,
            initializationFuture: initializationFuture,
          );
  }
}
