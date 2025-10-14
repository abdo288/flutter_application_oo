import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/dashboard_stats.dart';
import '../providers/stream_app_provider.dart';
import '../services/dashboard_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_helpers.dart';
import '../utils/responsive_breakpoints.dart';

/// شاشة تفاصيل البطاقة لعرض معلومات مفصلة عن كل إحصائية
class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({
    super.key,
    required this.cardType,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final CardType cardType;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  DashboardStats _stats = DashboardStats.empty();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetailedData();
  }

  Future<void> _loadDetailedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final DashboardStats stats =
          await DashboardService.calculateDashboardStatsStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context).dataLoadingError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : _buildContent(context),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                widget.color,
                widget.color.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      );

  Widget _buildErrorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetailedData,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );

  Widget _buildContent(BuildContext context) => RefreshIndicator(
        onRefresh: _loadDetailedData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // بطاقة الإحصائية الرئيسية
              _buildMainCard(context),
              const SizedBox(height: 16),

              // تفاصيل إضافية حسب نوع البطاقة
              ..._buildDetailedContent(context),
            ],
          ),
        ),
      );

  Widget _buildMainCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: ResponsiveHelpers.responsiveCard(
        context: context,
        color: isDark ? Colors.grey[800] : Colors.white,
        elevation: 4,
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.isSmallScreen ? 200 : 250,
          ),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 12 : 16,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // الأيقونة
              Container(
                padding: EdgeInsets.all(
                  context.responsiveSpacing * 0.8,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: context.isSmallScreen ? 24 : 32,
                ),
              ),
              SizedBox(height: context.responsiveSpacing * 0.5),

              // العنوان
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppConstants.textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.responsiveSpacing * 0.3),

              // القيمة
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (widget.subtitle != null) ...<Widget>[
                SizedBox(height: context.responsiveSpacing * 0.3),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsiveSpacing * 0.5,
                    vertical: context.responsiveSpacing * 0.3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.isSmallScreen ? 16 : 20,
                    ),
                  ),
                  child: Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      color: widget.color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailedContent(BuildContext context) {
    switch (widget.cardType) {
      case CardType.totalProducts:
        return _buildTotalProductsDetails(context);
      case CardType.totalValue:
        return _buildTotalValueDetails(context);
      case CardType.todaySales:
        return _buildTodaySalesDetails(context);
      case CardType.monthlySales:
        return _buildMonthlySalesDetails(context);
      case CardType.totalProfit:
        return _buildTotalProfitDetails(context);
      case CardType.averagePrice:
        return _buildAveragePriceDetails(context);
    }
  }

  List<Widget> _buildTotalProductsDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).totalProductsSold,
          icon: Icons.shopping_cart,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalProducts,
              value: _formatNumber(_stats.totalProducts),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).todaySales,
              value: _formatNumber(_stats.todaySales),
            ),
          ],
        ),
      ];

  List<Widget> _buildTotalValueDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).totalProductsValue,
          icon: Icons.attach_money,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalValue,
              value: _stats.formattedProductsValue(context),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalProducts,
              value: _formatNumber(_stats.totalProducts),
            ),
          ],
        ),
      ];

  List<Widget> _buildTodaySalesDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).todaySales,
          icon: Icons.today,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).productsSoldToday,
              value: _formatNumber(_stats.todaySales),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).todayDate,
              value: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).salesTrend,
              value: _getSalesTrendText(),
            ),
          ],
        ),
      ];

  List<Widget> _buildMonthlySalesDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).monthlySales,
          icon: Icons.calendar_month,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).productsSoldThisMonth,
              value: _formatNumber(_stats.monthlySales),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).currentMonth,
              value: DateFormat('MMMM yyyy').format(DateTime.now()),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).todaySales,
              value: _formatNumber(_stats.todaySales),
            ),
          ],
        ),
      ];

  List<Widget> _buildTotalProfitDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).totalProfitTitle,
          icon: Icons.trending_up,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalProfit,
              value: _stats.formattedTotalProfit(context),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalValue,
              value: _stats.formattedProductsValue(context),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalProducts,
              value: _formatNumber(_stats.totalProducts),
            ),
          ],
        ),
      ];

  List<Widget> _buildAveragePriceDetails(BuildContext context) => <Widget>[
        _buildInfoCard(
          context: context,
          title: AppLocalizations.of(context).averageProductPrice,
          icon: Icons.price_check,
          color: widget.color,
          children: <Widget>[
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).averagePrice,
              value: _stats.formattedAverageProductPrice(context),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalValue,
              value: _stats.formattedProductsValue(context),
            ),
            _buildInfoRow(
              context: context,
              label: AppLocalizations.of(context).totalProducts,
              value: _formatNumber(_stats.totalProducts),
            ),
          ],
        ),
      ];

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) =>
      ResponsiveHelpers.responsiveCard(
        context: context,
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.lightTextColor,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
            ),
          ],
        ),
      );

  String _formatNumber(int number) =>
      CurrencyFormatter.formatNumber(number, context);

  String _getSalesTrendText() {
    if (_stats.todaySales > _stats.averageDailySales) {
      return AppLocalizations.of(context).trendingUp;
    } else if (_stats.todaySales < _stats.averageDailySales) {
      return AppLocalizations.of(context).trendingDown;
    } else {
      return AppLocalizations.of(context).stable;
    }
  }
}

/// أنواع البطاقات المختلفة
enum CardType {
  totalProducts,
  totalValue,
  todaySales,
  monthlySales,
  totalProfit,
  averagePrice,
}
