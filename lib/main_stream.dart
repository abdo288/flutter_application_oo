// ignore_for_file: prefer_const_constructors, avoid_print
// تجاهل التحذيرات المتعلقة بالثوابت والطباعة في الكونسول

// Dart Core
import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Flutter Framework
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:profit_calculator/providers/stream_inventory_provider.dart';
import 'package:profit_calculator/providers/stream_product_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/riverpod_provider_wrapper.dart'
    show streamAppProvider, RiverpodProviderWrapper;

// Project Files
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/stream_app_provider.dart';
import 'screens/add_product_tab_riverpod.dart';
import 'screens/alerts_tab_riverpod.dart';
import 'screens/inventory_tab_riverpod.dart';
import 'screens/dashboard_tab_riverpod.dart';
import 'screens/enhanced_pos_reports_screen_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/pos_tab_riverpod.dart';
import 'screens/product_list_tab_riverpod.dart';
import 'screens/realtime_settings_tab.dart';
import 'screens/settings_tab_riverpod.dart';
import 'screens/store_display_tab_riverpod.dart';
import 'screens/windows_pos_screen.dart';
import 'services/appearance_service.dart';
import 'services/auto_backup_service.dart';
import 'services/backup_service.dart';
import 'services/connectivity_service.dart';
import 'services/enhanced_security_service.dart';
import 'services/error_handler_service.dart';
import 'services/local_notification_service.dart';
import 'services/locale_service.dart';
import 'services/memory_management_service.dart';
import 'services/memory_optimization_service.dart';
import 'services/performance_service.dart';
import 'services/presence_service.dart';
import 'services/service_initializer.dart';
import 'services/unified_sync_manager.dart';
// ✅ إضافة الخدمات الجديدة للتواصل بين التبويبات
import 'services/app_state_manager.dart';
import 'services/navigation_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/currency_formatter.dart';
import 'utils/navigation_utils.dart';
import 'utils/responsive_breakpoints.dart';
import 'widgets/alert_badge.dart';
import 'widgets/loading_widget.dart' as custom_widgets;
import 'widgets/offline_indicator.dart';
import 'widgets/responsive_navigation.dart';
import 'widgets/responsive_widgets.dart';
import 'widgets/tab_error_overlay.dart';
// ✅ إضافة مؤشر المزامنة
import 'widgets/sync_status_indicator.dart';

void main() async {
  // ضمان تهيئة Flutter قبل أي شيء آخر
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الخدمات الأساسية قبل تشغيل التطبيق
  await initializeCoreServices();

  // تشغيل التطبيق بعد اكتمال التهيئة الأساسية
  runApp(const StreamProfitCalculatorApp());
}

/// تهيئة الخدمات الأساسية التي لا تعتمد على واجهة المستخدم
Future<void> initializeCoreServices() async {
  try {
    // تحميل متغيرات البيئة أولاً مع معالجة أفضل للأخطاء
    try {
      await dotenv.load();
      debugPrint('✅ تم تحميل متغيرات البيئة بنجاح');
    } catch (e) {
      debugPrint(
          '⚠️ تحذير: لم يتم العثور على ملف .env - سيتم استخدام القيم الافتراضية');
      debugPrint('تفاصيل الخطأ: $e');
    }

    // تهيئة Firebase مع معالجة أفضل للأخطاء
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ تم تهيئة Firebase بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Firebase: $e');
      // إعادة المحاولة مع القيم الافتراضية
      try {
        await Firebase.initializeApp();
        debugPrint('✅ تم تهيئة Firebase بالقيم الافتراضية');
      } catch (e2) {
        debugPrint('❌ فشل في تهيئة Firebase حتى بالقيم الافتراضية: $e2');
        rethrow;
      }
    }

    // إعدادات Firestore المحسنة
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      ignoreUndefinedProperties: true,
    );
    debugPrint('✅ تم تهيئة إعدادات Firestore');

    // تهيئة الخدمات التي يمكن أن تعمل بالتوازي
    await Future.wait(<Future<void>>[
      _initializeLocalServices(),
      EnhancedSecurityService.initialize(),
      LocaleService.instance.initialize(),
      BackupService.initialize(),
      AutoBackupService.initialize(),
      AppearanceService.instance.initialize(),
    ]);

    // تهيئة خدمات لا تعتمد على غيرها
    PerformanceService.initialize();
    ErrorHandlerService.initialize();
    MemoryManagementService.setMemoryLimits();
    MemoryManagementService.startPeriodicCleanup();

    // تهيئة خدمات الأداء المحسنة
    MemoryOptimizationService().startMemoryMonitoring();

    // ✅ تهيئة الخدمات الجديدة للتواصل بين التبويبات
    try {
      // تهيئة AppStateManager
      final AppStateManager appStateManager = AppStateManager();
      appStateManager.initialize();
      debugPrint('✅ تم تهيئة AppStateManager');

      // تهيئة NavigationService (سيتم إكمالها في build)
      debugPrint('✅ تم تحضير NavigationService');

      debugPrint('✅ تم تهيئة خدمات التواصل بين التبويبات');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمات التواصل: $e');
    }

    // إعداد نظام السجلات
    _setupLogging();

    // ✅ إضافة تهيئة المزامنة بعد Firebase
    try {
      final UnifiedSyncManager syncManager = UnifiedSyncManager();
      // تهيئة المزامنة مع معرف مؤقت
      await syncManager.initialize('temp_user');
      debugPrint('✅ تم تهيئة مدير المزامنة الموحد');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة مدير المزامنة: $e');
    }

    debugPrint('✅ تم تهيئة جميع الخدمات الأساسية بنجاح');
  } on FirebaseException catch (e, s) {
    debugPrint('❌ خطأ Firebase في تهيئة الخدمات الأساسية: $e\n$s');
    // يمكن إرسال الخطأ إلى خدمة مراقبة الأخطاء هنا
  } on Exception catch (e, s) {
    debugPrint('❌ خطأ عام في تهيئة الخدمات الأساسية: $e\n$s');
  }
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      // ... الكود الأصلي لطباعة السجلات الملونة ...
    }
  });
}

/// تهيئة الخدمات المحلية
Future<void> _initializeLocalServices() async {
  try {
    await LocalNotificationService.initialize();
    await ConnectivityService.initialize();
    await LocalNotificationService.setupDailyReminders();
    await LocalNotificationService.setupWeeklyReminders();
    debugPrint('✅ تم تهيئة الخدمات المحلية بنجاح');
  } on Exception catch (e) {
    debugPrint('❌ خطأ في تهيئة الخدمات المحلية: $e');
  }
}

class StreamProfitCalculatorApp extends StatelessWidget {
  const StreamProfitCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          // توفير StreamAppProvider للـ Riverpod providers
          streamAppProvider.overrideWithValue(StreamAppProvider()),
        ],
        child: provider.MultiProvider(
          providers: <SingleChildWidget>[
            provider.ChangeNotifierProvider<AuthProvider>(
                create: (_) => AuthProvider()),
            provider.ChangeNotifierProvider<StreamAppProvider>(
              create: (_) {
                final StreamAppProvider appProvider = StreamAppProvider();
                appProvider.initialize();
                return appProvider;
              },
            ),
            // ✅ إضافة AppStateManager لإدارة الحالة المشتركة
            provider.ChangeNotifierProvider<AppStateManager>(
              create: (_) {
                final AppStateManager manager = AppStateManager();
                manager.initialize();
                return manager;
              },
            ),
            // إضافة Providers الفرعية للوصول المباشر
            provider.ChangeNotifierProxyProvider<StreamAppProvider,
                StreamProductProvider>(
              create: (_) => StreamProductProvider(),
              update: (_, StreamAppProvider appProvider,
                      StreamProductProvider? previous) =>
                  appProvider.productProvider,
            ),
            provider.ChangeNotifierProxyProvider<StreamAppProvider,
                StreamInventoryProvider>(
              create: (_) => StreamInventoryProvider(),
              update: (_, StreamAppProvider appProvider,
                      StreamInventoryProvider? previous) =>
                  appProvider.inventoryProvider,
            ),
            // إضافة CartProvider للوصول المباشر
            provider.ChangeNotifierProxyProvider<StreamAppProvider,
                CartProvider>(
              create: (_) => CartProvider(),
              update:
                  (_, StreamAppProvider appProvider, CartProvider? previous) =>
                      appProvider.cartProvider,
            ),
          ],
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable?>[
              LocaleService.instance,
              AppearanceService.instance.fontKeyNotifier
            ]),
            builder: (BuildContext context, _) => AdaptiveTheme(
              light: AppTheme.lightTheme,
              dark: AppTheme.darkTheme,
              initial: AdaptiveThemeMode.system,
              builder: (ThemeData light, ThemeData dark) => MaterialApp(
                title: 'حاسبة الأرباح - Stream Edition',
                theme: light.copyWith(
                  textTheme: AppTheme.localizedTextThemeFor(
                    light.textTheme,
                    LocaleService.instance.locale,
                    fontKey: AppearanceService.instance.fontKeyNotifier.value,
                  ),
                ),
                darkTheme: dark.copyWith(
                  textTheme: AppTheme.localizedTextThemeFor(
                    dark.textTheme,
                    LocaleService.instance.locale,
                    fontKey: AppearanceService.instance.fontKeyNotifier.value,
                  ),
                ),
                builder: (context, child) {
                  final media = MediaQuery.of(context);
                  final clamped = media.textScaler
                      .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.2);
                  return MediaQuery(
                    data: media.copyWith(textScaler: clamped),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  AppLocalizations.delegate,
                ],
                supportedLocales: LocaleService.supportedLocales,
                locale: LocaleService.instance.locale,
                home: const AuthWrapper(),
              ),
            ),
          ),
        ),
      );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch both providers for changes.
    final AuthProvider auth = context.watch<AuthProvider>();
    final StreamAppProvider appProvider = context.watch<StreamAppProvider>();

    // Show a loading screen if auth is processing or the app provider is not ready.
    if (auth.isLoading || !appProvider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تهيئة التطبيق...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // If the user is not authenticated, show the login screen.
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Once authenticated and providers are ready, show the main screen.
    return const StreamProfitCalculatorScreen();
  }
}

class StreamProfitCalculatorScreen extends StatefulWidget {
  const StreamProfitCalculatorScreen({super.key});

  @override
  StreamProfitCalculatorScreenState createState() =>
      StreamProfitCalculatorScreenState();
}

class StreamProfitCalculatorScreenState
    extends State<StreamProfitCalculatorScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // UI State
  late PageController _pageController;
  int _currentIndex = 0;
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

  /// Initialize the app and wait for StreamAppProvider to be ready
  Future<void> _initializeApp() async {
    try {
      // Wait for the next frame to ensure context is available
      await Future<void>.delayed(Duration.zero);

      // Check if context is still valid
      if (!mounted) return;

      // Get the StreamAppProvider from context safely
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // Wait for the provider to be fully initialized with a longer, more flexible timeout
      try {
        await appProvider.initializationComplete
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        debugPrint(
            '⚠️ StreamAppProvider initialization timed out after 20 seconds.');
        if (mounted) {
          // Consider showing a non-blocking warning to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
              'تحذير: استغرق تحميل البيانات وقتاً طويلاً.',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            )),
          );
        }
        // Continue execution even if it times out
      }

      debugPrint('✅ StreamAppProvider initialization considered complete.');

      // Initialize services after provider is ready
      if (mounted) {
        await _initializeServicesIfReady();
      }

      debugPrint('✅ App initialization flow completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during app initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - let the app continue with error handling
    }
  }

  /// تهيئة الخدمات عندما يكون AppProvider جاهز
  Future<void> _initializeServicesIfReady() async {
    if (_servicesInitialized) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final AuthProvider authProvider = context.read<AuthProvider>();

      // التحقق من أن جميع المتطلبات متوفرة قبل التهيئة
      if (appProvider.isInitialized &&
          authProvider.isAuthenticated &&
          authProvider.firebaseUser?.uid != null) {
        debugPrint(
            '🚀 بدء تهيئة الخدمات في الخلفية للمستخدم: ${authProvider.firebaseUser!.uid}');

        // تشغيل تهيئة الخدمات في الخلفية لتجنب تجمد الواجهة
        await _initializeServicesInBackground(
            authProvider.firebaseUser!.uid, appProvider);
      } else {
        debugPrint('⚠️ تخطي تهيئة الخدمات - المتطلبات غير متوفرة');
        debugPrint('  - AppProvider مهيأ: ${appProvider.isInitialized}');
        debugPrint('  - AuthProvider مصادق: ${authProvider.isAuthenticated}');
        debugPrint('  - Firebase User ID: ${authProvider.firebaseUser?.uid}');
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

  /// تهيئة الخدمات في الخلفية
  Future<void> _initializeServicesInBackground(
      String userId, StreamAppProvider appProvider) async {
    try {
      // التحقق من أن الخدمات لم يتم تهيئتها بالفعل
      if (_servicesInitialized) {
        debugPrint('الخدمات مهيأة بالفعل - تخطي التهيئة');
        return;
      }

      // تأخير قصير لضمان عدم تجمد الواجهة
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await _serviceInitializer.initializeServices(userId, appProvider);

      // ✅ إضافة إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي
      try {
        final UnifiedSyncManager syncManager = UnifiedSyncManager();
        final Map<String, dynamic> syncInfo = syncManager.getSyncInfo();

        // التحقق من أن المدير مهيأ مع معرف المستخدم الحقيقي
        if (syncInfo['currentUserId'] != userId ||
            syncInfo['isInitialized'] != true) {
          debugPrint(
              '🔄 إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي: $userId');
          await syncManager.shutdown();
          await syncManager.initialize(userId);
          debugPrint(
              '✅ تم إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي');
        } else {
          debugPrint(
              '✅ UnifiedSyncManager مهيأ بالفعل مع معرف المستخدم الصحيح');
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في إعادة تهيئة UnifiedSyncManager: $e');
        // لا نريد إيقاف العملية الأساسية بسبب فشل إعادة التهيئة
      }

      _servicesInitialized = true;
      debugPrint('✅ تم تهيئة الخدمات في الخلفية بنجاح');
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة الخدمات في الخلفية: $e');
      debugPrint('Stack trace: $stackTrace');

      // إعادة المحاولة بعد تأخير أطول
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted && !_servicesInitialized) {
          _initializeServicesInBackground(userId, appProvider);
        }
      });
    }
  }

  /// معالج النقر على التبويبات
  void _onTabTapped(int index) {
    if (_pageController.hasClients && _currentIndex != index) {
      // Save to PageStorage
      PageStorage.of(context)
          .writeState(context, index, identifier: _kCurrentIndexKey);

      // تحديث الفهرس فوراً لتجنب التأخير
      setState(() {
        _currentIndex = index;
      });

      // تحريك الصفحة في الخلفية
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// عرض حوار تأكيد الخروج
  Future<bool> _showExitDialog() async {
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            AppLocalizations.of(context).confirm,
            style: TextStyle(fontSize: context.responsiveFontSize(18)),
          ),
          content: Text(
            AppLocalizations.of(context).exitAppQuestion,
            style: TextStyle(fontSize: context.responsiveFontSize(16)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context).no,
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context).yes,
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('خطأ في عرض حوار الخروج: $e');
      // في حالة الخطأ، اسمح بالخروج
      return true;
    }
  }

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
          child: _buildResponsiveLayout(context),
        ),
      ),
    );
  }

  /// بناء التخطيط المتجاوب
  Widget _buildResponsiveLayout(BuildContext context) => context.isSmallScreen
      ? _buildMobileLayout(context)
      : _buildDesktopLayout(context);

  /// بناء تخطيط الموبايل
  Widget _buildMobileLayout(BuildContext context) => Scaffold(
        appBar: _buildMobileAppBar(context),
        body: _buildBody(context),
        bottomNavigationBar: ResponsiveNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      );

  /// بناء شريط التطبيق للموبايل
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) => AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calculate,
                  color: Colors.white, size: context.isSmallScreen ? 18 : 20),
            ),
            SizedBox(width: context.responsiveSpacing * 0.8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).appTitle,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  provider.Consumer<StreamAppProvider>(
                    builder: (BuildContext context,
                        StreamAppProvider appProvider, Widget? child) {
                      try {
                        // التحقق من أن Provider مهيأ ومتاح
                        if (!appProvider.isInitialized ||
                            appProvider.isLoading) {
                          return Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(12),
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          );
                        }

                        final Map<String, dynamic> stats =
                            appProvider.getQuickStats();
                        return Text(
                          '${stats['productCount']} منتج • ${stats['inventoryCount']} مخزون',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        );
                      } catch (e) {
                        debugPrint('خطأ في عرض الإحصائيات: $e');
                        return Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: _buildMobileAppBarActions(context),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      );

  /// بناء أزرار شريط التطبيق للموبايل
  List<Widget> _buildMobileAppBarActions(BuildContext context) => <Widget>[
        // ✅ مؤشر المزامنة
        Container(
          margin: EdgeInsets.only(
              right: context.responsiveSpacing * 0.4,
              top: context.responsiveSpacing * 0.5,
              bottom: context.responsiveSpacing * 0.5),
          child: const InteractiveSyncIndicator(),
        ),
        // زر الإعدادات
        Container(
          margin: EdgeInsets.only(
              right: context.responsiveSpacing * 0.4,
              top: context.responsiveSpacing * 0.5,
              bottom: context.responsiveSpacing * 0.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: provider.Consumer<AuthProvider>(
            builder: (BuildContext context, AuthProvider auth, _) => IconButton(
              onPressed: auth.isAdmin
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const SettingsTabRiverpod(), // Riverpod version
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.settings, color: Colors.white, size: 18),
              tooltip: AppLocalizations.of(context).settings,
              splashRadius: 16,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        // أيقونة التنبيهات مع شارة
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: AlertBadge(
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const AlertsTabRiverpod(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications,
                  color: Colors.white, size: 18),
              tooltip: AppLocalizations.of(context).notifications,
              splashRadius: 16,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ];

  /// بناء تخطيط سطح المكتب
  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
        body: Row(
          children: <Widget>[
            ResponsiveNavigation(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  _buildDesktopAppBar(context),
                  Expanded(child: _buildBody(context)),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء شريط التطبيق لسطح المكتب
  Widget _buildDesktopAppBar(BuildContext context) => Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: context.responsiveSpacing),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppConstants.primaryColor,
              AppConstants.primaryColor.withValues(alpha: 0.9),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: Row(
          children: <Widget>[
            // شعار التطبيق
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calculate,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // عنوان التطبيق مع تأثير
            ShaderMask(
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Colors.white, Colors.white70],
              ).createShader(bounds),
              child: ResponsiveText(
                AppLocalizations.of(context).appTitle,
                fontSize: AppConstants.titleFontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // إحصائيات سريعة
            _buildQuickStats(context),
            const SizedBox(width: 20),
            ..._buildAppBarActions(context),
          ],
        ),
      );

  /// بناء إحصائيات سريعة
  Widget _buildQuickStats(BuildContext context) =>
      provider.Consumer<StreamAppProvider>(
        builder: (BuildContext context, StreamAppProvider appProvider,
            Widget? child) {
          try {
            // التحقق من أن Provider مهيأ ومتاح
            if (!appProvider.isInitialized || appProvider.isLoading) {
              return Row(
                children: <Widget>[
                  _buildStatItem(
                    context: context,
                    icon: Icons.inventory,
                    value: '...',
                    label: 'منتج',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context: context,
                    icon: Icons.storage,
                    value: '...',
                    label: 'مخزون',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context: context,
                    icon: Icons.trending_up,
                    value: '...',
                    label: 'قيمة',
                    color: Colors.orange,
                  ),
                ],
              );
            }

            final Map<String, dynamic> stats = appProvider.getQuickStats();
            return Row(
              children: <Widget>[
                _buildStatItem(
                  context: context,
                  icon: Icons.inventory,
                  value: stats['productCount'].toString(),
                  label: 'منتج',
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context: context,
                  icon: Icons.storage,
                  value: stats['inventoryCount'].toString(),
                  label: 'مخزون',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context: context,
                  icon: Icons.trending_up,
                  value: CurrencyFormatter.formatCurrencyNoDecimals(
                      (stats['totalValue'] as double) / 100, context),
                  label: 'قيمة',
                  color: Colors.orange,
                ),
              ],
            );
          } catch (e) {
            debugPrint('خطأ في عرض الإحصائيات السريعة: $e');
            return Row(
              children: <Widget>[
                _buildStatItem(
                  context: context,
                  icon: Icons.inventory,
                  value: '...',
                  label: 'منتج',
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context: context,
                  icon: Icons.storage,
                  value: '...',
                  label: 'مخزون',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context: context,
                  icon: Icons.trending_up,
                  value: '...',
                  label: 'قيمة',
                  color: Colors.orange,
                ),
              ],
            );
          }
        },
      );

  /// بناء عنصر إحصائية
  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// بناء أزرار شريط التطبيق
  List<Widget> _buildAppBarActions(BuildContext context) => <Widget>[
        // ✅ مؤشر المزامنة
        const InteractiveSyncIndicator(),
        const SizedBox(width: 6),
        // زر الإعدادات
        provider.Consumer<AuthProvider>(
          builder: (BuildContext context, AuthProvider auth, _) =>
              _buildActionButton(
            context: context,
            icon: Icons.settings,
            tooltip: AppLocalizations.of(context).settings,
            onPressed: auth.isAdmin
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const SettingsTabRiverpod(), // Riverpod version
                      ),
                    );
                  }
                : null,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            iconSize: 20,
          ),
        ),
        const SizedBox(width: 6),
        // أيقونة التنبيهات مع شارة
        AlertBadge(
          child: _buildActionButton(
            context: context,
            icon: Icons.notifications,
            tooltip: AppLocalizations.of(context).notifications,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AlertsTabRiverpod(),
                ),
              );
            },
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            iconSize: 20,
          ),
        ),
      ];

  /// بناء زر إجراء
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
    required Color backgroundColor,
    double iconSize = 24,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: iconSize),
          tooltip: tooltip,
          splashRadius: 20,
        ),
      );

  /// بناء المحتوى الرئيسي
  Widget _buildBody(BuildContext context) {
    try {
      // Use FutureBuilder to prevent race conditions
      return FutureBuilder<void>(
        future:
            _initializationFuture ?? (_initializationFuture = _initializeApp()),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          // Show loading screen while initialization is in progress
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const custom_widgets.LoadingWidget(
              message: 'جاري تهيئة التطبيق...',
            );
          }

          // Handle initialization errors
          if (snapshot.hasError) {
            debugPrint('خطأ في تهيئة التطبيق: ${snapshot.error}');
            return custom_widgets.ErrorWidget(
              message: 'خطأ في تهيئة التطبيق: ${snapshot.error}',
              onRetry: () {
                if (mounted) {
                  setState(() {
                    _initializationFuture = _initializeApp();
                  });
                }
              },
            );
          }

          // Initialization completed successfully, now build the main content
          return provider.Consumer<StreamAppProvider>(
            builder: (BuildContext context, StreamAppProvider appProvider,
                Widget? child) {
              try {
                // التحقق من أن Provider مهيأ ومتاح
                if (!appProvider.isInitialized || appProvider.isLoading) {
                  return const custom_widgets.LoadingWidget(
                    message: 'جاري تهيئة التطبيق...',
                  );
                }

                final StreamProductProvider streamProductProvider =
                    appProvider.productProvider;
                final StreamInventoryProvider streamInventoryProvider =
                    appProvider.inventoryProvider;

                // عرض شاشة التحميل إذا كانت البيانات لا تزال تحمل (مع timeout)
                if (streamProductProvider.isLoading &&
                    streamInventoryProvider.isLoading) {
                  return const custom_widgets.LoadingWidget(
                    message: 'جاري تحميل البيانات...',
                  );
                }

                // إذا فشل تحميل البيانات، اعرض التطبيق مع رسالة تحذير
                if (streamProductProvider.errorMessage != null &&
                    streamInventoryProvider.errorMessage != null) {
                  return Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تحذير: فشل في تحميل بعض البيانات. التطبيق يعمل في وضع محدود.',
                                style: TextStyle(color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildMainContent(context, appProvider)),
                    ],
                  );
                }

                // عرض الأخطاء إذا وجدت
                if (streamProductProvider.errorMessage != null ||
                    streamInventoryProvider.errorMessage != null) {
                  return custom_widgets.ErrorWidget(
                    message: streamProductProvider.errorMessage ??
                        streamInventoryProvider.errorMessage ??
                        'خطأ غير معروف',
                    onRetry: () => appProvider.refreshAll(),
                  );
                }

                return _buildMainContent(context, appProvider);
              } catch (e) {
                debugPrint('خطأ في Consumer: $e');
                return custom_widgets.ErrorWidget(
                  message: 'خطأ في تحميل البيانات: $e',
                  onRetry: () {
                    if (mounted) {
                      context.read<StreamAppProvider>().refreshAll();
                    }
                  },
                );
              }
            },
          );
        },
      );
    } catch (e) {
      debugPrint('خطأ في بناء المحتوى الرئيسي: $e');
      return custom_widgets.ErrorWidget(
        message: 'خطأ في تحميل المحتوى: $e',
        onRetry: () {
          if (mounted) {
            context.read<StreamAppProvider>().refreshAll();
          }
        },
      );
    }
  }

  /// بناء المحتوى الرئيسي للتطبيق
  Widget _buildMainContent(
      BuildContext context, StreamAppProvider appProvider) {
    try {
      // التحقق من أن Provider مهيأ ومتاح
      if (!appProvider.isInitialized || appProvider.isLoading) {
        return const custom_widgets.LoadingWidget(
          message: 'جاري تهيئة التطبيق...',
        );
      }

      final StreamInventoryProvider streamInventoryProvider =
          appProvider.inventoryProvider;

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            ResponsiveContentContainer(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight > 0
                ? constraints.maxHeight
                : double.infinity,
          ),
          isScrollable: false,
          child: SizedBox(
            height: constraints.maxHeight > 0 ? constraints.maxHeight : null,
            child: PageView(
              key: const PageStorageKey<String>('main_page_view'),
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              allowImplicitScrolling: true,
              onPageChanged: (int index) {
                if (mounted && _currentIndex != index) {
                  // Save to PageStorage
                  PageStorage.of(context).writeState(context, index,
                      identifier: _kCurrentIndexKey);

                  setState(() {
                    _currentIndex = index;
                    // مسح الباركود المعلق بعد الوصول لتبويب الإضافة
                    if (index == 1 && _pendingScannedBarcode != null) {
                      // يستهلك مرة واحدة
                      _pendingScannedBarcode = null;
                    }
                  });
                }
              },
              children: <Widget>[
                TabErrorOverlay(
                  tabName: 'dashboard',
                  childBuilder: (BuildContext ctx) =>
                      RiverpodProviderWrapper.wrapWithRiverpod(
                    appProvider: context.read<StreamAppProvider>(),
                    context: ctx,
                    child: DashboardTabRiverpod(
                      onNavigateToTab: _onTabTapped,
                    ),
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'add_product',
                  childBuilder: (BuildContext ctx) =>
                      provider.Consumer<StreamAppProvider>(
                    builder: (BuildContext context,
                        StreamAppProvider appProvider, Widget? child) {
                      return RiverpodProviderWrapper.wrapWithRiverpod(
                        appProvider: appProvider,
                        context: context,
                        child: AddProductTabRiverpod(
                          inventoryItems:
                              streamInventoryProvider.inventoryItems,
                          onProductAdded: () {},
                          scannedBarcode: _pendingScannedBarcode,
                        ),
                      );
                    },
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'inventory',
                  childBuilder: (BuildContext ctx) =>
                      provider.Consumer<StreamAppProvider>(
                    builder: (BuildContext context,
                        StreamAppProvider appProvider, Widget? child) {
                      // التحقق من أن Provider مهيأ قبل عرض تبويب المخزون
                      if (!appProvider.isInitialized || appProvider.isLoading) {
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

                      // استخدام النسخة الجديدة مع Riverpod
                      debugPrint('✅ Using InventoryTabRiverpod');
                      return RiverpodProviderWrapper.wrapWithRiverpod(
                        appProvider: appProvider,
                        context: context,
                        child: InventoryTabRiverpod(
                          onInventoryUpdated: () {
                            // لا نحتاج لإعادة تحميل البيانات
                            // لأن التحديثات تتم محلياً بالفعل
                            debugPrint(
                                'تم تحديث المخزون - لا حاجة لإعادة التحميل');
                          },
                        ),
                      );
                    },
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'product_list',
                  childBuilder: (BuildContext ctx) =>
                      RiverpodProviderWrapper.wrapWithRiverpod(
                    appProvider: context.read<StreamAppProvider>(),
                    context: ctx,
                    child: const ProductListTabRiverpod(),
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'reports',
                  childBuilder: (BuildContext ctx) =>
                      provider.Consumer<AuthProvider>(
                    builder: (BuildContext context, AuthProvider auth, _) =>
                        auth.isAdmin
                            ? const EnhancedPOSReportsScreenRiverpod()
                            : const Center(
                                child:
                                    Text('غير مسموح بعرض التقارير إلا للمدير')),
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'pos',
                  childBuilder: (BuildContext ctx) => Platform.isWindows
                      ? const WindowsPOSScreen()
                      : RiverpodProviderWrapper.wrapWithRiverpod(
                          appProvider: context.read<StreamAppProvider>(),
                          context: ctx,
                          child: const POSTabRiverpod(),
                        ),
                ),
                TabErrorOverlay(
                  tabName: 'store_display',
                  childBuilder: (BuildContext ctx) =>
                      RiverpodProviderWrapper.wrapWithRiverpod(
                    appProvider: context.read<StreamAppProvider>(),
                    context: ctx,
                    child: StoreDisplayTabRiverpod(
                      onNavigateToAddProduct: () =>
                          _pageController.animateToPage(2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut),
                    ),
                  ),
                ),
                TabErrorOverlay(
                  tabName: 'realtime_settings',
                  childBuilder: (BuildContext ctx) => RealtimeSettingsTab(),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('خطأ في بناء المحتوى الرئيسي: $e');
      return custom_widgets.ErrorWidget(
        message: 'خطأ في تحميل المحتوى: $e',
        onRetry: () {
          if (mounted) {
            context.read<StreamAppProvider>().refreshAll();
          }
        },
      );
    }
  }
}
