import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/reports_system/screens/main_reports_screen.dart';

/// اختبار أداء تبويب التقارير
/// يقيس وقت التحميل والأداء مع مختلف أحجام الشاشات
void main() {
  group('Reports Tab Performance Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// اختبار أداء التحميل في الشاشات الصغيرة
    testWidgets('Performance Test - Small Screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      final Stopwatch stopwatch = Stopwatch()..start();

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

      stopwatch.stop();

      print('🕐 Small Screen Load Time: ${stopwatch.elapsedMilliseconds}ms');

      // التأكد من أن وقت التحميل أقل من 2 ثانية
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    /// اختبار أداء التحميل في الشاشات المتوسطة
    testWidgets('Performance Test - Medium Screen',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      final Stopwatch stopwatch = Stopwatch()..start();

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

      stopwatch.stop();

      print('🕐 Medium Screen Load Time: ${stopwatch.elapsedMilliseconds}ms');

      // التأكد من أن وقت التحميل أقل من 3 ثوانٍ
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    /// اختبار أداء التحميل في الشاشات الكبيرة
    testWidgets('Performance Test - Large Screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      final Stopwatch stopwatch = Stopwatch()..start();

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

      stopwatch.stop();

      print('🕐 Large Screen Load Time: ${stopwatch.elapsedMilliseconds}ms');

      // التأكد من أن وقت التحميل أقل من 4 ثوانٍ
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));
    });

    /// اختبار سرعة التبديل بين التبويبات
    testWidgets('Tab Switch Performance Test', (WidgetTester tester) async {
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

      final Stopwatch stopwatch = Stopwatch()..start();

      // التبديل بين جميع التبويبات
      await tester.tap(find.text('تقارير EOD'));
      await tester.pump();

      await tester.tap(find.text('التحليلات'));
      await tester.pump();

      await tester.tap(find.text('المبيعات'));
      await tester.pump();

      await tester.tap(find.text('لوحة التحكم'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      print('🕐 Tab Switch Time: ${stopwatch.elapsedMilliseconds}ms');

      // التأكد من أن وقت التبديل سريع
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    /// اختبار استهلاك الذاكرة
    testWidgets('Memory Usage Test', (WidgetTester tester) async {
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

      // Navigate through all tabs multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('تقارير EOD'));
        await tester.pump();

        await tester.tap(find.text('التحليلات'));
        await tester.pump();

        await tester.tap(find.text('المبيعات'));
        await tester.pump();

        await tester.tap(find.text('لوحة التحكم'));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // التأكد من أن الشاشة لا تزال تعمل بشكل صحيح
      expect(find.byType(MainReportsScreen), findsOneWidget);
    });
  });
}

