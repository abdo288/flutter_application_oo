import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/dashboard_stats.dart';
import '../providers/stream_app_provider.dart';
import '../services/dashboard_service.dart';
import '../services/error_handler_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/success_feedback_widget.dart';
import '../widgets/modern_dashboard_stat_card.dart';
import '../widgets/modern_product_profit_card.dart';
import '../widgets/modern_quick_action_button.dart';
import '../widgets/modern_profit_chart.dart';

/// A completely redesigned, modern, and interactive dashboard.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onNavigateToTab});
  final void Function(int) onNavigateToTab;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  Future<DashboardStats>? _statsFuture;
  List<Map<String, dynamic>> _topProducts = <Map<String, dynamic>>[];

  // متغيرات التحسينات الجديدة
  Timer? _searchDebounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // StreamProviders تقوم بتحديث الواجهات تلقائياً عند تغير البيانات
    // لا نحتاج إلى الاستماع لأحداث معقدة
    debugPrint('ℹ️ DashboardTab يستخدم StreamProviders للتحديث التلقائي');
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
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();

    setState(() {
      _statsFuture = DashboardService.calculateDashboardStatsStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
      );
      _statsFuture?.then((DashboardStats stats) async {
        if (!mounted) return; // Check if widget is still mounted

        await ErrorHelper.safeExecute(
          () async {
            final List<Map<String, dynamic>> topProducts =
                await DashboardService.getTopProfitableProductsStatic(
              productProvider: appProvider.productProvider,
              inventoryProvider: appProvider.inventoryProvider,
              limit: 3,
            );
            if (mounted) {
              setState(() {
                _topProducts = topProducts;
              });
            }
          },
          userAction: 'تحميل بيانات لوحة التحكم',
          showUserMessage: (String message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
        );
      });
    });
  }

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      await appProvider.refreshAll();

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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: _statsFuture == null
            ? _buildShimmerLoading(context)
            : FutureBuilder<DashboardStats>(
                future: _statsFuture!,
                builder: (BuildContext context,
                    AsyncSnapshot<DashboardStats> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading(context);
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return ErrorStateWidget(
                      message: snapshot.error?.toString() ??
                          AppLocalizations.of(context).dataLoadingError(''),
                      onRetry: _loadDashboardData,
                      title: 'خطأ في تحميل لوحة التحكم',
                    );
                  }

                  final DashboardStats stats = snapshot.data!;
                  return AdvancedRefreshIndicator(
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
                            _buildTopProducts(context),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 40)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      );

  // Shimmer loading for dashboard
  Widget _buildShimmerLoading(BuildContext context) => CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: <Widget>[
        _buildSliverAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: context.responsivePadding,
            child: Column(
              children: [
                // Quick actions shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => Expanded(
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
                    (index) => const ShimmerCard(),
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
                    label: 'إدارة المخزون',
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
                    label: 'إضافة منتج',
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    onTap: () {
                      widget.onNavigateToTab(3);
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
                    label: 'إضافة للمخزون',
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

    // Calculate trend values (placeholder - would come from historical data)
    final double totalProfitTrend = stats.totalProfit > 0 ? 12.5 : 0;
    final double productsValueTrend = stats.totalProductsValue > 0 ? 8.3 : 0;
    final double todayTrend = stats.todaySales > 0 ? 5.2 : 0;
    final double monthlyTrend = stats.monthlySales > 0 ? 15.7 : 0;

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

  Widget _buildTopProducts(BuildContext context) {
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
            if (_topProducts.isEmpty)
              Padding(
                padding: context.responsivePadding,
                child: Center(child: Text(l10n.noData)),
              )
            else
              ..._topProducts
                  .asMap()
                  .entries
                  .map((MapEntry<int, Map<String, dynamic>> entry) {
                final int idx = entry.key;
                final Map<String, dynamic> product = entry.value;
                return ModernProductProfitCard(
                  rank: idx + 1,
                  productName: product['name'] as String,
                  profit: (product['profit'] as num).toDouble(),
                  profitPercentage:
                      (product['profitPercentage'] as num).toDouble(),
                );
              }),
          ],
        ),
      ),
    );
  }
}
