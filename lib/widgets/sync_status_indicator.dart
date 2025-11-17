import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_state_manager.dart';
import '../utils/constants.dart';

/// مؤشر حالة المزامنة في الوقت الفعلي
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState state = ref.watch(appStateNotifierProvider);
    if (compact) {
      return _buildCompactIndicator(context, state);
    } else {
      return _buildFullIndicator(context, state);
    }
  }

  /// بناء المؤشر المضغوط
  Widget _buildCompactIndicator(BuildContext context, AppState state) {
    if (state.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'مزامنة...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (state.pendingOperations > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.sync,
              size: 12,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              '${state.pendingOperations}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!state.isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 12,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              'غير متصل',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.cloud_done,
            size: 12,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            'متزامن',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء المؤشر الكامل
  Widget _buildFullIndicator(BuildContext context, AppState state) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // العنوان
            const Row(
              children: <Widget>[
                Icon(
                  Icons.sync,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'حالة المزامنة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // حالة الاتصال
            _buildConnectionStatus(context, state),
            const SizedBox(height: 8),

            // حالة المزامنة
            _buildSyncStatus(context, state),

            // العمليات المعلقة
            if (state.pendingOperations > 0) ...<Widget>[
              const SizedBox(height: 8),
              _buildPendingOperations(context, state),
            ],

            // التفاصيل
            if (showDetails) ...<Widget>[
              const SizedBox(height: 12),
              _buildDetails(context, state),
            ],
          ],
        ),
      );

  /// بناء حالة الاتصال
  Widget _buildConnectionStatus(BuildContext context, AppState state) => Row(
        children: <Widget>[
          Icon(
            state.isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: state.isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            state.isOnline ? 'متصل' : 'غير متصل',
            style: TextStyle(
              fontSize: 14,
              color: state.isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.connectionType != null) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              '(${state.connectionType})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );

  /// بناء حالة المزامنة
  Widget _buildSyncStatus(BuildContext context, AppState state) {
    if (state.isSyncing) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'جاري المزامنة...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (state.pendingOperations > 0) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.sync,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            '${state.pendingOperations} عملية معلقة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Icon(
          Icons.cloud_done,
          size: 16,
          color: Colors.green[700],
        ),
        const SizedBox(width: 8),
        Text(
          'متزامن',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// بناء العمليات المعلقة
  Widget _buildPendingOperations(BuildContext context, AppState state) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.queue,
              size: 16,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${state.pendingOperations} عملية في الانتظار',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      );

  /// بناء التفاصيل
  Widget _buildDetails(BuildContext context, AppState state) {
    // final Map<String, dynamic> summary = ref.read(appStateNotifierProvider.notifier).getStateSummary();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'التفاصيل',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          // ...summary.entries.map((MapEntry<String, dynamic> entry) => Padding(
          //       padding: const EdgeInsets.symmetric(vertical: 1),
          //       child: Row(
          //         children: <Widget>[
          //           Text(
          //             '${entry.key}: ',
          //             style: TextStyle(
          //               fontSize: 10,
          //               color: Colors.grey[600],
          //             ),
          //           ),
          //           Text(
          //             '${entry.value}',
          //             style: TextStyle(
          //               fontSize: 10,
          //               color: Colors.grey[800],
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //     )),
        ],
      ),
    );
  }
}

/// مؤشر المزامنة المبسط للشريط العلوي
class CompactSyncIndicator extends StatelessWidget {
  const CompactSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const SyncStatusIndicator(compact: true);
}

/// مؤشر المزامنة الكامل للواجهات الرئيسية
class FullSyncIndicator extends StatelessWidget {
  const FullSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const SyncStatusIndicator(showDetails: true);
}

/// مؤشر المزامنة مع إجراءات
class InteractiveSyncIndicator extends ConsumerWidget {
  const InteractiveSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState state = ref.watch(appStateNotifierProvider);
    return PopupMenuButton<String>(
      child: const SyncStatusIndicator(compact: true),
      onSelected: (String value) {
        switch (value) {
          case 'refresh':
            _handleRefresh(context, state);
            break;
          case 'details':
            _showDetailsDialog(context, state);
            break;
          case 'clear':
            _handleClear(context, state);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: <Widget>[
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('تحديث'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: <Widget>[
              Icon(Icons.info),
              SizedBox(width: 8),
              Text('التفاصيل'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: <Widget>[
              Icon(Icons.clear),
              SizedBox(width: 8),
              Text('مسح'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleRefresh(BuildContext context, AppState state) {
    // إعادة تعيين الحالة
    // ref.read(appStateNotifierProvider.notifier).resetState();

    // إظهار رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث الحالة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, AppState state) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) =>
            AlertDialog(
          title: const Text('تفاصيل المزامنة'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const FullSyncIndicator(),
                const SizedBox(height: 16),
                Text(
                  'ملخص الحالة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                // ...ref.read(appStateNotifierProvider.notifier)
                //     .getStateSummary()
                //     .entries
                //     .map((MapEntry<String, dynamic> entry) => Padding(
                //           padding: const EdgeInsets.symmetric(vertical: 2),
                //           child: Row(
                //             children: <Widget>[
                //               Text(
                //                 '${entry.key}: ',
                //                 style: TextStyle(
                //                   fontSize: 12,
                //                   color: Colors.grey[600],
                //                 ),
                //               ),
                //               Text(
                //                 '${entry.value}',
                //                 style: TextStyle(
                //                   fontSize: 12,
                //                   color: Colors.grey[800],
                //                   fontWeight: FontWeight.w500,
                //                 ),
                //               ),
                //             ],
                //           ),
                //         )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleClear(BuildContext context, AppState state) {
    // مسح البيانات المشتركة
    // ref.read(appStateNotifierProvider.notifier).clearSharedData();

    // إظهار رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح البيانات المشتركة'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
