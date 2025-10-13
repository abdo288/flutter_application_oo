import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/models/product.dart';
import 'package:profit_calculator/widgets/product_card.dart';

void main() {
  group('ProductCard Widget Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = Product(
        id: 'test-id',
        name: 'Test Product',
        wholesalePrice: 100,
        retailPrice: 150,
        savedAt: DateTime.now(),
      );
    });

    testWidgets('should display product information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('50'), findsOneWidget); // Profit
      expect(find.text('50.0%'), findsOneWidget); // Profit percentage
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool onTapCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () {
                onTapCalled = true;
              },
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ProductCard));
      await tester.pump();

      // Assert
      expect(onTapCalled, true);
    });

    testWidgets('should call onEdit when edit button is tapped', (WidgetTester tester) async {
      // Arrange
      bool onEditCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () {},
              onEdit: () {
                onEditCalled = true;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Assert
      expect(onEditCalled, true);
    });

    testWidgets('should call onDelete when delete button is tapped', (WidgetTester tester) async {
      // Arrange
      bool onDeleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () {},
              onEdit: () {},
              onDelete: () {
                onDeleteCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Assert
      expect(onDeleteCalled, true);
    });

    testWidgets('should display correct profit calculation', (WidgetTester tester) async {
      // Arrange
      final Product productWithDifferentPrices = Product(
        id: 'test-id',
        name: 'Test Product',
        wholesalePrice: 80,
        retailPrice: 120,
        savedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: productWithDifferentPrices,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('40'), findsOneWidget); // Profit: 120 - 80 = 40
      expect(find.text('50.0%'), findsOneWidget); // Profit percentage: (40/80) * 100 = 50%
    });

    testWidgets('should handle zero profit correctly', (WidgetTester tester) async {
      // Arrange
      final Product productWithNoProfit = Product(
        id: 'test-id',
        name: 'Test Product',
        wholesalePrice: 100,
        retailPrice: 100,
        savedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: productWithNoProfit,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsOneWidget); // Profit: 100 - 100 = 0
      expect(find.text('0.0%'), findsOneWidget); // Profit percentage: 0%
    });

    testWidgets('should display long product names correctly', (WidgetTester tester) async {
      // Arrange
      final Product productWithLongName = Product(
        id: 'test-id',
        name: 'This is a very long product name that should be handled properly',
        wholesalePrice: 100,
        retailPrice: 150,
        savedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: productWithLongName,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('This is a very long product name that should be handled properly'), findsOneWidget);
    });
  });
}


