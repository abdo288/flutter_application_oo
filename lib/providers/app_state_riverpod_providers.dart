import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_state_manager.dart';

/// Provider لـ AppStateNotifier
final StateNotifierProvider<AppStateNotifier, AppState> appStateManagerProvider = appStateNotifierProvider;

/// Provider لحالة المزامنة
final Provider<bool> isSyncingProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(appStateNotifierProvider).isSyncing);

/// Provider لحالة الاتصال
final Provider<bool> isOnlineProvider = Provider<bool>((ProviderRef<bool> ref) => ref.watch(appStateNotifierProvider).isOnline);

/// Provider للعمليات المعلقة
final Provider<int> pendingOperationsProvider = Provider<int>((ProviderRef<int> ref) => ref.watch(appStateNotifierProvider).pendingOperations);

/// Provider لنوع الاتصال
final Provider<String?> connectionTypeProvider = Provider<String?>((ProviderRef<String?> ref) => ref.watch(appStateNotifierProvider).connectionType);

/// Provider لملخص الحالة
final Provider<Map<String, dynamic>> stateSummaryProvider = Provider<Map<String, dynamic>>((ProviderRef<Map<String, dynamic>> ref) => ref.watch(appStateNotifierProvider.notifier).getStateSummary());
