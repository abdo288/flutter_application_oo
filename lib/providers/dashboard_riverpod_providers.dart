import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/providers/stream_app_provider.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import 'riverpod_provider_wrapper.dart';

/// Riverpod provider for dashboard statistics
final FutureProvider<DashboardStats> dashboardStatsProvider =
    FutureProvider<DashboardStats>(
  (FutureProviderRef<DashboardStats> ref) async {
    // Get the existing Provider services through Riverpod
    final StreamAppProvider appProvider = ref.watch(streamAppProvider);

    return await DashboardService.calculateDashboardStatsStatic(
      productProvider: appProvider.productProvider,
      inventoryProvider: appProvider.inventoryProvider,
    );
  },
  dependencies: [streamAppProvider],
);

/// Riverpod provider for top profitable products
final FutureProvider<List<Map<String, dynamic>>> topProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (FutureProviderRef<List<Map<String, dynamic>>> ref) async {
    final StreamAppProvider appProvider = ref.watch(streamAppProvider);

    return await DashboardService.getTopProfitableProductsStatic(
      productProvider: appProvider.productProvider,
      inventoryProvider: appProvider.inventoryProvider,
      limit: 3,
    );
  },
  dependencies: [streamAppProvider],
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
        (ProviderRef<DashboardRefreshNotifier> ref) =>
            DashboardRefreshNotifier(ref));

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
