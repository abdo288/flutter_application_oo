import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_riverpod_providers.dart';
import '../providers/realtime_update_manager.dart';
import '../services/dashboard_service.dart';
import '../services/error_handler_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/modern_dashboard_stat_card.dart';
import '../widgets/modern_product_profit_card.dart';
import '../widgets/modern_profit_chart.dart';
import '../widgets/modern_quick_action_button.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/success_feedback_widget.dart';

/// A completely redesigned, modern, and interactive dashboard using Riverpod.
class DashboardTabRiverpod extends ConsumerStatefulWidget {
  const DashboardTabRiverpod({super.key, required this.onNavigateToTab});
  final void Function(int) onNavigateToTab;

  @override
  ConsumerState<DashboardTabRiverpod> createState() =>
      _DashboardTabRiverpodState();
}

class _DashboardTabRiverpodState extends ConsumerState<DashboardTabRiverpod>
    with TickerProviderStateMixin {
  // متغيرات التحسينات الجديدة
  Timer? _searchDebounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // متغيرات الاتجاهات
  Map<String, double> _trends = <String, double>{
    'totalProfitTrend': 0.0,
    'productsValueTrend': 0.0,
    'todayTrend': 0.0,
    'monthlyTrend': 0.0,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Riverpod providers تقوم بتحديث الواجهات تلقائياً عند تغير البيانات
    debugPrint('ℹ️ DashboardTabRiverpod يستخدم Riverpod للتحديث التلقائي');
  }

  @override
  void initState() {
    super.initState();

    // تهيئة Animation Controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // تأجيل تحميل البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      // استخدام Riverpod refresh
      final DashboardRefreshNotifier refreshNotifier =
          ref.read(dashboardRefreshNotifierProvider);
      await refreshNotifier.refreshDashboard();
      
      // حساب الاتجاهات بعد تحميل البيانات
      await _calculateTrends();
    } catch (e) {
      if (mounted) {
        await ErrorHelper.safeExecute(
          () async {
            // إعادة المحاولة في حالة الفشل
            final DashboardRefreshNotifier refreshNotifier =
                ref.read(dashboardRefreshNotifierProvider);
            await refreshNotifier.refreshDashboard();
            await _calculateTrends();
          },
          userAction: 'تحميل بيانات لوحة التحكم',
          showUserMessage: (String message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: AppConstants.errorColor,
                ),
              );
            }
          },
        );
      }
    }
  }

  /// حساب الاتجاهات من البيانات التاريخية
  Future<void> _calculateTrends() async {
    try {
      final AsyncValue<DashboardStats> dashboardStatsAsync =
          ref.read(dashboardStatsProvider);
      
      await dashboardStatsAsync.when(
        data: (DashboardStats stats) async {
          final Map<String, double> trends =
              await DashboardService.calculateTrends(
            currentTotalProfit: stats.totalProfit,
            currentProductsValue: stats.totalProductsValue,
            currentTodaySales: stats.todaySales,
            currentMonthlySales: stats.monthlySales,
          );
          
          if (mounted) {
            setState(() {
              _trends = trends;
            });
          }
        },
        loading: () async {},
        error: (Object error, StackTrace? stackTrace) async {},
      );
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب الاتجاهات: $e');
    }
  }

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      // إعادة تحميل بيانات Dashboard
      await _loadDashboardData();

      // إعادة تشغيل الـ animations
      _fadeController.forward();
      _slideController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackbar(
            message: 'تم تحديث لوحة التحكم بنجاح',
            icon: Icons.refresh_rounded,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ في التحديث: $e')),
              ],
            ),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch dashboard stats
    final AsyncValue<DashboardStats> dashboardStatsAsync =
        ref.watch(dashboardStatsProvider);
    final AsyncValue<List<Map<String, dynamic>>> topProductsAsync =
        ref.watch(topProductsProvider);
    final bool isLoading = ref.watch(dashboardLoadingProvider);
    final String? error = ref.watch(dashboardErrorProvider);

    // Watch realtime updates status
    final bool isConnected = ref.watch(isConnectedProvider);
    final DateTime? lastUpdateTime = ref.watch(lastUpdateTimeProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: <Widget>[
          _buildBody(dashboardStatsAsync, topProductsAsync, isLoading, error),
          // مؤشر التحديثات الفورية
          if (isConnected && lastUpdateTime != null)
            Positioned(
              top: 60,
              right: 16,
              child: _buildRealtimeIndicator(lastUpdateTime),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<DashboardStats> dashboardStatsAsync,
    AsyncValue<List<Map<String, dynamic>>> topProductsAsync,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return _buildShimmerLoading(context);
    }

    if (error != null) {
      return ErrorStateWidget(
        message: error,
        onRetry: () {
          ref.read(dashboardRefreshNotifierProvider).refreshDashboard();
        },
        title: 'خطأ في تحميل لوحة التحكم',
      );
    }

    return dashboardStatsAsync.when(
      data: (DashboardStats stats) => AdvancedRefreshIndicator(
        onRefresh: _onRefresh,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: context.responsiveScrollPhysics,
              slivers: <Widget>[
                _buildSliverAppBar(context),
                _buildQuickActions(context),
                _buildStatsGrid(context, stats),
                _buildProfitChart(context, stats),
                _buildTopProducts(context, topProductsAsync),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
      loading: () => _buildShimmerLoading(context),
      error: (Object error, StackTrace? stackTrace) => ErrorStateWidget(
        message: error.toString(),
        onRetry: () {
          ref.invalidate(dashboardStatsProvider);
        },
        title: 'خطأ في تحميل لوحة التحكم',
      ),
    );
  }

  /// بناء مؤشر التحديثات الفورية
  Widget _buildRealtimeIndicator(DateTime lastUpdateTime) {
    final Duration timeSinceUpdate = DateTime.now().difference(lastUpdateTime);
    final String timeText = timeSinceUpdate.inSeconds < 60
        ? 'منذ ${timeSinceUpdate.inSeconds} ثانية'
        : 'منذ ${timeSinceUpdate.inMinutes} دقيقة';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'محدث $timeText',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer loading for dashboard
  Widget _buildShimmerLoading(BuildContext context) => CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: <Widget>[
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: context.responsivePadding,
              child: Column(
                children: <Widget>[
                  // Quick actions shimmer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      3,
                      (int index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: const ShimmerCard(
                            height: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  // Stats grid shimmer
                  GridView.count(
                    crossAxisCount: context.isSmallScreen ? 2 : 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: context.responsiveSpacing * 0.8,
                    crossAxisSpacing: context.responsiveSpacing * 0.8,
                    childAspectRatio: context.isSmallScreen ? 1.2 : 1.4,
                    children: List.generate(
                      4,
                      (int index) => const ShimmerCard(),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  // Chart shimmer
                  const ShimmerCard(height: 300),
                ],
              ),
            ),
          ),
        ],
      );

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        centerTitle: false,
        title: Text(
          l10n.dashboard,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: context.responsiveFontSize(18)),
        ),
        background: Container(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
            gradient: LinearGradient(
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 40),
            child: Text(
              l10n.dashboardWelcome,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: context.responsiveFontSize(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: context.responsivePadding,
        child: context.shouldUseVerticalLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ModernQuickActionButton(
                    icon: Icons.add_shopping_cart,
                    label: 'عملية بيع جديدة',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(1);
                    },
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  ModernQuickActionButton(
                    icon: Icons.inventory,
                    label: 'نموذج المنتج',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(2);
                    },
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  ModernQuickActionButton(
                    icon: Icons.add,
                    label: 'البيع السريع',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(1);
                    },
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ModernQuickActionButton(
                    icon: Icons.add_shopping_cart,
                    label: 'عملية بيع جديدة',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(1);
                    },
                  ),
                  ModernQuickActionButton(
                    icon: Icons.point_of_sale,
                    label: l10n.pointOfSale,
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(6);
                    },
                  ),
                  ModernQuickActionButton(
                    icon: Icons.inventory,
                    label: 'نموذج المنتج',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(2);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // استخدام الاتجاهات المحسوبة من البيانات التاريخية
    final double totalProfitTrend = _trends['totalProfitTrend'] ?? 0.0;
    final double productsValueTrend = _trends['productsValueTrend'] ?? 0.0;
    final double todayTrend = _trends['todayTrend'] ?? 0.0;
    final double monthlyTrend = _trends['monthlyTrend'] ?? 0.0;

    return SliverPadding(
      padding: context.responsivePadding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: context.isSmallScreen ? 200.0 : 280.0,
          mainAxisSpacing: context.responsiveSpacing * 1.0,
          crossAxisSpacing: context.responsiveSpacing * 1.0,
          childAspectRatio: context.isSmallScreen ? 1.0 : 1.1,
        ),
        delegate: SliverChildListDelegate(
          <Widget>[
            ModernDashboardStatCard(
              title: l10n.totalProfitTitle,
              value:
                  CurrencyFormatter.formatCurrency(stats.totalProfit, context),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF22C55E),
              trend: totalProfitTrend > 0 ? 'up' : null,
              trendValue: totalProfitTrend,
            ),
            ModernDashboardStatCard(
              title: l10n.totalProductsValue,
              value: CurrencyFormatter.formatCurrency(
                  stats.totalProductsValue, context),
              icon: Icons.attach_money_rounded,
              color: const Color(0xFF2563EB),
              trend: productsValueTrend > 0 ? 'up' : null,
              trendValue: productsValueTrend,
              delay: const Duration(milliseconds: 100),
            ),
            ModernDashboardStatCard(
              title: l10n.todaySales,
              value: stats.todaySales.toString(),
              icon: Icons.today_rounded,
              color: const Color(0xFF8B5CF6),
              trend: todayTrend > 0 ? 'up' : null,
              trendValue: todayTrend,
              delay: const Duration(milliseconds: 200),
            ),
            ModernDashboardStatCard(
              title: l10n.monthlySales,
              value: stats.monthlySales.toString(),
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFF59E0B),
              trend: monthlyTrend > 0 ? 'up' : null,
              trendValue: monthlyTrend,
              delay: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitChart(BuildContext context, DashboardStats stats) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // تحويل البيانات إلى التنسيق المطلوب
    final List<Map<String, dynamic>> profitData = stats.profitHistory
        .map((ProfitData profitData) => <String, Object>{
              'date': profitData.formattedDate,
              'profit': profitData.profit,
            })
        .toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: context.responsivePadding,
        child: ModernProfitChart(
          title: l10n.profitLast30Days,
          profitHistory: profitData,
          height: context.isSmallScreen ? 250 : 300,
        ),
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> topProductsAsync) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.topProfitableProducts,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(18),
                color: AppConstants.textColor,
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.8),
            topProductsAsync.when(
              data: (List<Map<String, dynamic>> topProducts) {
                if (topProducts.isEmpty) {
                  return Padding(
                    padding: context.responsivePadding,
                    child: Center(child: Text(l10n.noData)),
                  );
                }
                return Column(
                  children: topProducts
                      .asMap()
                      .entries
                      .map((MapEntry<int, Map<String, dynamic>> entry) {
                    final int idx = entry.key;
                    final Map<String, dynamic> product = entry.value;

                    // معالجة آمنة للبيانات
                    final String productName =
                        product['name']?.toString() ?? 'منتج غير معروف';
                    final double profit =
                        (product['profit'] as num?)?.toDouble() ?? 0.0;
                    final double profitPercentage =
                        (product['profitPercentage'] as num?)?.toDouble() ??
                            0.0;

                    return ModernProductProfitCard(
                      rank: idx + 1,
                      productName: productName,
                      profit: profit,
                      profitPercentage: profitPercentage,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace? stackTrace) => Center(
                child: Text('خطأ في تحميل المنتجات: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
