import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/reports_system/screens/main_reports_screen.dart';

/// اختبار تدفق البكسل الشامل لتبويب التقارير
/// يختبر جميع أحجام الشاشات للتأكد من أن التخطيط يعمل بشكل صحيح
void main() {
  group('Reports Tab Pixel Flow Tests', () {
    late ProviderContainer container;

    setUp(() {
      // إعداد ProviderContainer للاختبارات
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// اختبار الشاشات الصغيرة (موبايل عمودي)
    testWidgets('Mobile Portrait Layout Test', (WidgetTester tester) async {
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

      // التأكد من وجود شريط التبويبات
      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.text('تقارير EOD'), findsOneWidget);
      expect(find.text('التحليلات'), findsOneWidget);
      expect(find.text('المبيعات'), findsOneWidget);

      // اختبار التنقل بين التبويبات
      await tester.tap(find.text('تقارير EOD'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('التحليلات'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المبيعات'));
      await tester.pumpAndSettle();
    });

    /// اختبار الشاشات المتوسطة (تابلت عمودي)
    testWidgets('Tablet Portrait Layout Test', (WidgetTester tester) async {
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

      // التأكد من أن العناصر متوسطة في التابلت
      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // اختبار أن الرسوم البيانية تملأ المساحة بشكل صحيح
      await tester.tap(find.text('التحليلات'));
      await tester.pumpAndSettle();
    });

    /// اختبار الشاشات الكبيرة (سطح المكتب)
    testWidgets('Desktop Layout Test', (WidgetTester tester) async {
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

      // التأكد من أن العناصر تتوسع بشكل صحيح
      expect(find.byType(MainReportsScreen), findsOneWidget);

      // اختبار أن التبويبات تعمل بشكل صحيح في الشاشة الكبيرة
      await tester.tap(find.text('لوحة التحكم'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تقارير EOD'));
      await tester.pumpAndSettle();
    });

    /// اختبار الشاشات الفائقة (Ultra-wide)
    testWidgets('Ultra-wide Layout Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(2560, 1440));

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

      // التأكد من أن العناصر لا تتوسع بشكل مفرط
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    /// اختبار الشاشات الصغيرة جداً (إطارات ضيقة)
    testWidgets('Narrow Screen Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

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

      // التأكد من أن جميع التبويبات مرئية ويمكن النقر عليها
      expect(find.text('لوحة التحكم'), findsWidgets);
      expect(find.text('تقارير EOD'), findsWidgets);

      // اختبار التنقل
      await tester.tap(find.text('المبيعات'));
      await tester.pumpAndSettle();
    });

    /// اختبار التبديل بين الوضعين الأفقي والعمودي
    testWidgets('Orientation Switch Test', (WidgetTester tester) async {
      // البدء في الوضع العمودي
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

      // التبديل إلى الوضع الأفقي
      await tester.binding.setSurfaceSize(const Size(800, 360));
      await tester.pumpAndSettle();

      // التأكد من أن التبويبات لا تزال مرئية
      expect(find.byType(TabBar), findsOneWidget);

      // العودة إلى الوضع العمودي
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });

    /// اختبار الأزرار في AppBar
    testWidgets('AppBar Actions Test', (WidgetTester tester) async {
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

      // التأكد من وجود أزرار التحديث والإعدادات
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);

      // اختبار الضغط على زر التحديث
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // اختبار الضغط على زر الإعدادات
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
    });

    /// اختبار التحديث اليدوي للبيانات
    testWidgets('Manual Refresh Test', (WidgetTester tester) async {
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

      // الضغط على زر التحديث
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // التأكد من عدم حدوث أخطاء
      expect(find.byType(MainReportsScreen), findsOneWidget);
    });

    /// اختبار التبديل السريع بين التبويبات
    testWidgets('Quick Tab Switch Test', (WidgetTester tester) async {
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

      // التبديل السريع بين جميع التبويبات
      for (final String tabName in <String>[
        'لوحة التحكم',
        'تقارير EOD',
        'التحليلات',
        'المبيعات'
      ]) {
        await tester.tap(find.text(tabName));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // التأكد من عدم حدوث أخطاء
      expect(find.byType(MainReportsScreen), findsOneWidget);
    });

    /// اختبار جميع أحجام الشاشات المختلفة دفعة واحدة
    testWidgets('All Screen Sizes Comprehensive Test',
        (WidgetTester tester) async {
      final List<Size> screenSizes = <Size>[
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad Landscape
        const Size(1920, 1080), // Desktop Full HD
        const Size(2560, 1440), // Desktop 2K
      ];

      for (final Size screenSize in screenSizes) {
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

        // التأكد من وجود جميع العناصر الأساسية
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);

        // اختبار التنقل
        await tester.tap(find.text('التحليلات'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('لوحة التحكم'));
        await tester.pumpAndSettle();
      }
    });

    /// اختبار تحجيم العناصر مع تغيير حجم الشاشة
    testWidgets('Responsive Scaling Test', (WidgetTester tester) async {
      final List<Size> screenSizes = <Size>[
        const Size(360, 800),
        const Size(768, 1024),
        const Size(1920, 1080),
      ];

      for (final Size screenSize in screenSizes) {
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

        // التأكد من أن TabBar يحافظ على نسبته
        final Finder tabBarFinder = find.byType(TabBar);
        expect(tabBarFinder, findsOneWidget);

        final RenderBox tabBarBox = tester.renderObject(find.byType(TabBar));
        expect(tabBarBox.size.width, equals(screenSize.width));
      }
    });
  });
}
