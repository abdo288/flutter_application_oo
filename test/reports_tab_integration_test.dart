import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/reports_system/screens/analytics_screen.dart';
import 'package:profit_calculator/reports_system/screens/dashboard_screen_fixed.dart';
import 'package:profit_calculator/reports_system/screens/eod_reports_screen.dart';
import 'package:profit_calculator/reports_system/screens/main_reports_screen.dart';
import 'package:profit_calculator/reports_system/screens/sales_screen_fixed.dart';

/// اختبار التكامل الشامل لتبويب التقارير
/// يختبر جميع التبويبات الفرعية مع مختلف أحجام الشاشات
void main() {
  group('Reports Tab Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// اختبار التكامل بين جميع التبويبات الفرعية
    testWidgets('Sub-tabs Integration Test - Mobile',
        (WidgetTester tester) async {
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

      // اختبار لوحة التحكم
      expect(find.byType(DashboardScreenFixed), findsOneWidget);

      // الانتقال إلى تقارير EOD
      await tester.tap(find.text('تقارير EOD'));
      await tester.pumpAndSettle();

      // التأكد من تحميل التبويب الصحيح
      expect(find.byType(EODReportsScreen), findsOneWidget);

      // الانتقال إلى التحليلات
      await tester.tap(find.text('التحليلات'));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsScreen), findsOneWidget);

      // الانتقال إلى المبيعات
      await tester.tap(find.text('المبيعات'));
      await tester.pumpAndSettle();

      expect(find.byType(SalesScreenFixed), findsOneWidget);
    });

    /// اختبار التكامل مع الشاشات الكبيرة
    testWidgets('Sub-tabs Integration Test - Desktop',
        (WidgetTester tester) async {
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

      // اختبار أن جميع التبويبات تعمل
      final List<String> tabNames = <String>[
        'لوحة التحكم',
        'تقارير EOD',
        'التحليلات',
        'المبيعات'
      ];

      for (final String tabName in tabNames) {
        await tester.tap(find.text(tabName));
        await tester.pumpAndSettle();

        // التأكد من تحميل التبويب
        expect(find.byType(MainReportsScreen), findsOneWidget);
      }
    });

    /// اختبار التفاعل مع الأزرار
    testWidgets('Button Interactions Test', (WidgetTester tester) async {
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

      // اختبار زر التحديث
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // اختبار زر الإعدادات
      expect(find.byIcon(Icons.settings), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // اختبار زر إنهاء اليوم
      expect(find.byIcon(Icons.event), findsOneWidget);
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();
    });

    /// اختبار التخطيط المتجاوب
    testWidgets('Responsive Layout Integration Test',
        (WidgetTester tester) async {
      final List<Size> testSizes = <Size>[
        const Size(320, 568),
        const Size(360, 800),
        const Size(414, 896),
        const Size(768, 1024),
        const Size(1920, 1080),
      ];

      for (final Size screenSize in testSizes) {
        await tester.binding.setSurfaceSize(screenSize);

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

        // التأكد من وجود جميع العناصر
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // اختبار التنقل
        await tester.tap(find.text('التحليلات'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('لوحة التحكم'));
        await tester.pumpAndSettle();

        print(
            '✅ Layout works correctly at ${screenSize.width}x${screenSize.height}');
      }
    });

    /// اختبار الحالات الخاصة
    testWidgets('Edge Cases Test', (WidgetTester tester) async {
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

      // اختبار النقر المتكرر على نفس التبويب
      await tester.tap(find.text('لوحة التحكم'));
      await tester.pump();
      await tester.tap(find.text('لوحة التحكم'));
      await tester.pump();
      await tester.tap(find.text('لوحة التحكم'));
      await tester.pumpAndSettle();

      // التأكد من عدم حدوث أخطاء
      expect(find.byType(MainReportsScreen), findsOneWidget);

      // اختبار النقر السريع على أزرار مختلفة
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.tap(find.text('تقارير EOD'));
      await tester.tap(find.text('التحليلات'));
      await tester.tap(find.text('المبيعات'));
      await tester.pumpAndSettle();

      // التأكد من أن الشاشة لا تزال تعمل
      expect(find.byType(MainReportsScreen), findsOneWidget);
    });

    /// اختبار التكامل الكامل مع جميع أحجام الشاشات
    testWidgets('Complete Integration Test - All Sizes',
        (WidgetTester tester) async {
      final List<Map<String, dynamic>> testConfigs = <Map<String, dynamic>>[
        <String, dynamic>{'size': const Size(320, 568), 'name': 'Small Phone'},
        <String, dynamic>{'size': const Size(375, 667), 'name': 'iPhone 8'},
        <String, dynamic>{'size': const Size(414, 896), 'name': 'iPhone 11 Pro'},
        <String, dynamic>{'size': const Size(768, 1024), 'name': 'iPad Portrait'},
        <String, dynamic>{'size': const Size(1024, 768), 'name': 'iPad Landscape'},
        <String, dynamic>{'size': const Size(1920, 1080), 'name': 'Desktop Full HD'},
        <String, dynamic>{'size': const Size(2560, 1440), 'name': 'Desktop 2K'},
      ];

      for (final Map<String, dynamic> config in testConfigs) {
        final Size size = config['size'] as Size;
        final String name = config['name'] as String;

        await tester.binding.setSurfaceSize(size);

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

        // التحقق من العناصر الأساسية
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);

        // اختبار التبويبات
        final List<String> tabNames = <String>[
          'لوحة التحكم',
          'تقارير EOD',
          'التحليلات',
          'المبيعات'
        ];

        for (final String tabName in tabNames) {
          await tester.tap(find.text(tabName));
          await tester.pumpAndSettle();
        }

        print('✅ $name (${size.width}x${size.height}) - All tests passed');
      }
    });
  });
}

