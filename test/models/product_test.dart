import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/models/product.dart';
import 'package:profit_calculator/services/data_conversion_service.dart';

void main() {
  group('Product Model Tests', () {
    test('Product should be created with valid data', () {
      // Arrange
      final Product product = Product(
        name: 'Test Product',
        wholesalePrice: 50,
        retailPrice: 75,
        savedAt: DateTime.now(),
      );

      // Assert
      expect(product.name, 'Test Product');
      expect(product.wholesalePrice, 50);
      expect(product.retailPrice, 75);
      expect(product.isValid(), true);
    });

    test('Product should calculate profit correctly', () {
      // Arrange
      final Product product = Product(
        name: 'Test Product',
        wholesalePrice: 40,
        retailPrice: 60,
        savedAt: DateTime.now(),
      );

      // Act
      final int profit = product.calculateProfit();

      // Assert
      expect(profit, 20);
    });

    test('Product should calculate profit percentage correctly', () {
      // Arrange
      final Product product = Product(
        name: 'Test Product',
        wholesalePrice: 100,
        retailPrice: 150,
        savedAt: DateTime.now(),
      );

      // Act
      final double profitPercentage = product.calculateProfitPercentage();

      // Assert
      expect(profitPercentage, 50.0);
    });

    test('Product validation should work correctly', () {
      // Test valid product
      final Product validProduct = Product(
        name: 'Valid Product',
        wholesalePrice: 10,
        retailPrice: 15,
        savedAt: DateTime.now(),
      );
      expect(validProduct.isValid(), true);

      // Test invalid product with empty name
      final Product invalidNameProduct = Product(
        name: '',
        wholesalePrice: 10,
        retailPrice: 15,
        savedAt: DateTime.now(),
      );
      expect(invalidNameProduct.isValid(), false);

      // Test invalid product with negative wholesale price
      final Product invalidWholesaleProduct = Product(
        name: 'Test',
        wholesalePrice: -10,
        retailPrice: 15,
        savedAt: DateTime.now(),
      );
      expect(invalidWholesaleProduct.isValid(), false);

      // Test invalid product with negative retail price
      final Product invalidRetailProduct = Product(
        name: 'Test',
        wholesalePrice: 10,
        retailPrice: -15,
        savedAt: DateTime.now(),
      );
      expect(invalidRetailProduct.isValid(), false);
    });

    test('Product toMap should return correct map', () {
      // Arrange
      final DateTime now = DateTime.now();
      final Product product = Product(
        id: 'test-id',
        name: 'Test Product',
        wholesalePrice: 30,
        retailPrice: 45,
        savedAt: now,
      );

      // Act
      final Map<String, dynamic> map = product.toMap();

      // Assert
      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Product');
      expect(map['wholesale_price'], 30);
      expect(map['retail_price'], 45);
      expect(map['saved_at'], isA<String>());
    });

    test('DataConversionService.convertMapToProduct should create correct product', () {
      // Arrange
      final DateTime now = DateTime.now();
      final Map<String, Object> map = <String, Object>{
        'id': 'test-id',
        'name': 'Test Product',
        'wholesalePrice': 30,
        'retailPrice': 45,
        'savedAt': now,
      };

      // Act
      final Product? product = DataConversionService.convertMapToProduct(map);
      expect(product, isNotNull);

      // Assert
      expect(product!.id, 'test-id');
      expect(product.name, 'Test Product');
      expect(product.wholesalePrice, 30);
      expect(product.retailPrice, 45);
    });

    test('Product copyWith should work correctly', () {
      // Arrange
      final Product original = Product(
        id: 'original-id',
        name: 'Original Product',
        wholesalePrice: 30,
        retailPrice: 45,
        savedAt: DateTime.now(),
      );

      // Act
      final Product modified = original.copyWith(
        name: 'Modified Product',
        wholesalePrice: 40,
      );

      // Assert
      expect(modified.id, 'original-id'); // Should remain same
      expect(modified.name, 'Modified Product'); // Should be updated
      expect(modified.wholesalePrice, 40); // Should be updated
      expect(modified.retailPrice, 45); // Should remain same
    });

    test('Product should handle edge cases for profit calculation', () {
      // Test zero wholesale price
      final Product product1 = Product(
        name: 'Test',
        wholesalePrice: 0,
        retailPrice: 10,
        savedAt: DateTime.now(),
      );
      expect(product1.calculateProfitPercentage(), 0.0);

      // Test same wholesale and retail price
      final Product product2 = Product(
        name: 'Test',
        wholesalePrice: 10,
        retailPrice: 10,
        savedAt: DateTime.now(),
      );
      expect(product2.calculateProfit(), 0);
      expect(product2.calculateProfitPercentage(), 0.0);
    });

    test('Product should handle negative price calculation error', () {
      // Arrange
      final Product product = Product(
        name: 'Test',
        wholesalePrice: -5,
        retailPrice: 10,
        savedAt: DateTime.now(),
      );

      // Act & Assert
      expect(product.calculateProfit, throwsArgumentError);
    });
  });
}
