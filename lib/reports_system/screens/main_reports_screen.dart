import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/eod_report.dart';

import '../../providers/eod_process_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/eod_reports_provider.dart';
import '../providers/sales_analytics_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/end_of_day_dialog.dart';
import 'analytics_screen.dart';
import 'dashboard_screen_fixed.dart';
import 'eod_reports_screen.dart';
import 'sales_screen_fixed.dart';

/// الشاشة الرئيسية للتقارير
class MainReportsScreen extends ConsumerStatefulWidget {
  const MainReportsScreen({super.key});

  @override
  ConsumerState<MainReportsScreen> createState() => _MainReportsScreenState();
}

class _MainReportsScreenState extends ConsumerState<MainReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة عملية إنهاء اليوم
    final AsyncValue<EODReport?> eodState = ref.watch(eodProcessNotifierProvider);
    final bool isEodRunning = eodState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام التقارير المتقدم'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: <Widget>[
          IconButton(
            onPressed: _refreshCurrentTab,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: _showEndOfDayDialog,
            icon: const Icon(Icons.event),
            tooltip: 'إنهاء اليوم',
          ),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'لوحة التحكم',
            ),
            Tab(
              icon: Icon(Icons.description),
              text: 'تقارير EOD',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'التحليلات',
            ),
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'المبيعات',
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          // عارض التبويبات
          TabBarView(
            controller: _tabController,
            children: const <Widget>[
              DashboardScreenFixed(),
              EODReportsScreen(),
              AnalyticsScreen(),
              SalesScreenFixed(),
            ],
          ),

          // (احترافي) عرض مؤشر تحميل شامل فوق كل التبويبات
          // عندما تكون عملية إنهاء اليوم قيد التشغيل
          if (isEodRunning)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري إنشاء تقرير نهاية اليوم...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _refreshCurrentTab() {
    switch (_currentIndex) {
      case 0: // لوحة التحكم
        ref.read(refreshDashboardProvider)();
        break;
      case 1: // تقارير EOD
        ref.read(refreshEODReportsProvider)();
        break;
      case 2: // التحليلات
        ref.read(refreshAnalyticsProvider)();
        break;
      case 3: // المبيعات
        ref.read(refreshSalesAnalyticsProvider)();
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث البيانات'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEndOfDayDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => const EndOfDayDialog(),
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final ReportsSettingsState settings =
              ref.watch(reportsSettingsProvider);
          final ReportsSettings settingsNotifier =
              ref.read(reportsSettingsProvider.notifier);

          return AlertDialog(
            title: const Text('إعدادات التقارير'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('الإشعارات'),
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (_) => settingsNotifier.toggleNotifications(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('المزامنة التلقائية'),
                    trailing: Switch(
                      value: settings.autoSyncEnabled,
                      onChanged: (_) => settingsNotifier.toggleAutoSync(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('الوضع الليلي'),
                    trailing: Switch(
                      value: settings.darkModeEnabled,
                      onChanged: (_) => settingsNotifier.toggleDarkMode(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('الرسوم البيانية'),
                    trailing: Switch(
                      value: settings.chartsEnabled,
                      onChanged: (_) => settingsNotifier.toggleCharts(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('تصدير البيانات'),
                    trailing: Switch(
                      value: settings.dataExportEnabled,
                      onChanged: (_) => settingsNotifier.toggleDataExport(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('اللغة'),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          settingsNotifier.changeLanguage(value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('فترة التحديث (دقيقة)'),
                    trailing: DropdownButton<int>(
                      value: settings.refreshIntervalMinutes,
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 15, child: Text('15')),
                        DropdownMenuItem(value: 30, child: Text('30')),
                        DropdownMenuItem(value: 60, child: Text('60')),
                      ],
                      onChanged: (int? value) {
                        if (value != null) {
                          settingsNotifier.updateRefreshInterval(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: settingsNotifier.resetToDefaults,
                child: const Text('إعادة تعيين'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }
}
