import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_alert.dart';
import '../services/inventory_alert_service.dart';
import 'riverpod/stream_inventory_riverpod_provider.dart';

/// حالة تبويب التنبيهات
class AlertsState {

  const AlertsState({
    this.alerts = const <InventoryAlert>[],
    this.alertStatistics = const <String, int>{},
    this.expandedGroups = const <AlertType, bool>{},
    this.isLoading = false,
    this.showOnlyUnread = false,
    this.errorMessage,
  });
  final List<InventoryAlert> alerts;
  final Map<String, int> alertStatistics;
  final Map<AlertType, bool> expandedGroups;
  final bool isLoading;
  final bool showOnlyUnread;
  final String? errorMessage;

  AlertsState copyWith({
    List<InventoryAlert>? alerts,
    Map<String, int>? alertStatistics,
    Map<AlertType, bool>? expandedGroups,
    bool? isLoading,
    bool? showOnlyUnread,
    String? errorMessage,
  }) => AlertsState(
      alerts: alerts ?? this.alerts,
      alertStatistics: alertStatistics ?? this.alertStatistics,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      isLoading: isLoading ?? this.isLoading,
      showOnlyUnread: showOnlyUnread ?? this.showOnlyUnread,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// مدير حالة التنبيهات
class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier(this.ref) : super(const AlertsState());

  final Ref ref;

  /// تحميل التنبيهات
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true);

    try {
      final List<InventoryAlert> alerts =
          await InventoryAlertService.getAllAlerts();
      final Map<String, int> statistics =
          await InventoryAlertService.getAlertStatistics();

      state = state.copyWith(
        alerts: alerts,
        alertStatistics: statistics,
        isLoading: false,
      );

      // فتح المجموعة الأولى تلقائياً
      _expandFirstGroupIfNeeded();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تحميل التنبيهات: $e',
      );
      debugPrint('خطأ في تحميل التنبيهات: $e');
    }
  }

  /// تحديث التنبيهات
  Future<void> refreshAlerts() async {
    await loadAlerts();
  }

  /// فحص المخزون وإنشاء التنبيهات
  Future<void> checkInventoryAlerts() async {
    state = state.copyWith(isLoading: true);

    try {
      final InventoryController inventoryController =
          ref.read(inventoryControllerProvider.notifier);
      await InventoryAlertService.checkInventoryAlertsForControllers(
          inventoryController);
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في فحص المخزون: $e',
      );
      debugPrint('خطأ في فحص المخزون: $e');
    }
  }

  /// تحديد تنبيه كمقروء
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await InventoryAlertService.markAlertAsRead(alertId);

      // تحديث التنبيه في القائمة
      final List<InventoryAlert> updatedAlerts = state.alerts.map((InventoryAlert alert) {
        if (alert.id == alertId) {
          return alert.copyWith(isRead: true);
        }
        return alert;
      }).toList();

      state = state.copyWith(alerts: updatedAlerts);
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطأ في تحديد التنبيه كمقروء: $e');
      debugPrint('خطأ في تحديد التنبيه كمقروء: $e');
    }
  }

  /// حذف تنبيه
  Future<void> deleteAlert(String alertId) async {
    try {
      await InventoryAlertService.deleteAlert(alertId);

      // إزالة التنبيه من القائمة
      final List<InventoryAlert> updatedAlerts =
          state.alerts.where((InventoryAlert alert) => alert.id != alertId).toList();

      state = state.copyWith(alerts: updatedAlerts);
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطأ في حذف التنبيه: $e');
      debugPrint('خطأ في حذف التنبيه: $e');
    }
  }

  /// تحديد جميع التنبيهات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      await InventoryAlertService.markAllAlertsAsRead();
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'خطأ في تحديد جميع التنبيهات كمقروءة: $e');
      debugPrint('خطأ في تحديد جميع التنبيهات كمقروءة: $e');
    }
  }

  /// حذف التنبيهات المقروءة
  Future<void> deleteReadAlerts() async {
    try {
      await InventoryAlertService.deleteReadAlerts();
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطأ في حذف التنبيهات المقروءة: $e');
      debugPrint('خطأ في حذف التنبيهات المقروءة: $e');
    }
  }

  /// تنظيف التنبيهات القديمة
  Future<void> cleanupOldAlerts() async {
    try {
      await InventoryAlertService.cleanupOldAlerts();
      await loadAlerts();
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'خطأ في تنظيف التنبيهات القديمة: $e');
      debugPrint('خطأ في تنظيف التنبيهات القديمة: $e');
    }
  }

  /// تعيين الفلتر
  void setFilter(bool showOnlyUnread) {
    state = state.copyWith(showOnlyUnread: showOnlyUnread);
  }

  /// تبديل حالة مجموعة التنبيهات
  void toggleGroup(AlertType alertType) {
    final Map<AlertType, bool> updatedGroups = Map.from(state.expandedGroups);
    updatedGroups[alertType] = !(updatedGroups[alertType] ?? false);
    state = state.copyWith(expandedGroups: updatedGroups);
  }

  /// تبديل حالة جميع المجموعات
  void toggleAllGroups() {
    final bool allExpanded = _areAllGroupsExpanded();
    final Map<AlertType, bool> updatedGroups = <AlertType, bool>{};

    for (final AlertType alertType in AlertType.values) {
      updatedGroups[alertType] = !allExpanded;
    }

    state = state.copyWith(expandedGroups: updatedGroups);
  }

  /// تحميل الإحصائيات
  Future<void> loadStatistics() async {
    try {
      final Map<String, int> statistics =
          await InventoryAlertService.getAlertStatistics();
      state = state.copyWith(alertStatistics: statistics);
    } catch (e) {
      debugPrint('خطأ في تحميل الإحصائيات: $e');
    }
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  /// التحقق من فتح جميع المجموعات
  bool _areAllGroupsExpanded() {
    if (state.expandedGroups.isEmpty) return false;
    return state.expandedGroups.values.every((bool isExpanded) => isExpanded);
  }

  /// فتح المجموعة الأولى تلقائياً عند وجود تنبيهات
  void _expandFirstGroupIfNeeded() {
    if (state.expandedGroups.isEmpty && state.alerts.isNotEmpty) {
      final Map<AlertType, List<InventoryAlert>> groupedAlerts =
          _groupAlertsByType(state.alerts);
      if (groupedAlerts.isNotEmpty) {
        final AlertType firstType = groupedAlerts.keys.first;
        final Map<AlertType, bool> updatedGroups =
            Map.from(state.expandedGroups);
        updatedGroups[firstType] = true;
        state = state.copyWith(expandedGroups: updatedGroups);
      }
    }
  }

  /// تجميع التنبيهات حسب النوع
  Map<AlertType, List<InventoryAlert>> _groupAlertsByType(
      List<InventoryAlert> alerts) {
    final Map<AlertType, List<InventoryAlert>> grouped =
        <AlertType, List<InventoryAlert>>{};

    for (final InventoryAlert alert in alerts) {
      if (!grouped.containsKey(alert.alertType)) {
        grouped[alert.alertType] = <InventoryAlert>[];
      }
      grouped[alert.alertType]!.add(alert);
    }

    // ترتيب المجموعات حسب الأولوية
    final Map<AlertType, List<InventoryAlert>> orderedGroups =
        <AlertType, List<InventoryAlert>>{};

    // نفاد الكمية أولاً
    if (grouped.containsKey(AlertType.outOfStock)) {
      orderedGroups[AlertType.outOfStock] = grouped[AlertType.outOfStock]!;
    }

    // الحد الأدنى ثانياً
    if (grouped.containsKey(AlertType.lowStock)) {
      orderedGroups[AlertType.lowStock] = grouped[AlertType.lowStock]!;
    }

    // قرب الانتهاء أخيراً
    if (grouped.containsKey(AlertType.expiringSoon)) {
      orderedGroups[AlertType.expiringSoon] = grouped[AlertType.expiringSoon]!;
    }

    return orderedGroups;
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة تبويب التنبيهات
final AutoDisposeStateNotifierProvider<AlertsNotifier, AlertsState> alertsStateProvider =
    StateNotifierProvider.autoDispose<AlertsNotifier, AlertsState>(
  AlertsNotifier.new,
);

/// Provider للتحقق من حالة التحميل
final AutoDisposeProvider<bool> alertsLoadingProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AlertsState state = ref.watch(alertsStateProvider);
    return state.isLoading;
  },
  dependencies: <ProviderOrFamily>[alertsStateProvider],
);

/// Provider للتنبيهات المفلترة
final AutoDisposeProvider<List<InventoryAlert>> filteredAlertsProvider = Provider.autoDispose<List<InventoryAlert>>(
  (AutoDisposeProviderRef<List<InventoryAlert>> ref) {
    final AlertsState state = ref.watch(alertsStateProvider);

    if (state.showOnlyUnread) {
      return state.alerts.where((InventoryAlert alert) => !alert.isRead).toList();
    }

    return state.alerts;
  },
  dependencies: <ProviderOrFamily>[alertsStateProvider],
);

/// Provider للتنبيهات المجمعة
final AutoDisposeProvider<Map<AlertType, List<InventoryAlert>>> groupedAlertsProvider =
    Provider.autoDispose<Map<AlertType, List<InventoryAlert>>>(
  (AutoDisposeProviderRef<Map<AlertType, List<InventoryAlert>>> ref) {
    final List<InventoryAlert> filteredAlerts =
        ref.watch(filteredAlertsProvider);

    final Map<AlertType, List<InventoryAlert>> grouped =
        <AlertType, List<InventoryAlert>>{};

    for (final InventoryAlert alert in filteredAlerts) {
      if (!grouped.containsKey(alert.alertType)) {
        grouped[alert.alertType] = <InventoryAlert>[];
      }
      grouped[alert.alertType]!.add(alert);
    }

    // ترتيب المجموعات حسب الأولوية
    final Map<AlertType, List<InventoryAlert>> orderedGroups =
        <AlertType, List<InventoryAlert>>{};

    // نفاد الكمية أولاً
    if (grouped.containsKey(AlertType.outOfStock)) {
      orderedGroups[AlertType.outOfStock] = grouped[AlertType.outOfStock]!;
    }

    // الحد الأدنى ثانياً
    if (grouped.containsKey(AlertType.lowStock)) {
      orderedGroups[AlertType.lowStock] = grouped[AlertType.lowStock]!;
    }

    // قرب الانتهاء أخيراً
    if (grouped.containsKey(AlertType.expiringSoon)) {
      orderedGroups[AlertType.expiringSoon] = grouped[AlertType.expiringSoon]!;
    }

    return orderedGroups;
  },
  dependencies: <ProviderOrFamily>[filteredAlertsProvider, alertsStateProvider],
);

/// Provider لإحصائيات التنبيهات
final AutoDisposeProvider<Map<String, int>> alertStatisticsProvider = Provider.autoDispose<Map<String, int>>(
  (AutoDisposeProviderRef<Map<String, int>> ref) {
    final AlertsState state = ref.watch(alertsStateProvider);
    return state.alertStatistics;
  },
  dependencies: <ProviderOrFamily>[alertsStateProvider],
);

/// Provider لرسالة الخطأ
final AutoDisposeProvider<String?> alertsErrorProvider = Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final AlertsState state = ref.watch(alertsStateProvider);
    return state.errorMessage;
  },
  dependencies: <ProviderOrFamily>[alertsStateProvider],
);

/// Provider لحالة المجموعات المفتوحة
final AutoDisposeProvider<Map<AlertType, bool>> expandedGroupsProvider = Provider.autoDispose<Map<AlertType, bool>>(
  (AutoDisposeProviderRef<Map<AlertType, bool>> ref) {
    final AlertsState state = ref.watch(alertsStateProvider);
    return state.expandedGroups;
  },
  dependencies: <ProviderOrFamily>[alertsStateProvider],
);

/// Provider للتحقق من فتح جميع المجموعات
final AutoDisposeProvider<bool> allGroupsExpandedProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final Map<AlertType, bool> expandedGroups =
        ref.watch(expandedGroupsProvider);
    if (expandedGroups.isEmpty) return false;
    return expandedGroups.values.every((bool isExpanded) => isExpanded);
  },
  dependencies: <ProviderOrFamily>[expandedGroupsProvider],
);
