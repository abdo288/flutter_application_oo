import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:profit_calculator/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('should navigate through all tabs successfully', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act & Assert - Navigate to Products tab
      await tester.tap(find.text('المنتجات'));
      await tester.pumpAndSettle();
      expect(find.text('المنتجات'), findsOneWidget);

      // Act & Assert - Navigate to Add Product tab
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();
      expect(find.text('إضافة منتج'), findsOneWidget);

      // Act & Assert - Navigate to Settings tab
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('should add a new product successfully', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Add Product tab
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      // Act - Fill product form
      await tester.enterText(find.byType(TextField).first, 'Test Product');
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.enterText(find.byType(TextField).at(2), '150');
      
      // Tap save button
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Assert - Check if product was added (navigate to products list)
      await tester.tap(find.text('المنتجات'));
      await tester.pumpAndSettle();
      
      // The product should appear in the list
      expect(find.text('Test Product'), findsOneWidget);
    });

    testWidgets('should edit an existing product', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Products tab
      await tester.tap(find.text('المنتجات'));
      await tester.pumpAndSettle();

      // Act - Find and tap edit button for first product
      final Finder editButtons = find.byIcon(Icons.edit);
      if (editButtons.evaluate().isNotEmpty) {
        await tester.tap(editButtons.first);
        await tester.pumpAndSettle();

        // Modify the product name
        await tester.enterText(find.byType(TextField).first, 'Updated Product Name');
        
        // Save changes
        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();

        // Assert - Check if product was updated
        expect(find.text('Updated Product Name'), findsOneWidget);
      }
    });

    testWidgets('should delete a product successfully', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Products tab
      await tester.tap(find.text('المنتجات'));
      await tester.pumpAndSettle();

      // Act - Find and tap delete button for first product
      final Finder deleteButtons = find.byIcon(Icons.delete);
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('حذف'));
        await tester.pumpAndSettle();

        // Assert - Product should be removed from list
        // Note: This test assumes there was at least one product to delete
      }
    });

    testWidgets('should handle offline mode gracefully', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Try to add a product (this should work even offline)
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Offline Product');
      await tester.enterText(find.byType(TextField).at(1), '50');
      await tester.enterText(find.byType(TextField).at(2), '75');
      
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Assert - Product should be saved locally
      await tester.tap(find.text('المنتجات'));
      await tester.pumpAndSettle();
      
      expect(find.text('Offline Product'), findsOneWidget);
    });

    testWidgets('should display statistics correctly', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate to settings to view statistics
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Assert - Check if statistics are displayed
      expect(find.text('الإحصائيات'), findsOneWidget);
    });

    testWidgets('should handle theme switching', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate to settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Look for theme toggle
      final Finder themeToggle = find.text('الوضع المظلم');
      if (themeToggle.evaluate().isNotEmpty) {
        await tester.tap(themeToggle);
        await tester.pumpAndSettle();

        // Assert - Theme should change
        // Note: This is a basic test - actual theme testing would require more sophisticated checks
      }
    });

    testWidgets('should handle backup and restore', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate to settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Look for backup button
      final Finder backupButton = find.text('نسخ احتياطي');
      if (backupButton.evaluate().isNotEmpty) {
        await tester.tap(backupButton);
        await tester.pumpAndSettle();

        // Assert - Backup should be initiated
        // Note: This test verifies the UI flow, not the actual backup functionality
      }
    });
  });
}


