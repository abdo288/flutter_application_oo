import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/models/inventory_item.dart';
import 'package:profit_calculator/models/product.dart';
import 'package:profit_calculator/services/cache_service.dart';

void main() {
  group('CacheService Tests', () {
    late Product testProduct;
    late InventoryItem testInventoryItem;

    setUp(() {
      testProduct = Product(
        id: 'test-product-id',
        name: 'Test Product',
        wholesalePrice: 100,
        retailPrice: 150,
        savedAt: DateTime.now(),
      );

      testInventoryItem = InventoryItem(
        id: 'test-inventory-id',
        name: 'Test Inventory Item',
        wholesalePrice: 50,
        retailPrice: 75,
        quantity: 10,
        originalQuantity: 10,
        addedDate: DateTime.now(),
        addedTime: DateTime.now(),
      );
    });

    tearDown(CacheService.clearAllCache);

    group('Product Caching', () {
      test('should cache product successfully', () {
        // Act
        CacheService.cacheProduct(testProduct);

        // Assert
        final Product? cachedProduct =
            CacheService.getCachedProduct(testProduct.id ?? '');
        expect(cachedProduct, isNotNull);
        expect(cachedProduct!.id, testProduct.id);
        expect(cachedProduct.name, testProduct.name);
        expect(cachedProduct.wholesalePrice, testProduct.wholesalePrice);
        expect(cachedProduct.retailPrice, testProduct.retailPrice);
      });

      test('should return null for non-existent cached product', () {
        // Act
        final Product? cachedProduct =
            CacheService.getCachedProduct('non-existent-id');

        // Assert
        expect(cachedProduct, isNull);
      });

      test('should update cached product', () {
        // Arrange
        CacheService.cacheProduct(testProduct);
        final Product updatedProduct = testProduct.copyWith(
          wholesalePrice: 120,
          retailPrice: 180,
        );

        // Act
        CacheService.cacheProduct(updatedProduct);

        // Assert
        final Product? cachedProduct =
            CacheService.getCachedProduct(testProduct.id ?? '');
        expect(cachedProduct, isNotNull);
        expect(cachedProduct!.wholesalePrice, 120);
        expect(cachedProduct.retailPrice, 180);
      });

      test('should get all cached products', () {
        // Arrange
        final Product product1 = testProduct;
        final Product product2 = Product(
          id: 'test-product-2',
          name: 'Test Product 2',
          wholesalePrice: 200,
          retailPrice: 300,
          savedAt: DateTime.now(),
        );

        CacheService.cacheProduct(product1);
        CacheService.cacheProduct(product2);

        // Act
        final List<Product> cachedProducts =
            CacheService.getAllCachedProducts();

        // Assert
        expect(cachedProducts.length, 2);
        expect(cachedProducts.any((Product p) => p.id == product1.id), true);
        expect(cachedProducts.any((Product p) => p.id == product2.id), true);
      });

      test('should remove cached product', () {
        // Arrange
        CacheService.cacheProduct(testProduct);

        // Act
        CacheService.removeCachedProduct(testProduct.id ?? '');

        // Assert
        final Product? cachedProduct =
            CacheService.getCachedProduct(testProduct.id ?? '');
        expect(cachedProduct, isNull);
      });
    });

    group('Inventory Caching', () {
      test('should cache inventory item successfully', () {
        // Act
        CacheService.cacheInventoryItem(testInventoryItem);

        // Assert
        final InventoryItem? cachedItem =
            CacheService.getCachedInventoryItem(testInventoryItem.id ?? '');
        expect(cachedItem, isNotNull);
        expect(cachedItem!.id, testInventoryItem.id);
        expect(cachedItem.name, testInventoryItem.name);
        expect(cachedItem.wholesalePrice, testInventoryItem.wholesalePrice);
        expect(cachedItem.quantity, testInventoryItem.quantity);
      });

      test('should return null for non-existent cached inventory item', () {
        // Act
        final InventoryItem? cachedItem =
            CacheService.getCachedInventoryItem('non-existent-id');

        // Assert
        expect(cachedItem, isNull);
      });

      test('should update cached inventory item', () {
        // Arrange
        CacheService.cacheInventoryItem(testInventoryItem);
        final InventoryItem updatedItem = InventoryItem(
          id: testInventoryItem.id,
          name: testInventoryItem.name,
          wholesalePrice: testInventoryItem.wholesalePrice,
          retailPrice: testInventoryItem.retailPrice,
          quantity: 15,
          originalQuantity: testInventoryItem.originalQuantity,
          addedDate: testInventoryItem.addedDate,
          addedTime: testInventoryItem.addedTime,
        );

        // Act
        CacheService.cacheInventoryItem(updatedItem);

        // Assert
        final InventoryItem? cachedItem =
            CacheService.getCachedInventoryItem(testInventoryItem.id ?? '');
        expect(cachedItem, isNotNull);
        expect(cachedItem!.quantity, 15);
      });

      test('should get all cached inventory items', () {
        // Arrange
        final InventoryItem item1 = testInventoryItem;
        final InventoryItem item2 = InventoryItem(
          id: 'test-inventory-2',
          name: 'Test Inventory Item 2',
          wholesalePrice: 100,
          retailPrice: 150,
          quantity: 20,
          originalQuantity: 20,
          addedDate: DateTime.now(),
          addedTime: DateTime.now(),
        );

        CacheService.cacheInventoryItem(item1);
        CacheService.cacheInventoryItem(item2);

        // Act
        final List<InventoryItem> cachedItems =
            CacheService.getAllCachedInventoryItems();

        // Assert
        expect(cachedItems.length, 2);
        expect(
            cachedItems.any((InventoryItem item) => item.id == item1.id), true);
        expect(
            cachedItems.any((InventoryItem item) => item.id == item2.id), true);
      });

      test('should remove cached inventory item', () {
        // Arrange
        CacheService.cacheInventoryItem(testInventoryItem);

        // Act
        CacheService.removeCachedInventoryItem(testInventoryItem.id ?? '');

        // Assert
        final InventoryItem? cachedItem =
            CacheService.getCachedInventoryItem(testInventoryItem.id ?? '');
        expect(cachedItem, isNull);
      });
    });

    group('Cache Management', () {
      test('should clear all cache', () {
        // Arrange
        CacheService.cacheProduct(testProduct);
        CacheService.cacheInventoryItem(testInventoryItem);

        // Act
        CacheService.clearAllCache();

        // Assert
        expect(CacheService.getAllCachedProducts().isEmpty, true);
        expect(CacheService.getAllCachedInventoryItems().isEmpty, true);
      });

      test('should check if cache is empty', () {
        // Act & Assert - Initially empty
        expect(CacheService.isCacheEmpty(), true);

        // Arrange - Add some data
        CacheService.cacheProduct(testProduct);

        // Act & Assert - Not empty anymore
        expect(CacheService.isCacheEmpty(), false);
      });

      test('should get cache size', () {
        // Act & Assert - Initially empty
        expect(CacheService.getCacheSize(), 0);

        // Arrange - Add some data
        CacheService.cacheProduct(testProduct);
        CacheService.cacheInventoryItem(testInventoryItem);

        // Act & Assert - Size should be 2
        expect(CacheService.getCacheSize(), 2);
      });
    });

    group('Cache Performance', () {
      test('should handle large number of cached items', () {
        // Arrange - Create many products
        final List<Product> products = List.generate(
            100,
            (int index) => Product(
                  id: 'product-$index',
                  name: 'Product $index',
                  wholesalePrice: index * 10,
                  retailPrice: index * 15,
                  savedAt: DateTime.now(),
                ));

        // Act - Cache all products
        for (final Product product in products) {
          CacheService.cacheProduct(product);
        }

        // Assert
        expect(CacheService.getAllCachedProducts().length, 100);
        expect(CacheService.getCacheSize(), 100);
      });

      test('should handle rapid cache operations', () {
        // Act - Perform many rapid operations
        for (int i = 0; i < 50; i++) {
          final Product product = Product(
            id: 'rapid-product-$i',
            name: 'Rapid Product $i',
            wholesalePrice: i * 5,
            retailPrice: i * 8,
            savedAt: DateTime.now(),
          );
          CacheService.cacheProduct(product);
        }

        // Assert
        expect(CacheService.getCacheSize(), 50);
      });
    });
  });
}
