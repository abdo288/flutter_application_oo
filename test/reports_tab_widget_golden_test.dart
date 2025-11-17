import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/reports_system/screens/main_reports_screen.dart';

/// Golden Test - اختبار بصمة الذهب لتبويب التقارير
/// يسجل لقطات شاشة في مختلف الأحجام للتأكد من عدم تغيير التخطيط
void main() {
  group('Reports Tab Golden Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// اختبار بصمة الذهب لموبايل عمودي
    testWidgets('Mobile Portrait Golden Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: MainReportsScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // إنشاء لقطة شاشة للتأكد من التخطيط
      await expectLater(
        find.byType(MainReportsScreen),
        matchesGoldenFile('reports_mobile_portrait.png'),
      );
    });

    /// اختبار بصمة الذهب لموبايل أفقي
    testWidgets('Mobile Landscape Golden Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: MainReportsScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MainReportsScreen),
        matchesGoldenFile('reports_mobile_landscape.png'),
      );
    });

    /// اختبار بصمة الذهب للتابلت
    testWidgets('Tablet Golden Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: MainReportsScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MainReportsScreen),
        matchesGoldenFile('reports_tablet.png'),
      );
    });

    /// اختبار بصمة الذهب لسطح المكتب
    testWidgets('Desktop Golden Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: MainReportsScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MainReportsScreen),
        matchesGoldenFile('reports_desktop.png'),
      );
    });
  });
}

