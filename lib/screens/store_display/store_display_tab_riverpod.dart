import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/inventory_item.dart';

import '../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../providers/riverpod/stream_inventory_riverpod_provider.dart'
    as stream;
import '../../providers/store_display_riverpod_providers.dart';
import '../../services/app_event_bus.dart';
import '../../services/tab_coordination_service.dart';
import '../../utils/constants.dart';
import '../../utils/windows_platform_utils.dart';
import 'widgets/empty_state.dart';
import 'widgets/inventory_list.dart';
import 'widgets/no_results_state.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/stats_bar.dart';

/// تبويب المخزون مع Riverpod - يعرض قائمة المخزون مع البحث والفلترة
class InventoryDisplayTabRiverpod extends ConsumerStatefulWidget {
  const InventoryDisplayTabRiverpod({
    super.key,
    this.onNavigateToQuickSell,
  });
  final VoidCallback? onNavigateToQuickSell;

  @override
  ConsumerState<InventoryDisplayTabRiverpod> createState() =>
      _InventoryDisplayTabRiverpodState();
}

class _InventoryDisplayTabRiverpodState
    extends ConsumerState<InventoryDisplayTabRiverpod> {
  bool _hasInitialized = false;
  StreamSubscription<AppEvent>? _eventSubscription;
  StreamSubscription<TabCoordinationEvent>? _coordinationSubscription;

  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
        _setupEventListeners();
        _setupCoordinationListeners();
      }
    });
  }

  /// إعداد الاستماع للأحداث
  /// ✅ إصلاح: ضمان التناسق مع QuickSellTab
  void _setupEventListeners() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      if (!mounted) return;

      switch (event.runtimeType) {
        case InventoryUpdatedEvent:
          _handleInventoryUpdated(event as InventoryUpdatedEvent);
          break;
        case InventoryItemAddedEvent:
          _handleInventoryItemAdded(event as InventoryItemAddedEvent);
          break;
        case InventoryItemDeletedEvent:
          _handleInventoryItemDeleted(event as InventoryItemDeletedEvent);
          break;
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
      }
    });
  }

  /// معالجة تحديث المخزون
  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث تحديث المخزون - ${event.itemName}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// معالجة إضافة عنصر مخزون جديد
  void _handleInventoryItemAdded(InventoryItemAddedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث إضافة عنصر مخزون - ${event.item.name}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// معالجة حذف عنصر مخزون
  void _handleInventoryItemDeleted(InventoryItemDeletedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث حذف عنصر مخزون - ${event.itemName}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// معالجة اكتمال البيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint('🔄 InventoryDisplayTab: استلام حدث اكتمال البيع');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// إعداد الاستماع لأحداث التنسيق
  /// ✅ إصلاح: ضمان التناسق مع QuickSellTab
  void _setupCoordinationListeners() {
    _coordinationSubscription = TabCoordinationService()
        .coordinationStream
        .listen((TabCoordinationEvent event) {
      if (!mounted) return;

      switch (event.runtimeType) {
        case InventoryUpdateCoordinatedEvent:
          _handleCoordinatedInventoryUpdate(
              event as InventoryUpdateCoordinatedEvent);
          break;
        case InventoryDeletionCoordinatedEvent:
          _handleCoordinatedInventoryDeletion(
              event as InventoryDeletionCoordinatedEvent);
          break;
        case DataRefreshCoordinatedEvent:
          _handleCoordinatedDataRefresh(event as DataRefreshCoordinatedEvent);
          break;
      }
    });
  }

  /// معالجة تحديث المخزون المنسق
  void _handleCoordinatedInventoryUpdate(
      InventoryUpdateCoordinatedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث تنسيق تحديث المخزون - ${event.itemName}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// معالجة حذف المخزون المنسق
  void _handleCoordinatedInventoryDeletion(
      InventoryDeletionCoordinatedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث تنسيق حذف المخزون - ${event.itemName}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// معالجة إعادة تحميل البيانات المنسق
  void _handleCoordinatedDataRefresh(DataRefreshCoordinatedEvent event) {
    debugPrint(
        '🔄 InventoryDisplayTab: استلام حدث تنسيق إعادة تحميل البيانات - ${event.reason}');
    // إعادة تحميل البيانات
    _refreshInventory();
  }

  /// تهيئة البيانات عند فتح التبويب
  Future<void> _initializeData() async {
    if (!mounted || _hasInitialized) return;

    try {
      // انتظار تهيئة AppController أولاً مع timeout محسن لـ Windows
      final AppState appState = ref.read(appControllerProvider);
      if (!appState.isInitialized) {
        debugPrint('⏳ انتظار تهيئة AppController...');

        // timeout محسن لـ Windows
        try {
          await ref
              .read(appControllerProvider.notifier)
              .waitForInitialization()
              .timeout(WindowsPlatformUtils.windowsTimeout);
        } on TimeoutException {
          WindowsPlatformUtils.handleWindowsError(
              'AppController initialization', 'timeout');
          // المتابعة حتى لو انتهت المهلة
        }
      }

      // تهيئة حالة تبويب المخزون
      ref.read(inventoryDisplayStateProvider.notifier).initialize();

      // التحقق من أن inventoryControllerProvider يعمل بشكل صحيح
      try {
        final stream.InventoryState inventoryState =
            ref.read(stream.inventoryControllerProvider);
        debugPrint('✅ تم الوصول إلى inventoryControllerProvider بنجاح');
        debugPrint(
            '🔍 inventoryState.isInitialized = ${inventoryState.isInitialized}');
        debugPrint(
            '🔍 inventoryState.inventoryItems.length = ${inventoryState.inventoryItems.length}');

        // إذا لم تكن البيانات مهيأة، نحاول تحميلها من قاعدة البيانات المحلية
        if (!inventoryState.isInitialized ||
            inventoryState.inventoryItems.isEmpty) {
          debugPrint('🔄 محاولة تحميل البيانات من قاعدة البيانات المحلية...');
          // إعادة تحميل البيانات
          await ref.read(stream.inventoryControllerProvider.notifier).refresh();
        }
      } catch (e) {
        debugPrint('⚠️ تحذير: مشكلة في inventoryControllerProvider: $e');
        // المتابعة حتى لو كان هناك مشكلة
      }

      // The inventory data is automatically provided by inventoryStreamProvider
      // which provides real-time updates from the same source as POS tab
      if (mounted) {
        debugPrint(
            '🔄 تم تهيئة InventoryDisplayTabRiverpod مع inventoryStreamProvider للـ real-time updates');
      }

      _hasInitialized = true;
    } catch (e) {
      WindowsPlatformUtils.handleWindowsError(
          'InventoryDisplayTabRiverpod initialization', e);
      // إعادة تعيين الحالة للسماح بإعادة المحاولة
      _hasInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // تبسيط منطق التهيئة - إزالة الحجب الكامل للمحتوى
    final AppState appState = ref.watch(appControllerProvider);

    // فقط نعرض تحذير إذا كان هناك خطأ في التهيئة، لكن نسمح بالوصول للمحتوى
    if (appState.errorMessage != null) {
      // عرض تحذير في الأعلى بدلاً من حجب المحتوى
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تحذير: ${appState.errorMessage}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(appControllerProvider.notifier).clearError();
                  },
                  child: const Text('إخفاء', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMainContent()),
        ],
      );
    }

    return _buildMainContent();
  }

  /// بناء المحتوى الرئيسي للتبويب
  Widget _buildMainContent() {
    final InventoryDisplayState inventoryDisplayState =
        ref.watch(inventoryDisplayStateProvider);

    // التحقق من أن InventoryDisplayState مهيأ
    if (!inventoryDisplayState.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل بيانات المخزون...'),
          ],
        ),
      );
    }

    // محاولة جلب البيانات مع معالجة الأخطاء
    try {
      // التحقق من أن inventoryControllerProvider متاح
      final stream.InventoryState inventoryState =
          ref.watch(stream.inventoryControllerProvider);

      debugPrint(
          '🔍 InventoryDisplayTab: inventoryState.isInitialized = ${inventoryState.isInitialized}');
      debugPrint(
          '🔍 InventoryDisplayTab: inventoryState.inventoryItems.length = ${inventoryState.inventoryItems.length}');

      final List<InventoryItem> filteredItems =
          ref.watch(filteredInventoryProvider);
      final bool hasItems = ref.watch(hasInventoryItemsProvider);
      final bool hasResults = ref.watch(hasFilteredResultsProvider);

      debugPrint(
          '🔍 InventoryDisplayTab: hasItems = $hasItems, hasResults = $hasResults, filteredItems.length = ${filteredItems.length}');

      // التحقق من حالة الحذف أولاً
      if (inventoryDisplayState.isDeleting) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري حذف العنصر...'),
            ],
          ),
        );
      }

      // لا تعرض حالة "لا توجد عناصر" إلا إذا كان المخزون فعلاً فارغاً
      if (!hasItems) {
        return EmptyState(
          onRefresh: () async {
            debugPrint('🔄 إعادة تحميل البيانات من EmptyState...');
            await ref
                .read(stream.inventoryControllerProvider.notifier)
                .refresh();
          },
        );
      }

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[50],
        body: Column(
          children: <Widget>[
            // شريط البحث والفلترة المحسن
            const SearchFilterBar(),

            // شريط الإحصائيات
            const StatsBar(),

            // قائمة العناصر المحسنة
            Expanded(
              child: !hasResults
                  ? const NoResultsState()
                  : RefreshIndicator(
                      onRefresh: _refreshInventory,
                      color: AppConstants.primaryColor,
                      backgroundColor: Colors.white,
                      child: InventoryList(items: filteredItems),
                    ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ خطأ في بناء InventoryDisplayTab: $e');

      // محاولة إصلاح المشكلة تلقائياً
      if (e.toString().contains('unifiedRepositoryProvider') ||
          e.toString().contains('inventoryControllerProvider')) {
        debugPrint('🔄 محاولة إصلاح مشكلة الـ providers...');
        // إعادة تهيئة البيانات
        _hasInitialized = false;
        Future.microtask(_initializeData);
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل بيانات المخزون',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    // إعادة تهيئة البيانات
                    _hasInitialized = false;
                    _initializeData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // المتابعة حتى لو كان هناك خطأ
                    _hasInitialized = true;
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('المتابعة'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'يمكنك المتابعة في استخدام التبويب أو إعادة المحاولة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  /// إعادة تحميل المخزون
  /// ✅ إصلاح: ضمان التناسق التام مع ProductFormTab
  Future<void> _refreshInventory() async {
    try {
      debugPrint('🔄 InventoryDisplayTab: إعادة تحميل المخزون...');

      // إعادة تحميل البيانات من stream controller
      await ref.read(stream.inventoryControllerProvider.notifier).refresh();

      // إعادة تحميل حالة تبويب المخزون
      ref.read(inventoryDisplayStateProvider.notifier).initialize();

      debugPrint('✅ InventoryDisplayTab: تم إعادة تحميل المخزون بنجاح');
    } catch (e) {
      debugPrint('❌ InventoryDisplayTab: خطأ في إعادة تحميل المخزون: $e');

      // محاولة إصلاح المشكلة تلقائياً
      try {
        await ref.read(stream.inventoryControllerProvider.notifier).refresh();
        debugPrint('✅ InventoryDisplayTab: تم إصلاح المشكلة تلقائياً');
      } catch (retryError) {
        debugPrint('❌ InventoryDisplayTab: فشل في إصلاح المشكلة: $retryError');
      }
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _coordinationSubscription?.cancel();
    super.dispose();
  }
}
