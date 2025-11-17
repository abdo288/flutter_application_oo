import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/realtime_update_manager.dart';

/// مؤشر حالة التحديثات الفورية
class RealtimeStatusIndicator extends ConsumerWidget {
  const RealtimeStatusIndicator({
    super.key,
    this.position = const Alignment(0.95, -0.9),
    this.showDetails = false,
  });

  final Alignment position;
  final bool showDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isConnected = ref.watch(isConnectedProvider);
    final DateTime? lastUpdateTime = ref.watch(lastUpdateTimeProvider);
    final Map<String, int> updateStats = ref.watch(updateStatsProvider);
    final String? error = ref.watch(updateErrorProvider);

    if (!isConnected && error == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 60,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _buildIndicator(
          context,
          isConnected,
          lastUpdateTime,
          updateStats,
          error,
        ),
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    bool isConnected,
    DateTime? lastUpdateTime,
    Map<String, int> updateStats,
    String? error,
  ) {
    if (error != null) {
      return _buildErrorIndicator(context, error);
    }

    if (!isConnected) {
      return _buildDisconnectedIndicator(context);
    }

    if (lastUpdateTime == null) {
      return _buildLoadingIndicator(context);
    }

    return _buildConnectedIndicator(context, lastUpdateTime, updateStats);
  }

  Widget _buildErrorIndicator(BuildContext context, String error) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'خطأ في التحديث',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildDisconnectedIndicator(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'غير متصل',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildLoadingIndicator(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'جاري التوصيل...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildConnectedIndicator(
    BuildContext context,
    DateTime lastUpdateTime,
    Map<String, int> updateStats,
  ) {
    final Duration timeSinceUpdate = DateTime.now().difference(lastUpdateTime);
    final String timeText = _formatTimeSinceUpdate(timeSinceUpdate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: showDetails
          ? _buildDetailedIndicator(context, timeText, updateStats)
          : _buildSimpleIndicator(context, timeText),
    );
  }

  Widget _buildSimpleIndicator(BuildContext context, String timeText) => Row(
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
    );

  Widget _buildDetailedIndicator(
    BuildContext context,
    String timeText,
    Map<String, int> updateStats,
  ) {
    final int totalUpdates =
        updateStats.values.fold(0, (int sum, int count) => sum + count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
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
        if (totalUpdates > 0) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            '$totalUpdates تحديثات',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimeSinceUpdate(Duration duration) {
    if (duration.inSeconds < 60) {
      return 'منذ ${duration.inSeconds} ثانية';
    } else if (duration.inMinutes < 60) {
      return 'منذ ${duration.inMinutes} دقيقة';
    } else if (duration.inHours < 24) {
      return 'منذ ${duration.inHours} ساعة';
    } else {
      return 'منذ ${duration.inDays} يوم';
    }
  }
}

/// مؤشر مبسط للحالة
class SimpleRealtimeIndicator extends ConsumerWidget {
  const SimpleRealtimeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isConnected = ref.watch(isConnectedProvider);
    final String? error = ref.watch(updateErrorProvider);

    if (error != null) {
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 16,
      );
    }

    if (!isConnected) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.orange,
        size: 16,
      );
    }

    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}
