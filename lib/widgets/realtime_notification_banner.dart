import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/realtime_update_manager.dart';

/// بانر إشعارات التحديثات الفورية
class RealtimeNotificationBanner extends ConsumerWidget {
  const RealtimeNotificationBanner({
    super.key,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  });

  final VoidCallback? onDismiss;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isConnected = ref.watch(isConnectedProvider);
    final String? error = ref.watch(updateErrorProvider);
    final Map<String, int> updateStats = ref.watch(updateStatsProvider);

    // إظهار البانر فقط عند وجود تحديثات أو أخطاء
    if (!isConnected && error == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(16),
      child: _buildBanner(context, ref, isConnected, error, updateStats),
    );
  }

  Widget _buildBanner(
    BuildContext context,
    WidgetRef ref,
    bool isConnected,
    String? error,
    Map<String, int> updateStats,
  ) {
    if (error != null) {
      return _buildErrorBanner(context, ref, error);
    }

    if (!isConnected) {
      return _buildDisconnectedBanner(context, ref);
    }

    return _buildConnectedBanner(context, updateStats);
  }

  Widget _buildErrorBanner(BuildContext context, WidgetRef ref, String error) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'خطأ في التحديثات الفورية',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref
                  .read(realtimeUpdateManagerProvider.notifier)
                  .restartRealtimeUpdates();
              onDismiss?.call();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.red[600],
            ),
            tooltip: 'إعادة المحاولة',
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: Colors.red[600],
            ),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );

  Widget _buildDisconnectedBanner(BuildContext context, WidgetRef ref) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_off,
            color: Colors.orange[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'انقطع الاتصال',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'التحديثات الفورية غير متاحة حالياً',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref
                  .read(realtimeUpdateManagerProvider.notifier)
                  .restartRealtimeUpdates();
              onDismiss?.call();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.orange[600],
            ),
            tooltip: 'إعادة المحاولة',
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: Colors.orange[600],
            ),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );

  Widget _buildConnectedBanner(
      BuildContext context, Map<String, int> updateStats) {
    final int totalUpdates =
        updateStats.values.fold(0, (int sum, int count) => sum + count);

    if (totalUpdates == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_done,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'تم تحديث البيانات',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalUpdates تحديثات جديدة',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: Colors.green[600],
            ),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }
}

/// بانر تلقائي يظهر ويختفي
class AutoDismissRealtimeBanner extends ConsumerStatefulWidget {
  const AutoDismissRealtimeBanner({
    super.key,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  });

  final VoidCallback? onDismiss;
  final Duration duration;

  @override
  ConsumerState<AutoDismissRealtimeBanner> createState() =>
      _AutoDismissRealtimeBannerState();
}

class _AutoDismissRealtimeBannerState
    extends ConsumerState<AutoDismissRealtimeBanner> {
  Timer? _dismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: _isDismissed ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: RealtimeNotificationBanner(
        onDismiss: () {
          setState(() {
            _isDismissed = true;
          });
          widget.onDismiss?.call();
        },
        duration: widget.duration,
      ),
    );
  }
}
