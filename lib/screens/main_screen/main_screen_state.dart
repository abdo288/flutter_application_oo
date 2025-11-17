import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_riverpod_providers.dart';
import '../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/memory_management_service.dart';
import '../../services/memory_optimization_service.dart';
import '../../services/navigation_service.dart';
import '../../services/presence_service.dart';
import '../../services/service_initializer.dart';
import '../../services/unified_sync_manager.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/safe_context_utils.dart';
import '../../widgets/offline_indicator.dart';
import 'layouts/responsive_builder.dart';
import 'main_screen.dart';

class StreamProfitCalculatorScreenState
    extends ConsumerState<StreamProfitCalculatorScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // UI State
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isAnimating = false; // Flag لمنع الحلقة اللانهائية
  // باركود ممسوح قيد التمرير إلى تبويب الإضافة
  String? _pendingScannedBarcode;

  // Add storage key for state persistence
  static const String _kCurrentIndexKey = 'main_screen_current_index';

  @override
  bool get wantKeepAlive => true;

  // Service initialization
  final ServiceInitializer _serviceInitializer = ServiceInitializer();
  bool _servicesInitialized = false;

  // Race condition fix: Store initialization Future (nullable to survive hot reload)
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();

    // Restore saved index if available
    final PageStorageBucket bucket = PageStorage.of(context);
    final int? savedIndex =
        bucket.readState(context, identifier: _kCurrentIndexKey) as int?;
    _currentIndex = savedIndex ?? 0;

    _pageController = PageController(initialPage: _currentIndex);

    // ✅ تهيئة NavigationService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.initialize(
        navigatorKey: GlobalKey<NavigatorState>(),
        onTabTapped: _onTabTapped,
      );
    });

    // ابدأ التهيئة مباشرة لتجنب قراءة المتغير قبل تهيئته
    _initializationFuture = _initializeApp();
  }

  /// Initialize the app and wait for Riverpod providers to be ready
  Future<void> _initializeApp() async {
    try {
      // Wait for the next frame to ensure context is available
      await Future<void>.delayed(Duration.zero);

      // Check if context is still valid
      if (!mounted) return;

      // Wait for the Riverpod app controller to be fully initialized with enhanced timeout
      try {
        await ref
            .read(appControllerProvider.notifier)
            .waitForInitialization()
            .timeout(const Duration(seconds: 30)); // زيادة المهلة لـ Windows
      } on TimeoutException {
        debugPrint(
            '⚠️ AppController initialization timed out after 30 seconds.');
        if (mounted) {
          // Consider showing a non-blocking warning to the user
          SafeContextUtils.safeExecute(
            context,
            () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                'تحذير: استغرق تحميل البيانات وقتاً طويلاً. يمكنك المتابعة.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              )),
            ),
            errorMessage: 'Failed to show timeout warning',
          );
        }
      }

      // Wait for auth provider to be ready
      final AuthState authState = ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        debugPrint(
            '⚠️ User not authenticated, skipping service initialization');
        return;
      }

      // Initialize services if ready
      await _initializeServicesIfReady();
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة التطبيق: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Initialize services if all conditions are met
  Future<void> _initializeServicesIfReady() async {
    try {
      final AppState appState = ref.read(appControllerProvider);
      final AuthState authState = ref.read(authStateProvider);

      if (appState.isInitialized &&
          authState.isAuthenticated &&
          authState.firebaseUser != null &&
          !_servicesInitialized) {
        debugPrint('🚀 بدء تهيئة الخدمات...');

        // Initialize services
        await _serviceInitializer.initializeServices(
            authState.firebaseUser!.uid, ref);

        _servicesInitialized = true;
        debugPrint('✅ تم تهيئة الخدمات بنجاح');

        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('⚠️ تخطي تهيئة الخدمات - المتطلبات غير متوفرة');
        debugPrint('  - AppController مهيأ: ${appState.isInitialized}');
        debugPrint('  - AuthProvider مصادق: ${authState.isAuthenticated}');
        debugPrint('  - Firebase User ID: ${authState.firebaseUser?.uid}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة الخدمات: $e');
      debugPrint('Stack trace: $stackTrace');

      // إعادة المحاولة بعد تأخير
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted && !_servicesInitialized) {
          _initializeServicesIfReady();
        }
      });
    }
  }

  /// معالج النقر على التبويبات
  void _onTabTapped(int index) {
    debugPrint(
        '🔄 _onTabTapped called with index: $index, currentIndex: $_currentIndex');

    // إضافة فحص إضافي للتأكد من صحة الفهرس
    if (index < 0 || index >= 8) {
      debugPrint('❌ Invalid tab index: $index (must be 0-7)');
      return;
    }

    if (_currentIndex == index) {
      debugPrint('ℹ️ Already on tab $index');
      return;
    }

    if (_isAnimating) {
      debugPrint('⚠️ Animation in progress, ignoring tap');
      return;
    }

    if (!_pageController.hasClients) {
      debugPrint('❌ PageController has no clients, skipping navigation');
      return;
    }

    debugPrint('🖱️ Tab clicked: $_currentIndex → $index');

    _isAnimating = true;

    // Save to PageStorage
    PageStorage.of(context)
        .writeState(context, index, identifier: _kCurrentIndexKey);

    // تحديث الفهرس فوراً لتجنب التأخير
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
      debugPrint('✅ Updated currentIndex to: $_currentIndex');
    }

    // استخدام النهج الهجين للتنقل
    _navigateToPage(index);
  }

  /// دالة التنقل الهجين - تقفز للصفحة المجاورة ثم تنتقل بسلاسة للهدف
  void _navigateToPage(int targetPage) {
    final int currentPage = _pageController.page?.round() ?? _currentIndex;
    final int distance = (targetPage - currentPage).abs();

    debugPrint(
        '🎯 Navigating: $currentPage → $targetPage (distance: $distance)');

    if (distance > 1) {
      // للمسافات البعيدة: قفز للصفحة المجاورة أولاً
      final int intermediatePage =
          targetPage > currentPage ? targetPage - 1 : targetPage + 1;

      debugPrint(
          '🚀 Large distance - jumping to intermediate page: $intermediatePage');

      try {
        _pageController.jumpToPage(intermediatePage);

        // ثم تحريك بشكل سلس للصفحة المستهدفة
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _pageController.hasClients) {
            _pageController
                .animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
            )
                .then((_) {
              _isAnimating = false;
              debugPrint('✅ Hybrid navigation completed: $targetPage');
            });
          }
        });
      } catch (e) {
        debugPrint('❌ Error in hybrid navigation: $e');
        _isAnimating = false;
      }
    } else {
      // للصفحات المجاورة: رسوم متحركة مباشرة
      debugPrint('🎬 Direct animation for adjacent page');
      _pageController
          .animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      )
          .then((_) {
        _isAnimating = false;
        debugPrint('✅ Direct animation completed: $targetPage');
      });
    }
  }

  /// معالج تغيير الصفحة من PageView
  void _onPageChanged(int index) {
    debugPrint(
        '📄 PageView onPageChanged: $index (isAnimating: $_isAnimating, current: $_currentIndex)');

    // إضافة فحص إضافي للتأكد من صحة الفهرس
    if (index < 0 || index >= 8) {
      debugPrint('❌ Invalid page index: $index (must be 0-7)');
      return;
    }

    // تجاهل استدعاءات onPageChanged أثناء التنقل الهجين
    if (_isAnimating) {
      debugPrint('⚠️ Ignoring onPageChanged during hybrid navigation');
      return;
    }

    // فقط حدّث إذا كان هناك desync فعلي
    if (_currentIndex != index && mounted) {
      // انتظر حتى تنتهي الـ animation إذا كانت قيد التشغيل
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _currentIndex != index && !_isAnimating) {
          setState(() {
            _currentIndex = index;
          });
          debugPrint('✅ State synced from PageView: $index');
        }
      });
    }
  }

  /// عرض حوار تأكيد الخروج
  Future<bool> _showExitDialog() async => await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('تأكيد الخروج'),
            content: const Text('هل أنت متأكد من أنك تريد الخروج من التطبيق؟'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('خروج'),
              ),
            ],
          ),
        ) ??
        false;

  @override
  void dispose() {
    _pageController.dispose();

    // تنظيف الخدمات
    _serviceInitializer.shutdownServices().catchError((Object e) {
      debugPrint('❌ خطأ في تنظيف الخدمات: $e');
    });

    // تنظيف شامل للذاكرة عند إغلاق الشاشة
    MemoryManagementService.performFinalCleanup();

    // تنظيف خدمات الأداء المحسنة
    MemoryOptimizationService().stopMemoryMonitoring();

    // تنظيف خدمة الاتصال
    ConnectivityService.dispose();

    // تنظيف خدمة الحضور
    PresenceService.instance.dispose();

    // تنظيف مدير المزامنة الموحد
    UnifiedSyncManager().dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // إضافة debug logging شامل
    debugPrint('🏗️ Building main screen with currentIndex: $_currentIndex');
    debugPrint('🏗️ Services initialized: $_servicesInitialized');
    debugPrint('🏗️ PageController has clients: ${_pageController.hasClients}');
    debugPrint('🏗️ Is animating: $_isAnimating');
    debugPrint('🏗️ Screen width: ${context.screenWidth}');
    debugPrint('🏗️ isSmallScreen: ${context.isSmallScreen}');

    // إضافة معلومات إضافية للتحقق من حالة التبويبات
    final List<String> tabNames = <String>[
      'Dashboard',
      'Quick Sell',
      'Product Form',
      'Sales History',
      'Reports',
      'POS',
      'Inventory',
      'Realtime Settings'
    ];
    if (_currentIndex >= 0 && _currentIndex < tabNames.length) {
      debugPrint('🏗️ Current tab: ${tabNames[_currentIndex]}');
    }

    return PageStorage(
      bucket: PageStorageBucket(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            try {
              final bool shouldPop = await _showExitDialog();
              if (shouldPop) {
                context.safePop();
              }
            } catch (e) {
              debugPrint('خطأ في معالجة الخروج: $e');
              // في حالة الخطأ، اسمح بالخروج فقط إذا كان هناك routes للعودة إليها
              context.safePop();
            }
          }
        },
        child: OfflineIndicator(
          child: ResponsiveLayoutBuilder(
            currentIndex: _currentIndex,
            onTabTapped: _onTabTapped,
            onPageChanged: _onPageChanged,
            pageController: _pageController,
            pendingScannedBarcode: _pendingScannedBarcode,
            initializationFuture: _initializationFuture,
          ),
        ),
      ),
    );
  }
}
