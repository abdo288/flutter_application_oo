import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import 'riverpod/stream_inventory_riverpod_provider.dart';
import 'riverpod/stream_product_riverpod_provider.dart';

/// Riverpod provider for dashboard statistics
final FutureProvider<DashboardStats> dashboardStatsProvider =
    FutureProvider<DashboardStats>(
  (FutureProviderRef<DashboardStats> ref) async {
    // Get the state directly from providers
    final ProductsState productsState = ref.watch(productsControllerProvider);
    final InventoryState inventoryState = ref.watch(inventoryControllerProvider);

    return await DashboardService.calculateDashboardStatsForStates(
      productsState: productsState,
      inventoryState: inventoryState,
    );
  },
  dependencies: <ProviderOrFamily>[productsControllerProvider, inventoryControllerProvider],
);

/// Riverpod provider for top profitable products
final FutureProvider<List<Map<String, dynamic>>> topProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (FutureProviderRef<List<Map<String, dynamic>>> ref) async {
    // Get the state directly from providers
    final ProductsState productsState = ref.watch(productsControllerProvider);
    final InventoryState inventoryState = ref.watch(inventoryControllerProvider);

    return await DashboardService.getTopProfitableProductsForStates(
      productsState: productsState,
      inventoryState: inventoryState,
      limit: 3,
    );
  },
  dependencies: <ProviderOrFamily>[productsControllerProvider, inventoryControllerProvider],
);

/// Riverpod provider for dashboard refresh functionality
final StateProvider<bool> dashboardRefreshProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Riverpod provider for dashboard loading state
final StateProvider<bool> dashboardLoadingProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Riverpod provider for dashboard error state
final StateProvider<String?> dashboardErrorProvider =
    StateProvider<String?>((StateProviderRef<String?> ref) => null);

/// Riverpod provider for dashboard refresh action
final Provider<DashboardRefreshNotifier> dashboardRefreshNotifierProvider =
    Provider<DashboardRefreshNotifier>(
        DashboardRefreshNotifier.new);

/// Notifier class for dashboard refresh operations
class DashboardRefreshNotifier {
  DashboardRefreshNotifier(this._ref);
  final Ref _ref;

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    _ref.read(dashboardLoadingProvider.notifier).state = true;
    _ref.read(dashboardErrorProvider.notifier).state = null;

    try {
      // Invalidate and refresh the providers
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(topProductsProvider);

      // Wait for the providers to refresh
      await _ref.read(dashboardStatsProvider.future);
      await _ref.read(topProductsProvider.future);

      _ref.read(dashboardRefreshProvider.notifier).state = true;
    } catch (e) {
      _ref.read(dashboardErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(dashboardLoadingProvider.notifier).state = false;
    }
  }

  /// Clear error state
  void clearError() {
    _ref.read(dashboardErrorProvider.notifier).state = null;
  }
}
