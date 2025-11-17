import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/cross_tab_sync_service.dart';
import '../../services/sync_coordination_service.dart';
import 'cart_riverpod_provider.dart';
import 'stream_inventory_riverpod_provider.dart';
import 'stream_product_riverpod_provider.dart';

part 'stream_app_riverpod_provider.g.dart';

/// State للتطبيق الكامل
class AppState {
  const AppState({
    required this.isInitialized,
    this.isLoading = false,
    this.errorMessage,
    this.isSyncing = false,
  });

  factory AppState.initial() => const AppState(isInitialized: false);
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;
  final bool isSyncing;

  AppState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
    bool? isSyncing,
  }) =>
      AppState(
        isInitialized: isInitialized ?? this.isInitialized,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isSyncing: isSyncing ?? this.isSyncing,
      );
}

/// App Controller الرئيسي
@riverpod
class AppController extends _$AppController {
  StreamSubscription<Map<String, dynamic>>? _syncStatusSubscription;
  Completer<void>? _initializationCompleter;

  @override
  AppState build() {
    _initializationCompleter = Completer<void>();

    // التهيئة التلقائية
    Future.microtask(initialize);

    ref.onDispose(() {
      _syncStatusSubscription?.cancel();
      debugPrint('🗑️ تم تنظيف AppController');
    });

    return AppState.initial();
  }

  /// تهيئة التطبيق
  Future<void> initialize() async {
    if (state.isInitialized) {
      if (_initializationCompleter != null &&
          !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete();
      }
      debugPrint('⚠️ التطبيق مهيأ بالفعل - حماية من إعادة التهيئة');
      return;
    }

    // استخدام خدمة التنسيق
    final bool success =
        await SyncCoordinationService.startInitialization(() async {
      state = state.copyWith(isLoading: true);

      try {
        debugPrint('🚀 بدء تهيئة التطبيق...');

        // تهيئة الـ providers مع timeout محسن لـ Windows
        try {
          await Future.wait(<Future<void>>[
            _initializeProvider(
                () => ref.read(productsControllerProvider.notifier)),
            _initializeProvider(
                () => ref.read(inventoryControllerProvider.notifier)),
            _initializeProvider(() => ref.read(cartControllerProvider.future)),
          ]).timeout(
            const Duration(seconds: 20), // زيادة المهلة لـ Windows
            onTimeout: () {
              debugPrint('⚠️ انتهت مهلة تهيئة الـ providers - سيتم الاستمرار');
              return <void>[];
            },
          );
        } catch (e) {
          debugPrint('⚠️ خطأ في تهيئة بعض الـ providers: $e - سيتم الاستمرار');
          // لا نرمي الخطأ، نستمر في التهيئة
        }

        // إعداد المزامنة
        _setupSyncListeners();

        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
        );

        if (_initializationCompleter != null &&
            !_initializationCompleter!.isCompleted) {
          _initializationCompleter!.complete();
        }

        debugPrint('✅ اكتملت تهيئة التطبيق');
      } catch (e) {
        debugPrint('❌ خطأ في تهيئة التطبيق: $e');
        // بدلاً من إيقاف التطبيق، نستمر مع رسالة تحذير
        state = state.copyWith(
          errorMessage:
              'تحذير: فشل في تحميل بعض البيانات. التطبيق يعمل في وضع محدود.',
          isLoading: false,
        );
        if (_initializationCompleter != null &&
            !_initializationCompleter!.isCompleted) {
          _initializationCompleter!.complete();
        }
      }
    });

    if (!success) {
      state = state.copyWith(
        errorMessage: 'فشل في تهيئة التطبيق - عملية تهيئة أخرى قيد التشغيل',
      );
      if (_initializationCompleter != null &&
          !_initializationCompleter!.isCompleted) {
        _initializationCompleter!
            .completeError(Exception('Initialization already in progress'));
      }
    }
  }

  /// تهيئة provider واحد مع معالجة الأخطاء
  Future<void> _initializeProvider(dynamic Function() getProvider) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final dynamic provider = getProvider();

      // التحقق من أن provider تم إنشاؤه بنجاح
      if (provider != null) {
        debugPrint('✅ تم تهيئة ${provider.runtimeType} بنجاح');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة provider: $e');
      // لا نرمي الخطأ، نستمر في التهيئة
    }
  }

  /// إعداد مستمعي المزامنة
  void _setupSyncListeners() {
    try {
      _syncStatusSubscription = CrossTabSyncService.statusUpdates
          .listen((Map<String, dynamic> status) {
        debugPrint('📊 تحديث حالة المزامنة: $status');
        // يمكن إضافة معالجة إضافية هنا
      });
      debugPrint('✅ تم تسجيل الاستماع لحالة المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الاستماع لحالة المزامنة: $e');
    }
  }

  /// تحديث شامل
  Future<void> refreshAll() async {
    // حماية من إعادة تعيين isInitialized أثناء التحديث
    if (!state.isInitialized) {
      debugPrint('⚠️ لا يمكن تحديث البيانات - التطبيق غير مهيأ');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      debugPrint('🔄 إعادة تحميل جميع البيانات...');

      // محاولة تحديث كل provider بشكل منفصل
      try {
        await ref.read(productsControllerProvider.notifier).refresh();
        debugPrint('✅ تم تحديث المنتجات');
      } catch (e) {
        debugPrint('⚠️ خطأ في تحديث المنتجات: $e');
      }

      try {
        await ref.read(inventoryControllerProvider.notifier).refresh();
        debugPrint('✅ تم تحديث المخزون');
      } catch (e) {
        debugPrint('⚠️ خطأ في تحديث المخزون: $e');
      }

      state = state.copyWith(
        isLoading: false,
      );

      debugPrint('✅ تم تحديث البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في التحديث الشامل: $e');
      state = state.copyWith(
        errorMessage:
            'تحذير: فشل في تحميل بعض البيانات. التطبيق يعمل في وضع محدود.',
        isLoading: false,
      );
    }
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة...');

      await Future.wait(<Future<void>>[
        ref.read(productsControllerProvider.notifier).resetSyncState(),
        ref.read(inventoryControllerProvider.notifier).resetSyncState(),
      ]);

      debugPrint('✅ تم إعادة تعيين حالة المزامنة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// الحصول على إحصائيات سريعة
  Map<String, dynamic> getQuickStats() {
    try {
      final ProductsState productsState = ref.read(productsControllerProvider);
      final InventoryState inventoryState =
          ref.read(inventoryControllerProvider);

      if (!state.isInitialized ||
          productsState.isLoading ||
          inventoryState.isLoading) {
        return <String, dynamic>{
          'productCount': 0,
          'inventoryCount': 0,
          'totalValue': 0.0,
          'totalProfit': 0.0,
          'totalQuantity': 0,
          'lowStockCount': 0,
        };
      }

      return <String, dynamic>{
        'productCount': productsState.productCount,
        'inventoryCount': inventoryState.inventoryCount,
        'totalValue': productsState.getTotalValue(),
        'totalProfit': productsState.getTotalProfit(),
        'totalQuantity': inventoryState.getTotalQuantity(),
        'lowStockCount': inventoryState.getLowStockCount(),
      };
    } catch (e) {
      debugPrint('خطأ في getQuickStats: $e');
      return <String, dynamic>{
        'productCount': 0,
        'inventoryCount': 0,
        'totalValue': 0.0,
        'totalProfit': 0.0,
        'totalQuantity': 0,
        'lowStockCount': 0,
      };
    }
  }

  /// انتظار التهيئة
  Future<void> waitForInitialization() async {
    if (state.isInitialized) return;
    await _initializationCompleter?.future;
  }

  /// إعادة التهيئة
  Future<void> reinitialize() async {
    // حماية من إعادة تعيين isInitialized إذا كان التطبيق مهيأ بالفعل
    if (state.isInitialized) {
      debugPrint(
          '⚠️ محاولة إعادة تهيئة التطبيق المهيأ بالفعل - سيتم تجاهل الطلب');
      return;
    }

    _initializationCompleter = Completer<void>();
    state = AppState.initial();
    await initialize();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith(
      isLoading: false,
    );
  }

  /// فحص حالة التطبيق وإعادة المحاولة التلقائية
  Future<void> checkAndRetry() async {
    if (state.errorMessage != null && !state.isLoading) {
      debugPrint('🔄 محاولة إعادة تحميل البيانات تلقائياً...');
      await refreshAll();
    }
  }

  /// الوصول إلى ProductsController
  ProductsController get productProvider =>
      ref.read(productsControllerProvider.notifier);

  /// الوصول إلى InventoryController
  InventoryController get inventoryProvider =>
      ref.read(inventoryControllerProvider.notifier);

  /// الوصول إلى CartController
  Future<CartController> get cartProvider async =>
      ref.read(cartControllerProvider.notifier);
}

/// Helper Providers
@riverpod
bool appIsInitialized(AppIsInitializedRef ref) =>
    ref.watch(appControllerProvider).isInitialized;

@riverpod
bool appIsLoading(AppIsLoadingRef ref) =>
    ref.watch(appControllerProvider).isLoading;

@riverpod
bool appIsSyncing(AppIsSyncingRef ref) =>
    ref.watch(appControllerProvider).isSyncing;

@riverpod
String? appErrorMessage(AppErrorMessageRef ref) =>
    ref.watch(appControllerProvider).errorMessage;

/// Provider لـ initializationComplete (للتوافق مع الكود القديم)
@riverpod
Future<void> appInitializationComplete(AppInitializationCompleteRef ref) async {
  await ref.watch(appControllerProvider.notifier).waitForInitialization();
}
