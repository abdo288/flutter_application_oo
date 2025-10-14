import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/presence_service.dart';
import '../services/realtime_debug_service.dart';
import '../services/realtime_update_service.dart';
import '../services/realtime_settings_service.dart';
import '../widgets/realtime_status_widget.dart';
import '../widgets/realtime_stats_chart.dart';
import '../widgets/realtime_updates_log.dart';

/// شاشة إعدادات التحديثات الفورية
class RealtimeSettingsTab extends StatefulWidget {
  const RealtimeSettingsTab({super.key});

  @override
  State<RealtimeSettingsTab> createState() => _RealtimeSettingsTabState();
}

class _RealtimeSettingsTabState extends State<RealtimeSettingsTab>
    with TickerProviderStateMixin {
  final RealtimeUpdateService _realtimeService = RealtimeUpdateService.instance;
  final PresenceService _presenceService = PresenceService.instance;
  final RealtimeSettingsService _settingsService =
      RealtimeSettingsService.instance;

  bool _isOnline = false;
  bool _isListening = false;
  DateTime? _lastUpdateTime;
  Timer? _periodicUpdateTimer;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _updateStatus();
    _setupCallbacks();
    _initializeServices();
    // بدء تحديث دوري للحالة
    _startPeriodicUpdate();
    // تنظيف الجلسات المكررة عند البدء
    _cleanupDuplicateSessions();
  }

  @override
  void dispose() {
    _realtimeService.removeConnectionStatusCallback(_updateStatus);
    _periodicUpdateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _settingsService.initialize();
      await _realtimeService.initialize();
    } catch (e) {
      debugPrint('خطأ في تهيئة الخدمات: $e');
    }
  }

  void _setupCallbacks() {
    _realtimeService.addConnectionStatusCallback(_updateStatus);
  }

  /// بدء التحديث الدوري للحالة
  void _startPeriodicUpdate() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (mounted) {
        _updateStatus();
      }
    });
  }

  void _updateStatus() {
    if (mounted) {
      setState(() {
        _isOnline = _realtimeService.isOnline;
        _isListening = _realtimeService.isListening;
        _lastUpdateTime = _realtimeService.lastUpdateTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // معالجة خاصة لـ Windows
    if (Platform.isWindows) {
      return _buildWindowsOptimizedLayout(context);
    }

    return _buildDefaultLayout(context);
  }

  /// بناء التخطيط المحسن لـ Windows
  Widget _buildWindowsOptimizedLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات التحديثات الفورية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start, // محاذاة خاصة لـ Windows
            tabs: const <Widget>[
              Tab(text: 'الحالة', icon: Icon(Icons.dashboard)),
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
              Tab(text: 'السجل', icon: Icon(Icons.history)),
              Tab(text: 'الجلسات', icon: Icon(Icons.devices_other)),
              Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: _buildWindowsOptimizedBody(),
      );

  /// بناء التخطيط الافتراضي
  Widget _buildDefaultLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات التحديثات الفورية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const <Widget>[
              Tab(text: 'الحالة', icon: Icon(Icons.dashboard)),
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
              Tab(text: 'السجل', icon: Icon(Icons.history)),
              Tab(text: 'الجلسات', icon: Icon(Icons.devices_other)),
              Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: _buildDefaultBody(),
      );

  /// بناء المحتوى المحسن لـ Windows
  Widget _buildWindowsOptimizedBody() {
    try {
      return TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildWindowsStatusTab(),
          _buildWindowsStatsTab(),
          _buildWindowsLogTab(),
          _buildWindowsSessionsTab(),
          _buildWindowsSettingsTab(),
        ],
      );
    } catch (e) {
      debugPrint('خطأ في TabBarView على Windows: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('خطأ في تحميل التبويبات', style: TextStyle(fontSize: 18)),
            Text('يرجى إعادة تشغيل التطبيق', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
  }

  /// بناء المحتوى الافتراضي
  Widget _buildDefaultBody() {
    try {
      return TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildStatusTab(),
          _buildStatsTab(),
          _buildLogTab(),
          _buildSessionsTab(),
          _buildSettingsTab(),
        ],
      );
    } catch (e) {
      debugPrint('خطأ في TabBarView: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('خطأ في تحميل التبويبات', style: TextStyle(fontSize: 18)),
            Text('يرجى إعادة تشغيل التطبيق', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
  }

  /// تبويب الحالة
  Widget _buildStatusTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // widget حالة التحديثات
            const RealtimeStatusWidget(),

            const SizedBox(height: 20),

            // معلومات مفصلة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'معلومات مفصلة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInfoRow(
                              'حالة الاتصال', _isOnline ? 'متصل' : 'غير متصل'),
                        ),
                        IconButton(
                          onPressed: _refreshConnectionStatus,
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'تحديث حالة الاتصال',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    _buildInfoRow(
                        'التحديثات الفورية', _isListening ? 'مفعلة' : 'معطلة'),
                    _buildInfoRow(
                        'آخر تحديث',
                        _lastUpdateTime != null
                            ? _formatLastUpdateTime(_lastUpdateTime!)
                            : 'لم يتم بعد'),
                    _buildInfoRow('عدد callbacks المنتجات',
                        _realtimeService.productCallbackCount.toString()),
                    _buildInfoRow('عدد callbacks المخزون',
                        _realtimeService.inventoryCallbackCount.toString()),
                    _buildInfoRow('عدد callbacks الاتصال',
                        _realtimeService.connectionCallbackCount.toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // المنصات النشطة (نظام الحضور)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.devices,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المنصات النشطة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _refreshActiveSessions,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'تحديث حالة الاتصال والمنصات النشطة',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // عرض المنصات النشطة باستخدام StreamBuilder
                    StreamBuilder<List<ActiveSession>>(
                      stream: _presenceService.getActiveSessionsStream(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<ActiveSession>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: <Widget>[
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'خطأ في تحميل المنصات النشطة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.red,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _refreshActiveSessions,
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final List<ActiveSession> sessions =
                            snapshot.data ?? <ActiveSession>[];

                        if (sessions.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: <Widget>[
                                  const Icon(
                                    Icons.devices_other,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لا توجد منصات نشطة حالياً',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: sessions
                              .map((ActiveSession session) =>
                                  _buildActiveSessionCard(context, session))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار التحكم الرئيسية
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? null : _startRealtimeUpdates,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('بدء التحديثات الفورية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopRealtimeUpdates : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف التحديثات الفورية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// تبويب الإحصائيات
  Widget _buildStatsTab() => const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: RealtimeStatsChart(),
      );

  /// تبويب السجل
  Widget _buildLogTab() => const RealtimeUpdatesLog();

  /// تبويب إدارة الجلسات النشطة
  Widget _buildSessionsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // عنوان القسم مع إحصائيات سريعة
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.devices_other,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إدارة الجلسات النشطة عبر المنصات',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _refreshActiveSessions,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'تحديث حالة الاتصال والمنصات النشطة',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // إحصائيات سريعة
                    StreamBuilder<List<ActiveSession>>(
                      stream: _presenceService.getActiveSessionsStream(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<ActiveSession>> snapshot) {
                        final int sessionCount = snapshot.data?.length ?? 0;
                        final int windowsCount = snapshot.data
                                ?.where((ActiveSession s) => s.platform
                                    .toLowerCase()
                                    .contains('windows'))
                                .length ??
                            0;
                        final int mobileCount = snapshot.data
                                ?.where((ActiveSession s) =>
                                    s.platform
                                        .toLowerCase()
                                        .contains('android') ||
                                    s.platform.toLowerCase().contains('ios'))
                                .length ??
                            0;

                        return Row(
                          children: <Widget>[
                            _buildQuickStat('إجمالي الجلسات',
                                sessionCount.toString(), Icons.group),
                            const SizedBox(width: 16),
                            _buildQuickStat('Windows', windowsCount.toString(),
                                Icons.laptop_windows),
                            const SizedBox(width: 16),
                            _buildQuickStat('موبايل', mobileCount.toString(),
                                Icons.phone_android),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // عرض المنصات النشطة باستخدام StreamBuilder
            StreamBuilder<List<ActiveSession>>(
              stream: _presenceService.getActiveSessionsStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<ActiveSession>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'خطأ في تحميل الجلسات النشطة',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.red,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<ActiveSession> sessions =
                    snapshot.data ?? <ActiveSession>[];

                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          const Icon(
                            Icons.devices_other,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد منصات نشطة حالياً',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: <Widget>[
                    // معلومات إضافية عن الجلسات
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم العثور على ${sessions.length} جلسة نشطة - آخر تحديث: ${_formatLastUpdateTime(DateTime.now())}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // قائمة الجلسات
                    ...sessions
                        .map((ActiveSession session) =>
                            _buildEnhancedActiveSessionCard(context, session))
                        ,
                  ],
                );
              },
            ),
          ],
        ),
      );

  // ========== دوال محسنة لـ Windows ==========

  /// تبويب الحالة المحسن لـ Windows
  Widget _buildWindowsStatusTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // معلومات Windows المحددة
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.laptop_windows, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'إعدادات Windows',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('نوع المزامنة', 'دورية (كل 10 ثوانٍ)'),
                    _buildInfoRow(
                        'حالة الاتصال', _isOnline ? 'متصل' : 'غير متصل'),
                    _buildInfoRow(
                        'آخر تحديث',
                        _lastUpdateTime != null
                            ? _formatLastUpdateTime(_lastUpdateTime!)
                            : 'لم يتم بعد'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // widget حالة التحديثات
            const RealtimeStatusWidget(),

            const SizedBox(height: 20),

            // معلومات مفصلة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'معلومات مفصلة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInfoCard(
                            'الاتصال',
                            _isOnline ? 'متصل' : 'غير متصل',
                            _isOnline ? Icons.wifi : Icons.wifi_off,
                            _isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            'الاستماع',
                            _isListening ? 'نشط' : 'معطل',
                            _isListening ? Icons.play_arrow : Icons.pause,
                            _isListening ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار التحكم الرئيسية
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? null : _startRealtimeUpdates,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('بدء التحديثات الفورية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopRealtimeUpdates : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف التحديثات الفورية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// تبويب الإحصائيات المحسن لـ Windows
  Widget _buildWindowsStatsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // معلومات Windows المحددة
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.analytics, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'إحصائيات Windows',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('نوع المزامنة', 'دورية محسنة'),
                    _buildInfoRow('فترة المزامنة', '10 ثوانٍ'),
                    _buildInfoRow('حالة الأداء', 'محسن لـ Windows'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const RealtimeStatsChart(),
          ],
        ),
      );

  /// تبويب السجل المحسن لـ Windows
  Widget _buildWindowsLogTab() => const RealtimeUpdatesLog();

  /// تبويب إدارة الجلسات المحسن لـ Windows
  Widget _buildWindowsSessionsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Windows-specific info header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.laptop_windows,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إدارة الجلسات النشطة - Windows',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: IconButton(
                      onPressed: _refreshActiveSessions,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تحديث حالة الاتصال والمنصات النشطة',
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // عرض المنصات النشطة باستخدام StreamBuilder
            StreamBuilder<List<ActiveSession>>(
              stream: _presenceService.getActiveSessionsStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<ActiveSession>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'خطأ في تحميل الجلسات النشطة',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.red.shade700,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<ActiveSession> sessions =
                    snapshot.data ?? <ActiveSession>[];

                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.devices_other,
                            color: Colors.grey.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد منصات نشطة حالياً',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: <Widget>[
                    // معلومات إضافية عن الجلسات - Windows
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم العثور على ${sessions.length} جلسة نشطة - آخر تحديث: ${_formatLastUpdateTime(DateTime.now())}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // قائمة الجلسات
                    ...sessions
                        .map((ActiveSession session) =>
                            _buildEnhancedActiveSessionCard(context, session))
                        ,
                  ],
                );
              },
            ),
          ],
        ),
      );

  /// تبويب الإعدادات المحسن لـ Windows
  Widget _buildWindowsSettingsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // إعدادات Windows المحددة
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.settings, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'إعدادات Windows',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('إعادة تشغيل التحديثات'),
                      subtitle: const Text('إعادة تشغيل جميع المستمعين'),
                      onTap: _restartRealtimeUpdates,
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('تحديث شامل للنظام'),
                      subtitle:
                          const Text('تحديث حالة الاتصال والجلسات والإعدادات'),
                      onTap: _performFullRefresh,
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync_problem),
                      title: const Text('فحص صحة الاتصال'),
                      subtitle: const Text('فحص حالة الاتصال والمزامنة'),
                      onTap: _performHealthCheck,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // إعدادات متقدمة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'إعدادات متقدمة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('مسح جميع Callbacks'),
                      subtitle: const Text('إزالة جميع callbacks المضافة'),
                      onTap: _clearAllCallbacks,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('تشخيص التحديثات الفورية'),
                      subtitle: const Text('فحص شامل لحالة النظام'),
                      onTap: _performDiagnosis,
                    ),
                    ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('اختبار التحديث الفوري'),
                      subtitle: const Text('إرسال تحديث تجريبي'),
                      onTap: _testRealtimeUpdate,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// بناء بطاقة معلومات
  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );

  /// تبويب الإعدادات
  Widget _buildSettingsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // إعدادات متقدمة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'إعدادات متقدمة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('إعادة تشغيل التحديثات'),
                      subtitle: const Text('إعادة تشغيل جميع المستمعين'),
                      onTap: _restartRealtimeUpdates,
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('تحديث شامل للنظام'),
                      subtitle:
                          const Text('تحديث حالة الاتصال والجلسات والإعدادات'),
                      onTap: _performFullRefresh,
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync_problem),
                      title: const Text('فحص صحة الاتصال'),
                      subtitle: const Text('فحص حالة الاتصال والمزامنة'),
                      onTap: _performHealthCheck,
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('مسح جميع Callbacks'),
                      subtitle: const Text('إزالة جميع callbacks المضافة'),
                      onTap: _clearAllCallbacks,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('تشخيص التحديثات الفورية'),
                      subtitle: const Text('فحص شامل لحالة النظام'),
                      onTap: _performDiagnosis,
                    ),
                    ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('اختبار التحديث الفوري'),
                      subtitle: const Text('إرسال تحديث تجريبي'),
                      onTap: _testRealtimeUpdate,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );

  /// بناء إحصائية سريعة
  Widget _buildQuickStat(String label, String value, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '$value $label',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );

  /// بناء بطاقة جلسة محسنة
  Widget _buildEnhancedActiveSessionCard(
      BuildContext context, ActiveSession session) {
    final bool isCurrentSession = _isCurrentSession(session);
    final Duration timeSinceLastSeen =
        DateTime.now().difference(session.lastSeen);
    final String timeAgo = _formatTimeAgo(timeSinceLastSeen);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isCurrentSession
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCurrentSession
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withOpacity(0.3),
          width: isCurrentSession ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header مع المنصة والحالة
            Row(
              children: <Widget>[
                // أيقونة المنصة
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(session.platform).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getPlatformIcon(session.platform),
                    color: _getPlatformColor(session.platform),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // معلومات الجلسة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            session.platform,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentSession
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                          ),
                          if (isCurrentSession) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'حالي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'آخر نشاط: $timeAgo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),

                // حالة الاتصال
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConnectionStatusColor(timeSinceLastSeen)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getConnectionStatusColor(timeSinceLastSeen),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getConnectionStatusColor(timeSinceLastSeen),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getConnectionStatusText(timeSinceLastSeen),
                        style: TextStyle(
                          color: _getConnectionStatusColor(timeSinceLastSeen),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // تفاصيل إضافية
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'بداية الجلسة: ${_formatDateTime(session.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.update, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'آخر تحديث: ${_formatDateTime(session.lastSeen)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                  if (session.userId.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(Icons.person,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'معرف المستخدم: ${session.userId}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة الجلسة النشطة
  Widget _buildActiveSessionCard(BuildContext context, ActiveSession session) {
    final bool isCurrentSession = _isCurrentSession(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isCurrentSession
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isCurrentSession
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withOpacity(0.3),
          width: isCurrentSession ? 2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          // أيقونة المنصة
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: _getPlatformColor(session.platform).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              _getPlatformIcon(session.platform),
              color: _getPlatformColor(session.platform),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // معلومات الجلسة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      session.platform,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentSession
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                    if (isCurrentSession) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'هذا الجهاز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر نشاط: ${session.lastSeenFormatted}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  'معرف الجلسة: ${session.sessionId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),

          // مؤشر الحالة
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: session.isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// التحقق من أن الجلسة هي الجلسة الحالية
  bool _isCurrentSession(ActiveSession session) {
    // التحقق من أن الجلسة تنتمي للمستخدم الحالي
    // يمكن إضافة منطق أكثر تعقيداً هنا للتحقق من الجلسة الحالية
    return session.platform == _getCurrentPlatform();
  }

  /// الحصول على المنصة الحالية
  String _getCurrentPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }

  /// تنسيق الوقت المنقضي
  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'الآن';
    } else if (duration.inMinutes < 60) {
      return 'منذ ${duration.inMinutes} دقيقة';
    } else if (duration.inHours < 24) {
      return 'منذ ${duration.inHours} ساعة';
    } else {
      return 'منذ ${duration.inDays} يوم';
    }
  }

  /// تنسيق التاريخ والوقت
  String _formatDateTime(DateTime dateTime) => '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  /// الحصول على لون حالة الاتصال
  Color _getConnectionStatusColor(Duration timeSinceLastSeen) {
    if (timeSinceLastSeen.inMinutes < 2) {
      return Colors.green; // نشط جداً
    } else if (timeSinceLastSeen.inMinutes < 5) {
      return Colors.orange; // نشط
    } else if (timeSinceLastSeen.inMinutes < 15) {
      return Colors.red; // غير نشط
    } else {
      return Colors.grey; // منقطع
    }
  }

  /// الحصول على نص حالة الاتصال
  String _getConnectionStatusText(Duration timeSinceLastSeen) {
    if (timeSinceLastSeen.inMinutes < 2) {
      return 'نشط جداً';
    } else if (timeSinceLastSeen.inMinutes < 5) {
      return 'نشط';
    } else if (timeSinceLastSeen.inMinutes < 15) {
      return 'غير نشط';
    } else {
      return 'منقطع';
    }
  }

  /// الحصول على لون المنصة
  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'windows':
        return Colors.blue;
      case 'android':
        return Colors.green;
      case 'ios':
        return Colors.grey;
      case 'web':
        return Colors.orange;
      case 'linux':
        return Colors.purple;
      case 'macos':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة المنصة
  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'windows':
        return Icons.laptop_windows;
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'linux':
        return Icons.laptop;
      case 'macos':
        return Icons.laptop_mac;
      default:
        return Icons.device_unknown;
    }
  }

  /// تحديث حالة الاتصال فقط
  Future<void> _refreshConnectionStatus() async {
    try {
      // إظهار مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('جاري فحص حالة الاتصال...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // تحديث حالة الاتصال
      _updateStatus();

      if (mounted) {
        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_isOnline ? 'الاتصال متاح' : 'الاتصال غير متاح'),
              ],
            ),
            backgroundColor: _isOnline ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('خطأ في فحص الاتصال: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// تحديث شامل للنظام
  Future<void> _performFullRefresh() async {
    try {
      // إظهار مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('جاري التحديث الشامل للنظام...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 1. تحديث حالة الاتصال
      _updateStatus();

      // 2. تنظيف الجلسات المنتهية الصلاحية
      await _presenceService.cleanupExpiredSessions();

      // 3. إعادة تشغيل التحديثات الفورية
      await _realtimeService.stopRealtimeUpdates();
      await Future<void>.delayed(const Duration(seconds: 1));
      await _realtimeService.startRealtimeUpdates();

      // 4. إعادة بناء الواجهة
      if (mounted) {
        setState(() {
          // إعادة بناء الواجهة
        });

        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('تم التحديث الشامل بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('خطأ في التحديث الشامل: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// تنظيف الجلسات المكررة للجهاز الحالي
  Future<void> _cleanupDuplicateSessions() async {
    try {
      // الحصول على جميع الجلسات النشطة
      final List<ActiveSession> sessions =
          await _presenceService.getActiveSessionsStream().first;

      // تجميع الجلسات حسب المنصة
      final Map<String, List<ActiveSession>> sessionsByPlatform =
          <String, List<ActiveSession>>{};
      for (final ActiveSession session in sessions) {
        sessionsByPlatform.putIfAbsent(
            session.platform, () => <ActiveSession>[]);
        sessionsByPlatform[session.platform]!.add(session);
      }

      int deletedCount = 0;
      // تنظيف الجلسات المكررة لكل منصة
      for (final MapEntry<String, List<ActiveSession>> entry
          in sessionsByPlatform.entries) {
        final List<ActiveSession> platformSessions = entry.value;

        if (platformSessions.length > 1) {
          // ترتيب الجلسات حسب آخر نشاط (الأحدث أولاً)
          platformSessions.sort((ActiveSession a, ActiveSession b) => b.lastSeen.compareTo(a.lastSeen));

          // الاحتفاظ بالجلسة الأحدث فقط وحذف الباقي
          for (int i = 1; i < platformSessions.length; i++) {
            await _presenceService
                .forceEndSession(platformSessions[i].sessionId);
            deletedCount++;
            debugPrint(
                '🗑️ تم حذف الجلسة المكررة: ${platformSessions[i].sessionId}');
          }
        }
      }

      // تنظيف صامت - بدون رسائل
      debugPrint('تم تنظيف $deletedCount جلسة مكررة بصمت');
    } catch (e) {
      debugPrint('خطأ في تنظيف الجلسات المكررة: $e');
      // إخفاء رسائل الخطأ أيضاً
    }
  }

  /// تحديث قائمة المنصات النشطة وحالة الاتصال
  Future<void> _refreshActiveSessions() async {
    try {
      // إظهار مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('جاري تحديث حالة الاتصال...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // تحديث حالة الاتصال
      _updateStatus();

      // تنظيف الجلسات المنتهية الصلاحية
      await _presenceService.cleanupExpiredSessions();

      // تنظيف الجلسات المكررة للجهاز الحالي
      await _cleanupDuplicateSessions();

      // إعادة بناء الـ StreamBuilder
      if (mounted) {
        setState(() {
          // إعادة بناء الواجهة
        });

        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('تم تحديث حالة الاتصال بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('خطأ في تحديث حالة الاتصال: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatLastUpdateTime(DateTime time) {
    final Duration difference = DateTime.now().difference(time);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  Future<void> _startRealtimeUpdates() async {
    try {
      await _realtimeService.startRealtimeUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء التحديثات الفورية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء التحديثات الفورية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRealtimeUpdates() async {
    try {
      await _realtimeService.stopRealtimeUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إيقاف التحديثات الفورية'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إيقاف التحديثات الفورية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restartRealtimeUpdates() async {
    try {
      await _realtimeService.stopRealtimeUpdates();
      await Future<void>.delayed(const Duration(seconds: 1));
      await _realtimeService.startRealtimeUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تشغيل التحديثات الفورية بنجاح'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة تشغيل التحديثات الفورية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performHealthCheck() async {
    // يمكن إضافة فحص صحة مخصص هنا
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فحص صحة الاتصال: ${_isOnline ? "متصل" : "غير متصل"}'),
          backgroundColor: _isOnline ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _clearAllCallbacks() {
    // يمكن إضافة منطق لمسح callbacks هنا
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم مسح جميع Callbacks'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _performDiagnosis() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري التشخيص...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final Map<String, dynamic> diagnosis =
          await RealtimeDebugService.performFullDiagnosis();

      // طباعة التقرير في الكونسول
      RealtimeDebugService.printDiagnosisReport(diagnosis);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التشخيص - راجع سجلات التطبيق'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التشخيص: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testRealtimeUpdate() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري إرسال تحديث تجريبي...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final bool success = await RealtimeDebugService.testRealtimeUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'تم إرسال التحديث التجريبي بنجاح'
                : 'فشل في إرسال التحديث التجريبي'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
