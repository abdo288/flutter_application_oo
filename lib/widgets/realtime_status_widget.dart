import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/update_log.dart';
import '../services/realtime_update_service.dart';

/// widget لعرض حالة التحديثات الفورية
class RealtimeStatusWidget extends StatefulWidget {
  const RealtimeStatusWidget({super.key});

  @override
  State<RealtimeStatusWidget> createState() => _RealtimeStatusWidgetState();
}

class _RealtimeStatusWidgetState extends State<RealtimeStatusWidget>
    with TickerProviderStateMixin {
  final RealtimeUpdateService _realtimeService = RealtimeUpdateService.instance;
  bool _isOnline = false;
  bool _isListening = false;
  int _productCallbacks = 0;
  int _inventoryCallbacks = 0;
  int _connectionCallbacks = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Performance stats
  Map<String, dynamic> _performanceStats = <String, dynamic>{};
  List<UpdateLog> _recentUpdates = <UpdateLog>[];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateStatus();
    _setupCallbacks();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _realtimeService.removeConnectionStatusCallback(_updateStatus);
    _pulseController.dispose();
    _rotationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (_isListening) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (mounted) {
        _updateStatus();
        _loadPerformanceStats();
      }
    });
  }

  void _loadPerformanceStats() {
    setState(() {
      _performanceStats = _realtimeService.getPerformanceStats();
      _recentUpdates = _realtimeService.getRecentUpdates(limit: 5);
    });
  }

  void _setupCallbacks() {
    _realtimeService.addConnectionStatusCallback(_updateStatus);
  }

  void _updateStatus() {
    if (mounted) {
      setState(() {
        final bool wasListening = _isListening;
        _isOnline = _realtimeService.isOnline;
        _isListening = _realtimeService.isListening;
        _productCallbacks = _realtimeService.productCallbackCount;
        _inventoryCallbacks = _realtimeService.inventoryCallbackCount;
        _connectionCallbacks = _realtimeService.connectionCallbackCount;

        // Update animations based on listening state
        if (_isListening && !wasListening) {
          if (mounted) {
            try {
              _pulseController.repeat(reverse: true);
              _rotationController.repeat();
            } catch (e) {
              // تجاهل الأخطاء إذا تم التخلص من المتحكمات
            }
          }
        } else if (!_isListening && wasListening) {
          if (mounted) {
            try {
              _pulseController.stop();
              _rotationController.stop();
            } catch (e) {
              // تجاهل الأخطاء إذا تم التخلص من المتحكمات
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // معالجة خاصة لـ Windows
    if (Platform.isWindows) {
      return _buildWindowsOptimizedWidget(context);
    }

    return _buildDefaultWidget(context);
  }

  /// بناء widget محسن لـ Windows
  Widget _buildWindowsOptimizedWidget(BuildContext context) => Card(
        margin: const EdgeInsets.all(8.0),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Windows-specific header
              Row(
                children: <Widget>[
                  Icon(
                    Icons.laptop_windows,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حالة التحديثات الفورية - Windows',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  _buildWindowsStatusIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              _buildWindowsStatusInfo(),
              const SizedBox(height: 16),
              _buildWindowsPerformanceInfo(),
            ],
          ),
        ),
      );

  /// بناء widget الافتراضي
  Widget _buildDefaultWidget(BuildContext context) => Card(
        margin: const EdgeInsets.all(8.0),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header with animated icon
              Row(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (BuildContext context, Widget? child) =>
                        Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (BuildContext context, Widget? child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Icon(
                              Icons.sync,
                              color: _isListening ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'حالة التحديثات الفورية',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Performance indicator
                  _buildPerformanceIndicator(),
                ],
              ),
              const SizedBox(height: 16),

              // Status cards
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatusCard(
                      'الاتصال',
                      _isOnline ? 'متصل' : 'غير متصل',
                      _isOnline ? Colors.green : Colors.red,
                      _isOnline ? Icons.wifi : Icons.wifi_off,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      'التحديثات',
                      _isListening ? 'مفعلة' : 'معطلة',
                      _isListening ? Colors.green : Colors.orange,
                      _isListening ? Icons.sync : Icons.sync_disabled,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Performance stats
              if (_performanceStats.isNotEmpty) ...<Widget>[
                _buildPerformanceStats(),
                const SizedBox(height: 12),
              ],

              // Recent updates
              if (_recentUpdates.isNotEmpty) ...<Widget>[
                _buildRecentUpdates(),
                const SizedBox(height: 12),
              ],

              // Callbacks stats
              _buildCallbacksStats(),

              const SizedBox(height: 12),

              // Control buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isListening ? null : _startRealtimeUpdates,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('بدء التحديثات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isListening ? _stopRealtimeUpdates : null,
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('إيقاف التحديثات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// بناء بطاقة الحالة
  Widget _buildStatusCard(
          String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );

  /// بناء مؤشر الأداء
  Widget _buildPerformanceIndicator() {
    final double successRate =
        (_performanceStats['successRate'] as double?) ?? 0.0;
    final Color indicatorColor = successRate >= 90
        ? Colors.green
        : successRate >= 70
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.trending_up, size: 16, color: indicatorColor),
          const SizedBox(width: 4),
          Text(
            '${successRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: indicatorColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إحصائيات الأداء
  Widget _buildPerformanceStats() {
    final int totalUpdates = (_performanceStats['totalUpdates'] as int?) ?? 0;
    final int successCount = (_performanceStats['successCount'] as int?) ?? 0;
    final int failureCount = (_performanceStats['failureCount'] as int?) ?? 0;
    final int avgResponseTime =
        (_performanceStats['avgResponseTime'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'إحصائيات الأداء',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildStatItem('إجمالي', totalUpdates.toString(), Colors.blue),
              _buildStatItem('نجح', successCount.toString(), Colors.green),
              _buildStatItem('فشل', failureCount.toString(), Colors.red),
              _buildStatItem(
                  'متوسط الاستجابة', '${avgResponseTime}ms', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء آخر التحديثات
  Widget _buildRecentUpdates() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'آخر التحديثات',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...(_recentUpdates.take(3).map((UpdateLog log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        log.isSuccessful ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: log.isSuccessful ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.message,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        log.formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ))),
          ],
        ),
      );

  /// بناء إحصائيات Callbacks
  Widget _buildCallbacksStats() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'إحصائيات التحديثات:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildCallbackStat('المنتجات', _productCallbacks, Colors.blue),
                _buildCallbackStat(
                    'المخزون', _inventoryCallbacks, Colors.orange),
                _buildCallbackStat(
                    'الاتصال', _connectionCallbacks, Colors.purple),
              ],
            ),
          ],
        ),
      );

  /// بناء عنصر إحصائية
  Widget _buildStatItem(String label, String value, Color color) => Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

  Widget _buildCallbackStat(String label, int count, Color color) => Column(
        children: <Widget>[
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

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

  // ========== دوال محسنة لـ Windows ==========

  /// بناء مؤشر الحالة لـ Windows
  Widget _buildWindowsStatusIndicator() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isListening ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isListening ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isListening ? 'نشط' : 'معطل',
            style: TextStyle(
              color:
                  _isListening ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

  /// بناء معلومات الحالة لـ Windows
  Widget _buildWindowsStatusInfo() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'معلومات النظام',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildWindowsInfoItem(
                  'الاتصال',
                  _isOnline ? 'متصل' : 'غير متصل',
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  _isOnline ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWindowsInfoItem(
                  'المزامنة',
                  'دورية (10 ث)',
                  Icons.sync,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildWindowsInfoItem(
                  'Callbacks',
                  '${_productCallbacks + _inventoryCallbacks + _connectionCallbacks}',
                  Icons.call_made,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWindowsInfoItem(
                  'الأداء',
                  'محسن',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );

  /// بناء معلومات الأداء لـ Windows
  Widget _buildWindowsPerformanceInfo() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.analytics, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'إحصائيات الأداء - Windows',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_performanceStats.isNotEmpty) ...<Widget>[
            _buildWindowsStatRow('المزامنات الناجحة',
                '${_performanceStats['successCount'] ?? 0}'),
            _buildWindowsStatRow('المزامنات الفاشلة',
                '${_performanceStats['failureCount'] ?? 0}'),
            _buildWindowsStatRow('متوسط وقت الاستجابة',
                '${_performanceStats['avgResponseTime'] ?? '0'}ms'),
          ] else ...<Widget>[
            const Text('جاري تحميل الإحصائيات...'),
          ],
        ],
      ),
    );

  /// بناء عنصر معلومات لـ Windows
  Widget _buildWindowsInfoItem(
      String label, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

  /// بناء صف إحصائية لـ Windows
  Widget _buildWindowsStatRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
          ),
        ],
      ),
    );
}
