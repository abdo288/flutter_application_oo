import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../services/sync_coordination_service.dart';
import '../services/cross_tab_sync_service.dart';
import 'cart_provider.dart';
import 'stream_inventory_provider.dart';
import 'stream_product_provider.dart';

/// مقدم خدمة التطبيق المحسن باستخدام Stream Providers
class StreamAppProvider with ChangeNotifier {
  // ========== Completer for initialization ==========
  final Completer<void> _initializationCompleter = Completer<void>();

  // ========== Providers ==========

  final StreamProductProvider _productProvider = StreamProductProvider();
  final StreamInventoryProvider _inventoryProvider = StreamInventoryProvider();
  final CartProvider _cartProvider = CartProvider();

  // ========== متغيرات الحالة ==========

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Map<String, dynamic>>? _syncStatusSubscription;

  // ========== Getters ==========

  StreamProductProvider get productProvider {
    if (!_isInitialized) {
      debugPrint('تحذير: محاولة الوصول إلى productProvider قبل التهيئة');
    }
    return _productProvider;
  }

  StreamInventoryProvider get inventoryProvider {
    if (!_isInitialized) {
      debugPrint('تحذير: محاولة الوصول إلى inventoryProvider قبل التهيئة');
    }
    return _inventoryProvider;
  }

  CartProvider get cartProvider {
    return _cartProvider;
  }

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> get initializationComplete => _initializationCompleter.future;

  // ========== تهيئة وإغلاق ==========

  /// Initialize the application's providers.
  Future<void> initialize() async {
    if (_isInitialized) {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      return;
    }

    // Use a coordination service to prevent redundant initializations
    final bool success =
        await SyncCoordinationService.startInitialization(() async {
      _isLoading = true;
      _clearError();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify listeners that loading has started
      });

      try {
        debugPrint('🚀 بدء تهيئة StreamAppProvider...');

        // Initialize providers in parallel with individual timeouts
        await Future.wait(<Future<void>>[
          _productProvider.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ انتهت مهلة تهيئة StreamProductProvider');
              return;
            },
          ),
          _inventoryProvider.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ انتهت مهلة تهيئة StreamInventoryProvider');
              return;
            },
          ),
        ]).timeout(
          const Duration(seconds: 8), // Overall timeout
          onTimeout: () {
            debugPrint('⚠️ انتهت مهلة تهيئة StreamAppProvider الإجمالية');
            return <void>[];
          },
        );

        // ✅ تسجيل الاستماع لحالة المزامنة من cross-tab
        _registerSyncStatusListener();

        // ✅ تسجيل الاستماع لتغييرات CartProvider
        _cartProvider.addListener(() {
          notifyListeners();
        });

        debugPrint('✅ تم تهيئة StreamAppProvider بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في تهيئة StreamAppProvider: $e');
        _setError('خطأ في تهيئة التطبيق: $e');
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.completeError(e);
        }
        // Do not rethrow, allow the app to show an error state
      } finally {
        _isInitialized =
            true; // Move here - ensures always set regardless of success/timeout
        _isLoading = false;
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners(); // Notify listeners about the final state
        });
      }
    });

    if (!success) {
      _setError('فشل في تهيئة التطبيق - عملية تهيئة أخرى قيد التشغيل');
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter
            .completeError(Exception('Initialization already in progress'));
      }
    }
  }

  /// إعادة تحميل جميع البيانات مع نظام Throttling
  Future<void> refreshAll() async {
    // استخدام خدمة التنسيق للمزامنة الكاملة
    final bool success = await SyncCoordinationService.startFullSync(() async {
      _setLoading(true);
      _clearError();

      try {
        debugPrint('🔄 إعادة تحميل جميع البيانات...');

        // استخدام refresh بدلاً من initialize لضمان جلب البيانات من Firestore
        await Future.wait(<Future<void>>[
          _productProvider.refresh(),
          _inventoryProvider.refresh(),
        ]);

        debugPrint('✅ تم إعادة تحميل جميع البيانات بنجاح');
      } on Exception catch (e) {
        debugPrint('❌ خطأ في إعادة تحميل البيانات: $e');
        _setError('خطأ في إعادة تحميل البيانات: $e');
        rethrow;
      } finally {
        _setLoading(false);
      }
    });

    if (!success) {
      _setError('فشل في إعادة تحميل البيانات - عملية مزامنة أخرى قيد التشغيل');
    }
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة...');

      // إعادة تعيين حالة المزامنة في Providers
      await Future.wait(<Future<void>>[
        _productProvider.resetSyncState(),
        _inventoryProvider.resetSyncState(),
      ]);

      debugPrint('✅ تم إعادة تعيين حالة المزامنة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
      _setError('خطأ في إعادة تعيين حالة المزامنة: $e');
      rethrow;
    }
  }

  // ========== إحصائيات سريعة ==========

  /// الحصول على إحصائيات سريعة
  Map<String, dynamic> getQuickStats() {
    try {
      // التحقق من أن Providers مهيأة قبل الوصول إليها
      if (!_isInitialized ||
          _productProvider.isLoading ||
          _inventoryProvider.isLoading) {
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
        'productCount': _productProvider.productCount,
        'inventoryCount': _inventoryProvider.inventoryCount,
        'totalValue': _productProvider.getTotalValue(),
        'totalProfit': _productProvider.getTotalProfit(),
        'totalQuantity': _inventoryProvider.getTotalQuantity(),
        'lowStockCount': _inventoryProvider.getLowStockCount(),
      };
    } catch (e) {
      debugPrint('خطأ في getQuickStats: $e');
      // إرجاع قيم افتراضية آمنة في حالة الخطأ
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

  // ========== طرق مساعدة ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    _errorMessage = error;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ========== Cross-Tab Sync ==========

  /// تسجيل الاستماع لحالة المزامنة
  void _registerSyncStatusListener() {
    try {
      _syncStatusSubscription = CrossTabSyncService.statusUpdates
          .listen((Map<String, dynamic> status) {
        debugPrint('📊 تحديث حالة المزامنة من cross-tab: $status');
        // يمكن إضافة معالجة إضافية هنا حسب الحاجة
      });

      debugPrint('✅ تم تسجيل الاستماع لحالة المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الاستماع لحالة المزامنة: $e');
    }
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    _productProvider.dispose();
    _inventoryProvider.dispose();
    _cartProvider.removeListener(() {
      notifyListeners();
    });
    super.dispose();
  }
}
