# Copilot Instructions for Profit Calculator App

This Flutter app is an Arabic-language profit calculation and inventory management system with cloud sync capabilities. Here's what you need to know to work effectively with this codebase:

## 🏗️ Architecture Overview

### Core Services Layer
- `FirestoreService` (`services/firestore_service.dart`): Central data management with Firebase
- `HybridDataService` (`services/hybrid_data_service.dart`): Handles offline-first data operations
- `CacheService` (`services/cache_service.dart`): LRU caching for performance optimization
- `PerformanceService` (`services/performance_service.dart`): Monitors app performance metrics

### Data Models
- `Product` (`models/product.dart`): Core product model with pricing logic
- `InventoryItem` (`models/inventory_item.dart`): Inventory tracking model
- `DashboardStats` (`models/dashboard_stats.dart`): Analytics and reporting models

### UI Organization
- Screens in `screens/` follow a tab-based structure (dashboard, products, inventory)
- Reusable widgets in `widgets/` (e.g., `offline_indicator.dart`, `loading_widget.dart`)
- Theming and styles centralized in `theme/app_theme.dart`

## 🔑 Key Development Patterns

### Data Flow
1. UI components request data through service layer
2. Services check local cache first (CacheService)
3. If not cached, check offline storage (HybridDataService)
4. Finally, fetch from Firebase if online (FirestoreService)

### Error Handling Pattern
```dart
try {
  // Operation logic
} on Exception catch (e) {
  debugPrint('Error description: $e');
  return fallback_value; // Appropriate fallback
}
```

### State Management
- Uses Provider pattern for app-wide state
- Prefers local state for simple UI components
- Implements optimistic updates for offline operations

## 🛠️ Development Workflow

### Setup Requirements
- Flutter SDK 3.35.3+
- Dart 3.5.3+
- Firebase project configuration
- Valid `google-services.json` in `android/app/`

### Running the App
1. Install dependencies: `flutter pub get`
2. Setup Firebase: Add config files
3. Run debug mode: `flutter run`

### Testing
- Unit tests in `test/` mirror the lib/ structure
- Run tests: `flutter test`
- Integration tests focus on offline/online transitions

## ⚠️ Common Pitfalls

1. **Product Names**: Must be unique, check with `FirestoreService.checkIfNameExists()`
2. **Offline Data**: Always handle offline state with `ConnectivityService`
3. **Arabic Text**: Use proper RTL support in new UI components

## 📋 Project-Specific Conventions

### Code Organization
- Services use static methods for global access
- UI components follow Material Design 3 guidelines
- All strings should be in Arabic with English comments

### File Naming
- Services: `_service.dart` suffix
- Models: Clear nouns (e.g., `product.dart`)
- Screens: `_tab.dart` or `_screen.dart` suffix

### Documentation
- Arabic comments for business logic
- English comments for technical implementation
- Each service class has a README section

## 🔄 Integration Points

1. **Firebase Integration**
   - Firestore for data storage
   - Firebase Storage for images
   - Real-time sync handled by HybridDataService

2. **Local Storage**
   - SQLite for offline data
   - SharedPreferences for settings
   - File system for cached images

3. **External Services**
   - Barcode scanning integration
   - PDF report generation
   - Local notifications system