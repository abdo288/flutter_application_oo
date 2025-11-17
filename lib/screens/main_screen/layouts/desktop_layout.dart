import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_riverpod_providers.dart';
import '../../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../../reports_system/screens/main_reports_screen.dart';
import '../../../screens/add_product/quick_sell_tab_riverpod.dart';
import '../../../screens/dashboard_tab_riverpod.dart';
import '../../../screens/inventory_tab_riverpod.dart';
import '../../../screens/pos_tab_riverpod.dart';
import '../../../screens/realtime_settings_tab_riverpod.dart';
import '../../../screens/sales_history_tab_riverpod.dart';
import '../../../screens/store_display/store_display_tab_riverpod.dart';
import '../../../screens/windows_pos_screen.dart';
import '../../../widgets/loading_widget.dart' as custom_widgets;
import '../../../widgets/responsive_navigation.dart';
import '../../../widgets/tab_error_overlay.dart';
import '../widgets/desktop_app_bar.dart';

class DesktopLayout extends ConsumerWidget {
  const DesktopLayout({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
    required this.onPageChanged,
    required this.pageController,
    this.pendingScannedBarcode,
    this.initializationFuture,
  });

  final int currentIndex;
  final void Function(int) onTabTapped;
  final void Function(int) onPageChanged;
  final PageController pageController;
  final String? pendingScannedBarcode;
  final Future<void>? initializationFuture;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Row(
          children: <Widget>[
            ResponsiveNavigation(
              currentIndex: currentIndex,
              onTap: onTabTapped,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  DesktopAppBar(
                    currentIndex: currentIndex,
                    onTabTapped: onTabTapped,
                  ),
                  Expanded(child: _buildBody(context)),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء المحتوى الرئيسي
  Widget _buildBody(BuildContext context) {
    try {
      // استخدام Consumer مباشرة بدلاً من FutureBuilder لتجنب إعادة البناء عند تغيير حجم الشاشة
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          try {
            final AppState appState = ref.watch(appControllerProvider);

            // عرض شاشة التحميل فقط إذا كانت البيانات لا تزال تحمل ولم تكتمل التهيئة بعد
            if (appState.isLoading && !appState.isInitialized) {
              return const custom_widgets.LoadingWidget(
                message: 'جاري تحميل البيانات...',
              );
            }

            // إذا فشل تحميل البيانات، اعرض التطبيق مع رسالة تحذير
            if (appState.errorMessage != null) {
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
                            'تحذير: فشل في تحميل بعض البيانات. التطبيق يعمل في وضع محدود.\nيمكنك الضغط على "إعادة المحاولة" أو الاستمرار في استخدام التطبيق.',
                            style: TextStyle(
                                color: Colors.orange[800], fontSize: 14),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            ref
                                .read(appControllerProvider.notifier)
                                .clearError();
                            await ref
                                .read(appControllerProvider.notifier)
                                .refreshAll();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('إعادة المحاولة'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            backgroundColor:
                                Colors.orange.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildMainContent(context)),
                ],
              );
            }

            // بناء المحتوى الرئيسي
            return _buildMainContent(context);
          } catch (e) {
            debugPrint('خطأ في Consumer: $e');
            return custom_widgets.ErrorWidget(
              message: 'خطأ في تحميل البيانات: $e',
              onRetry: () {
                ref.read(appControllerProvider.notifier).refreshAll();
              },
            );
          }
        },
      );
    } catch (e) {
      debugPrint('خطأ في بناء المحتوى الرئيسي: $e');
      return custom_widgets.ErrorWidget(
        message: 'خطأ في تحميل المحتوى: $e',
        onRetry: () {
          // إعادة تحميل الصفحة
          Navigator.of(context).pushReplacementNamed('/');
        },
      );
    }
  }

  /// بناء المحتوى الرئيسي للتطبيق
  Widget _buildMainContent(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            ResponsiveContentContainer(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight > 0
                ? constraints.maxHeight
                : double.infinity,
          ),
          isScrollable: false,
          child: PageStorage(
            bucket: PageStorageBucket(),
            child: SizedBox(
              height: constraints.maxHeight > 0 ? constraints.maxHeight : null,
              child: PageView(
                key: const PageStorageKey<String>('main_page_view'),
                controller: pageController,
                physics: Platform.isWindows
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                // إضافة debug logging لتتبع تغيير الصفحات
                onPageChanged: (int index) {
                  debugPrint('🖥️ Desktop Layout - Page changed to: $index');
                  onPageChanged(index);
                },
                children: <Widget>[
                  TabErrorOverlay(
                    tabName: 'dashboard',
                    // Index 0
                    childBuilder: (BuildContext ctx) => DashboardTabRiverpod(
                      onNavigateToTab: onTabTapped,
                    ),
                  ),
                  TabErrorOverlay(
                    tabName: 'quick_sell',
                    // Index 1
                    childBuilder: (BuildContext ctx) => QuickSellTabRiverpod(
                      onProductAdded: () {},
                      scannedBarcode: pendingScannedBarcode,
                    ),
                  ),
                  TabErrorOverlay(
                    tabName: 'product_form',
                    // Index 2 - نموذج المنتج
                    childBuilder: (BuildContext ctx) => Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) {
                        final AppState appState =
                            ref.watch(appControllerProvider);

                        // إزالة الفحص المزدوج - FutureBuilder يتولى إدارة التهيئة الأولية
                        // فقط نعرض تحذير إذا كان هناك خطأ في التهيئة
                        if (appState.errorMessage != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(Icons.warning,
                                    color: Colors.orange, size: 48),
                                const SizedBox(height: 16),
                                Text('تحذير: ${appState.errorMessage}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(appControllerProvider.notifier)
                                        .clearError();
                                  },
                                  child: const Text('إخفاء التحذير'),
                                ),
                              ],
                            ),
                          );
                        }

                        // استخدام النسخة الجديدة مع Riverpod
                        debugPrint('✅ Using ProductFormTabRiverpod');
                        return ProductFormTabRiverpod(
                          onInventoryUpdated: () {
                            // لا نحتاج لإعادة تحميل البيانات
                            // لأن التحديثات تتم محلياً بالفعل
                            debugPrint(
                                'تم تحديث المخزون - لا حاجة لإعادة التحميل');
                          },
                        );
                      },
                    ),
                  ),
                  TabErrorOverlay(
                    tabName: 'sales_history',
                    // Index 3
                    childBuilder: (BuildContext ctx) =>
                        const SalesHistoryTabRiverpod(),
                  ),
                  TabErrorOverlay(
                    tabName: 'reports',
                    // Index 4 - Reports Tab
                    childBuilder: (BuildContext ctx) => Consumer(
                      builder:
                          (BuildContext context, WidgetRef consumerRef, _) {
                        final bool isAdmin = consumerRef.watch(isAdminProvider);
                        return isAdmin
                            ? const MainReportsScreen()
                            : const Center(
                                child:
                                    Text('غير مسموح بعرض التقارير إلا للمدير'));
                      },
                    ),
                  ),
                  TabErrorOverlay(
                    tabName: 'pos',
                    // Index 5
                    childBuilder: (BuildContext ctx) {
                      // إضافة debug logging لتتبع بناء تبويب نقطة البيع
                      debugPrint(
                          '🏪 Building POS tab at index 5 (Desktop Layout)');
                      debugPrint(
                          '🏪 Platform.isWindows: ${Platform.isWindows}');

                      return Platform.isWindows
                          ? const WindowsPOSScreen()
                          : const POSTabRiverpod();
                    },
                  ),
                  TabErrorOverlay(
                    tabName: 'inventory',
                    // Index 6 - المخزون (عرض قائمة المخزون)
                    childBuilder: (BuildContext ctx) => InventoryDisplayTabRiverpod(
                      onNavigateToQuickSell: () =>
                          pageController.animateToPage(1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut),
                    ),
                  ),
                  TabErrorOverlay(
                    tabName: 'realtime_settings',
                    // Index 7
                    childBuilder: (BuildContext ctx) =>
                        const RealtimeSettingsTabRiverpod(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('خطأ في بناء المحتوى الرئيسي: $e');
      return custom_widgets.ErrorWidget(
        message: 'خطأ في تحميل المحتوى: $e',
        onRetry: () {
          // إعادة تحميل الصفحة
          Navigator.of(context).pushReplacementNamed('/');
        },
      );
    }
  }
}
