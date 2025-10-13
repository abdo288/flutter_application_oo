import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/alert_settings_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/inventory_alert.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_inventory_provider.dart';
import '../services/inventory_alert_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/inventory_alert_card.dart';
import '../widgets/styled_section.dart';

/// تبويب التنبيهات
class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  List<InventoryAlert> _alerts = <InventoryAlert>[];
  bool _isLoading = true;
  bool _showOnlyUnread = false;
  Map<String, int> _alertStatistics = <String, int>{};
  final Map<AlertType, bool> _expandedGroups = <AlertType, bool>{};

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAlerts();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // تحديد أحجام النصوص بناءً على عرض الشاشة
              final double screenWidth = constraints.maxWidth;
              final bool isSmallScreen = screenWidth < 400;
              final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
              final double subtitleFontSize = isSmallScreen ? 11.0 : 12.0;
              final double iconSize = isSmallScreen ? 14.0 : 16.0;
              final double containerPadding = isSmallScreen ? 8.0 : 12.0;

              return Container(
                constraints: const BoxConstraints(
                  maxHeight: 80, // حد أقصى للارتفاع
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: containerPadding,
                  vertical: isSmallScreen ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // العنوان الرئيسي
                    Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 3.0 : 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                                isSmallScreen ? 4.0 : 6.0),
                          ),
                          child: Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).alertsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isSmallScreen) ...<Widget>[
                      const SizedBox(height: 2.0),
                      // العنوان الفرعي
                      Row(
                        children: <Widget>[
                          const SizedBox(
                              width: 20.0), // محاذاة مع العنوان الرئيسي
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).alertsSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withValues(alpha: 0.9),
                  AppConstants.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
          actions: <Widget>[
            // قائمة الإعدادات والإجراءات الشاملة
            _buildActionButton(
              icon: Icons.settings,
              tooltip: AppLocalizations.of(context).allSettingsAndActionsNew,
              onPressed: null,
              color: Colors.blue,
              child: PopupMenuButton<String>(
                onSelected: _onComprehensiveActionSelected,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  // قسم إعدادات التنبيهات
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.settings,
                            color: AppConstants.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).alertSettingsNew,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'alert_settings',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.settings, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).alertSettings),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // قسم إدارة التنبيهات
                  PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.manage_accounts,
                            color: AppConstants.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).manageAlertsNew,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh_alerts',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.refresh, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).refreshAlerts),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'check_alerts',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.search,
                            color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).checkAlerts),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // قسم الفلترة
                  PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.filter_list,
                            color: AppConstants.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).filterAlertsNew,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'filter_all',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.list,
                            color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).filterAll),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'filter_unread',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.mark_email_unread,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).filterUnread),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // قسم التحكم في العرض
                  PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.view_module,
                            color: AppConstants.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).displayControlNew,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_groups',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _areAllGroupsExpanded()
                              ? Icons.unfold_less
                              : Icons.unfold_more,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(_areAllGroupsExpanded()
                            ? AppLocalizations.of(context).closeAllGroupsNew
                            : AppLocalizations.of(context).openAllGroupsNew),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // قسم الإجراءات الجماعية
                  PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.group_work,
                            color: AppConstants.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).bulkActionsNew,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.done_all, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).markAllRead),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.delete_sweep, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).deleteRead),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cleanup_old',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.cleaning_services, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).cleanOldAlertsNew),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.settings),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(child: _buildAlertsList()),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _checkInventoryAlerts,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            tooltip: AppLocalizations.of(context).checkInventory,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.search, size: 20),
            ),
            label: Text(
              AppLocalizations.of(context).checkInventory,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            elevation: 0,
          ),
        ),
      );

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).loadingAlerts,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).pleaseWait,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildAlertsList() {
    if (_alerts.isEmpty) {
      return _buildEmptyState();
    }

    // فلترة التنبيهات
    final List<InventoryAlert> filteredAlerts = _showOnlyUnread
        ? _alerts.where((InventoryAlert alert) => !alert.isRead).toList()
        : _alerts;

    if (filteredAlerts.isEmpty) {
      return _buildNoUnreadAlerts();
    }

    // تجميع التنبيهات حسب النوع
    final Map<AlertType, List<InventoryAlert>> groupedAlerts =
        _groupAlertsByType(filteredAlerts);

    return Column(
      children: <Widget>[
        // شريط إحصائيات التنبيهات
        StyledSection(child: _buildAlertsStatsBar(filteredAlerts)),

        // قائمة التنبيهات المجمعة
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RefreshIndicator(
            onRefresh: _refreshAlerts,
            color: AppConstants.primaryColor,
            backgroundColor: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: groupedAlerts.length,
              itemBuilder: (BuildContext context, int index) {
                final AlertType alertType = groupedAlerts.keys.elementAt(index);
                final List<InventoryAlert> alertsOfType =
                    groupedAlerts[alertType]!;

                return _buildAlertGroup(alertType, alertsOfType);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsStatsBar(List<InventoryAlert> filteredAlerts) {
    // استخدام الإحصائيات من الخدمة إذا كانت متاحة، وإلا استخدام البيانات المحلية
    final int totalCount = _alertStatistics['total'] ?? filteredAlerts.length;
    final int unreadCount = _alertStatistics['unread'] ??
        filteredAlerts.where((InventoryAlert alert) => !alert.isRead).length;
    final int outOfStockCount = _alertStatistics['outOfStock'] ??
        filteredAlerts
            .where((InventoryAlert alert) =>
                alert.alertType == AlertType.outOfStock)
            .length;
    final int lowStockCount = _alertStatistics['lowStock'] ??
        filteredAlerts
            .where(
                (InventoryAlert alert) => alert.alertType == AlertType.lowStock)
            .length;
    final int expiringCount = _alertStatistics['expiring'] ??
        filteredAlerts
            .where((InventoryAlert alert) =>
                alert.alertType == AlertType.expiringSoon)
            .length;

    // تحديد الحجم بناءً على عرض الشاشة
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isVerySmallScreen = screenWidth < 400;

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 120, // حد أقصى للارتفاع
      ),
      margin: EdgeInsets.fromLTRB(
          isSmallScreen ? 8 : 12, 6, isSmallScreen ? 8 : 12, 2),
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppConstants.primaryColor.withValues(alpha: 0.06),
            AppConstants.primaryColor.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.05),
            blurRadius: isSmallScreen ? 2 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // العنوان المضغوط
          Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: isSmallScreen ? 12 : 14,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).alertStatisticsNew,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isVerySmallScreen)
                Text(
                  _getCurrentTime(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 6 : 8),

          // الإحصائيات في صف واحد مضغوط جداً
          if (isVerySmallScreen)
            _buildCompactStatsGrid(filteredAlerts, totalCount, unreadCount,
                outOfStockCount, lowStockCount, expiringCount)
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildCompactStatItem(
                    AppLocalizations.of(context).totalNew,
                    totalCount.toString(),
                    Icons.list,
                    AppConstants.primaryColor,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Expanded(
                  child: _buildCompactStatItem(
                    AppLocalizations.of(context).unreadNew,
                    unreadCount.toString(),
                    Icons.mark_email_unread,
                    Colors.orange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Expanded(
                  child: _buildCompactStatItem(
                    AppLocalizations.of(context).outOfStockAlertsNew,
                    outOfStockCount.toString(),
                    Icons.warning,
                    Colors.red,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Expanded(
                  child: _buildCompactStatItem(
                    AppLocalizations.of(context).lowStockAlertsNew,
                    lowStockCount.toString(),
                    Icons.trending_down,
                    Colors.amber,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Expanded(
                  child: _buildCompactStatItem(
                    AppLocalizations.of(context).expiringSoonAlertsNew,
                    expiringCount.toString(),
                    Icons.schedule,
                    Colors.blue,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// بناء عنصر إحصائية مضغوط
  Widget _buildCompactStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isSmallScreen = false,
  }) =>
      Container(
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 4 : 6, horizontal: isSmallScreen ? 3 : 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 5 : 6),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 0.8,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: isSmallScreen ? 1 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: isSmallScreen ? 10 : 12),
            SizedBox(height: isSmallScreen ? 1 : 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 7 : 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  /// بناء شبكة إحصائيات مضغوطة للشاشات الصغيرة جداً
  Widget _buildCompactStatsGrid(
    List<InventoryAlert> filteredAlerts,
    int totalCount,
    int unreadCount,
    int outOfStockCount,
    int lowStockCount,
    int expiringCount,
  ) =>
      Column(
        children: <Widget>[
          // الصف الأول
          Row(
            children: <Widget>[
              Expanded(
                child: _buildCompactStatItem(
                  AppLocalizations.of(context).totalNew,
                  totalCount.toString(),
                  Icons.list,
                  AppConstants.primaryColor,
                  isSmallScreen: true,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildCompactStatItem(
                  AppLocalizations.of(context).unreadNew,
                  unreadCount.toString(),
                  Icons.mark_email_unread,
                  Colors.orange,
                  isSmallScreen: true,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildCompactStatItem(
                  AppLocalizations.of(context).outOfStockAlertsNew,
                  outOfStockCount.toString(),
                  Icons.warning,
                  Colors.red,
                  isSmallScreen: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // الصف الثاني
          Row(
            children: <Widget>[
              Expanded(
                child: _buildCompactStatItem(
                  AppLocalizations.of(context).lowStockAlertsNew,
                  lowStockCount.toString(),
                  Icons.trending_down,
                  Colors.amber,
                  isSmallScreen: true,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildCompactStatItem(
                  AppLocalizations.of(context).expiringSoonAlertsNew,
                  expiringCount.toString(),
                  Icons.schedule,
                  Colors.blue,
                  isSmallScreen: true,
                ),
              ),
              const SizedBox(width: 3),
              // مساحة فارغة للتوازن
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );

  /// الحصول على الوقت الحالي
  String _getCurrentTime() {
    final DateTime now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox,
                  size: 64,
                  color: AppConstants.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).noAlerts,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).allProductsGoodNew,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _checkInventoryAlerts,
                  icon: const Icon(Icons.search),
                  label: Text(
                      AppLocalizations.of(context).checkInventoryButtonNew),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildNoUnreadAlerts() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).excellentNew,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).noUnreadAlertsNew,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _checkInventoryAlerts,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).newCheckButtonNew),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<InventoryAlert> alerts =
          await InventoryAlertService.getAllAlerts();
      final Map<String, int> statistics =
          await InventoryAlertService.getAlertStatistics();
      setState(() {
        _alerts = alerts;
        _alertStatistics = statistics;
        _isLoading = false;
      });

      // فتح المجموعة الأولى تلقائياً
      _expandFirstGroupIfNeeded();
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).loadingAlertsError);
      }
    }
  }

  Future<void> _refreshAlerts() async {
    await _loadAlerts();
  }

  Future<void> _checkInventoryAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;
      await InventoryAlertService.checkInventoryAlerts(inventoryProvider);
      await _loadAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(
            context, AppLocalizations.of(context).inventoryCheckedSuccess);
      }
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).inventoryCheckError);
      }
    }
  }

  Future<void> _markAlertAsRead(InventoryAlert alert) async {
    try {
      if (alert.id != null) {
        await InventoryAlertService.markAlertAsRead(alert.id!);
        setState(() {
          alert.isRead = true;
        });
        if (mounted) {
          SnackbarUtils.showSuccess(
              context, AppLocalizations.of(context).markAsReadSuccess);
        }
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).markAsReadError);
      }
    }
  }

  Future<void> _deleteAlert(InventoryAlert alert) async {
    final bool confirmed = await _showDeleteConfirmation(alert);
    if (!confirmed) return;

    try {
      if (alert.id != null) {
        await InventoryAlertService.deleteAlert(alert.id!);
        setState(() {
          _alerts.remove(alert);
        });
        if (mounted) {
          SnackbarUtils.showSuccess(
              context, AppLocalizations.of(context).deleteAlertSuccess);
        }
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).deleteAlertError);
      }
    }
  }

  Future<bool> _showDeleteConfirmation(InventoryAlert alert) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(AppLocalizations.of(context).confirmDeleteAlert),
          content: Text(AppLocalizations.of(context)
              .confirmDeleteAlertMessage(alert.productName)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        ),
      ) ??
      false;

  void _onFilterSelected(String value) {
    try {
      setState(() {
        _showOnlyUnread = value == 'unread';
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context,
            AppLocalizations.of(context).applyFilterError(e.toString()));
      }
    }
  }

  /// التعامل مع إجراءات القائمة الشاملة
  Future<void> _onComprehensiveActionSelected(String action) async {
    try {
      switch (action) {
        // إعدادات التنبيهات
        case 'alert_settings':
          _showSettings();
          break;

        // إدارة التنبيهات
        case 'refresh_alerts':
          await _refreshAlerts();
          break;
        case 'check_alerts':
          await _checkInventoryAlerts();
          break;

        // فلترة التنبيهات
        case 'filter_all':
          _onFilterSelected('all');
          break;
        case 'filter_unread':
          _onFilterSelected('unread');
          break;

        // التحكم في العرض
        case 'toggle_groups':
          _toggleAllGroups();
          break;

        // الإجراءات الجماعية
        case 'mark_all_read':
          await _markAllAsRead();
          break;
        case 'delete_read':
          await _deleteReadAlerts();
          break;
        case 'cleanup_old':
          await _cleanupOldAlerts();
          break;

        default:
          if (mounted) {
            SnackbarUtils.showError(
                context, AppLocalizations.of(context).unknownAction);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).actionError(e.toString()));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await InventoryAlertService.markAllAlertsAsRead();
      await _loadAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(
            context, AppLocalizations.of(context).markAllReadSuccess);
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).markAllReadError);
      }
    }
  }

  Future<void> _deleteReadAlerts() async {
    final bool confirmed = await _showDeleteReadConfirmation();
    if (!confirmed) return;

    try {
      await InventoryAlertService.deleteReadAlerts();
      await _loadAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(
            context, AppLocalizations.of(context).deleteReadSuccess);
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).deleteReadError);
      }
    }
  }

  Future<bool> _showDeleteReadConfirmation() async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(AppLocalizations.of(context).confirmDelete),
          content: Text(AppLocalizations.of(context).deleteReadConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _cleanupOldAlerts() async {
    try {
      await InventoryAlertService.cleanupOldAlerts();
      await _loadAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(
            context, AppLocalizations.of(context).cleanupSuccess);
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).cleanupError);
      }
    }
  }

  void _showSettings() {
    try {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => const AlertSettingsDialog(),
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).settingsError(e.toString()));
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

  /// بناء مجموعة التنبيهات كقائمة منسدلة
  Widget _buildAlertGroup(AlertType alertType, List<InventoryAlert> alerts) {
    final String title = _getAlertTypeTitle(alertType);
    final Color color = _getAlertTypeColor(alertType);
    final IconData icon = _getAlertTypeIcon(alertType);
    final bool isExpanded = _expandedGroups[alertType] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // عنوان المجموعة القابل للنقر
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedGroups[alertType] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? color.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alerts.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // محتوى القائمة المنسدلة
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Column(
                    children: <Widget>[
                      const Divider(height: 1),
                      ...alerts.map((InventoryAlert alert) => Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: InventoryAlertCard(
                              alert: alert,
                              onMarkAsRead: alert.isRead
                                  ? null
                                  : () => _markAlertAsRead(alert),
                              onDelete: () => _deleteAlert(alert),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// الحصول على عنوان نوع التنبيه
  String _getAlertTypeTitle(AlertType alertType) {
    switch (alertType) {
      case AlertType.outOfStock:
        return AppLocalizations.of(context).outOfStockAlert;
      case AlertType.lowStock:
        return AppLocalizations.of(context).lowStockAlert;
      case AlertType.expiringSoon:
        return AppLocalizations.of(context).expiringAlert;
    }
  }

  /// الحصول على لون نوع التنبيه
  Color _getAlertTypeColor(AlertType alertType) {
    switch (alertType) {
      case AlertType.outOfStock:
        return Colors.red;
      case AlertType.lowStock:
        return Colors.orange;
      case AlertType.expiringSoon:
        return Colors.blue;
    }
  }

  /// الحصول على أيقونة نوع التنبيه
  IconData _getAlertTypeIcon(AlertType alertType) {
    switch (alertType) {
      case AlertType.outOfStock:
        return Icons.warning;
      case AlertType.lowStock:
        return Icons.trending_down;
      case AlertType.expiringSoon:
        return Icons.schedule;
    }
  }

  /// تبديل حالة جميع المجموعات
  void _toggleAllGroups() {
    try {
      final bool allExpanded = _areAllGroupsExpanded();
      setState(() {
        for (final AlertType alertType in AlertType.values) {
          _expandedGroups[alertType] = !allExpanded;
        }
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context,
            AppLocalizations.of(context).toggleGroupsError(e.toString()));
      }
    }
  }

  /// التحقق من فتح جميع المجموعات
  bool _areAllGroupsExpanded() {
    if (_expandedGroups.isEmpty) return false;
    return _expandedGroups.values.every((bool isExpanded) => isExpanded);
  }

  /// فتح المجموعة الأولى تلقائياً عند وجود تنبيهات
  void _expandFirstGroupIfNeeded() {
    if (_expandedGroups.isEmpty && _alerts.isNotEmpty) {
      final Map<AlertType, List<InventoryAlert>> groupedAlerts =
          _groupAlertsByType(_alerts);
      if (groupedAlerts.isNotEmpty) {
        final AlertType firstType = groupedAlerts.keys.first;
        _expandedGroups[firstType] = true;
      }
    }
  }

  /// بناء زر إجراء في AppBar
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
    Widget? child,
  }) =>
      Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: child ??
            IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              tooltip: tooltip,
              splashRadius: 20,
            ),
      );
}
