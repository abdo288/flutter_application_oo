# دليل الاختبارات - تطبيق حاسبة الأرباح

## نظرة عامة

يحتوي هذا المجلد على جميع اختبارات التطبيق، بما في ذلك اختبارات الوحدات واختبارات الواجهات واختبارات التكامل.

## هيكل الاختبارات

```
test/
├── models/                    # اختبارات النماذج
│   └── product_test.dart
├── services/                  # اختبارات الخدمات
│   ├── cache_service_test.dart
│   ├── firestore_service_test.dart
│   └── security_service_test.dart
├── widgets/                   # اختبارات المكونات
│   └── product_card_test.dart
├── test_setup.dart           # إعداد الاختبارات
├── test_config.dart          # تكوين الاختبارات
└── README.md                 # هذا الملف

integration_test/             # اختبارات التكامل
└── app_test.dart
```

## أنواع الاختبارات

### 1. اختبارات الوحدات (Unit Tests)

تختبر الوحدات الفردية من الكود بشكل منفصل:

- **اختبارات النماذج**: تختبر منطق النماذج وحساباتها
- **اختبارات الخدمات**: تختبر منطق الخدمات والتفاعل مع Firebase

#### تشغيل اختبارات الوحدات:
```bash
flutter test
```

### 2. اختبارات الواجهات (Widget Tests)

تختبر مكونات الواجهة بشكل منفصل:

- **اختبارات المكونات**: تختبر سلوك المكونات والتفاعل مع المستخدم

#### تشغيل اختبارات الواجهات:
```bash
flutter test test/widgets/
```

### 3. اختبارات التكامل (Integration Tests)

تختبر التطبيق ككل من نهاية إلى نهاية:

- **اختبارات التدفق**: تختبر تدفق المستخدم الكامل
- **اختبارات الوظائف**: تختبر الوظائف الرئيسية للتطبيق

#### تشغيل اختبارات التكامل:
```bash
flutter test integration_test/
```

## إعداد الاختبارات

### 1. إعداد Firebase للاختبارات

يتم إعداد Firebase في `test_setup.dart`:

```dart
await TestSetup.initializeFirebase();
```

### 2. تكوين الاختبارات

يتم تكوين الاختبارات في `test_config.dart`:

```dart
TestConfig.setupTestTimeout();
```

## كتابة اختبارات جديدة

### 1. اختبار وحدة جديد

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/models/product.dart';

void main() {
  group('Product Tests', () {
    test('should calculate profit correctly', () {
      // Arrange
      final product = Product(
        name: 'Test',
        wholesalePrice: 100,
        retailPrice: 150,
        savedAt: DateTime.now(),
      );
      
      // Act
      final profit = product.calculateProfit();
      
      // Assert
      expect(profit, 50);
    });
  });
}
```

### 2. اختبار واجهة جديد

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/widgets/product_card.dart';

void main() {
  testWidgets('should display product information', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(
          product: testProduct,
          onTap: () {},
        ),
      ),
    );
    
    // Assert
    expect(find.text('Test Product'), findsOneWidget);
  });
}
```

### 3. اختبار تكامل جديد

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:profit_calculator/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('should add product successfully', (WidgetTester tester) async {
    // Arrange
    app.main();
    await tester.pumpAndSettle();
    
    // Act
    await tester.tap(find.text('إضافة منتج'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('إضافة منتج'), findsOneWidget);
  });
}
```

## أفضل الممارسات

### 1. تسمية الاختبارات

- استخدم أسماء وصفية: `should calculate profit correctly`
- استخدم نمط Given-When-Then: `given valid product when calculating profit then should return correct value`

### 2. تنظيم الاختبارات

- استخدم `group()` لتجميع الاختبارات ذات الصلة
- استخدم `setUp()` و `tearDown()` لإعداد وتنظيف البيانات

### 3. معالجة الأخطاء

- اختبر الحالات الاستثنائية
- استخدم `expect()` مع `throwsA()` للتحقق من الأخطاء

### 4. اختبارات غير متصلة

- استخدم `TestConfig.executeWithRetry()` للعمليات التي قد تفشل
- استخدم مهلات زمنية مناسبة

## تشغيل الاختبارات

### تشغيل جميع الاختبارات:
```bash
flutter test
```

### تشغيل اختبارات محددة:
```bash
flutter test test/models/product_test.dart
```

### تشغيل اختبارات مع تغطية:
```bash
flutter test --coverage
```

### تشغيل اختبارات التكامل:
```bash
flutter test integration_test/
```

## استكشاف الأخطاء

### 1. مشاكل Firebase

إذا فشلت اختبارات Firebase:
- تأكد من إعداد `firebase_options.dart`
- استخدم `TestSetup.initializeFirebase()` في `setUpAll()`

### 2. مشاكل التوقيت

إذا فشلت الاختبارات بسبب التوقيت:
- استخدم `await tester.pumpAndSettle()`
- استخدم `TestConfig.waitWithTimeout()`

### 3. مشاكل البيانات

إذا فشلت الاختبارات بسبب البيانات:
- استخدم `setUp()` و `tearDown()` لتنظيف البيانات
- استخدم بيانات اختبار معزولة

## التغطية

لتوليد تقرير تغطية الاختبارات:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## المساهمة

عند إضافة ميزات جديدة:

1. اكتب اختبارات الوحدات أولاً
2. اكتب اختبارات الواجهات للمكونات الجديدة
3. اكتب اختبارات التكامل للتدفقات الجديدة
4. تأكد من أن جميع الاختبارات تمر
5. حافظ على تغطية اختبارات عالية (>80%)


