import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state_manager.dart';
import '../utils/constants.dart';

/// مؤشر حالة المزامنة في الوقت الفعلي
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context) => Consumer<AppStateManager>(
        builder: (context, stateManager, child) {
          if (compact) {
            return _buildCompactIndicator(context, stateManager);
          } else {
            return _buildFullIndicator(context, stateManager);
          }
        },
      );

  /// بناء المؤشر المضغوط
  Widget _buildCompactIndicator(
      BuildContext context, AppStateManager stateManager) {
    if (stateManager.isSyncing) {
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

    if (stateManager.pendingOperations > 0) {
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
              '${stateManager.pendingOperations}',
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

    if (!stateManager.isOnline) {
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
  Widget _buildFullIndicator(
          BuildContext context, AppStateManager stateManager) =>
      Container(
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
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
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
            _buildConnectionStatus(context, stateManager),
            const SizedBox(height: 8),

            // حالة المزامنة
            _buildSyncStatus(context, stateManager),

            // العمليات المعلقة
            if (stateManager.pendingOperations > 0) ...[
              const SizedBox(height: 8),
              _buildPendingOperations(context, stateManager),
            ],

            // التفاصيل
            if (showDetails) ...[
              const SizedBox(height: 12),
              _buildDetails(context, stateManager),
            ],
          ],
        ),
      );

  /// بناء حالة الاتصال
  Widget _buildConnectionStatus(
          BuildContext context, AppStateManager stateManager) =>
      Row(
        children: [
          Icon(
            stateManager.isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: stateManager.isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            stateManager.isOnline ? 'متصل' : 'غير متصل',
            style: TextStyle(
              fontSize: 14,
              color: stateManager.isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (stateManager.connectionType != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${stateManager.connectionType})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );

  /// بناء حالة المزامنة
  Widget _buildSyncStatus(BuildContext context, AppStateManager stateManager) {
    if (stateManager.isSyncing) {
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

    if (stateManager.pendingOperations > 0) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.sync,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            '${stateManager.pendingOperations} عملية معلقة',
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
  Widget _buildPendingOperations(
          BuildContext context, AppStateManager stateManager) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.queue,
              size: 16,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${stateManager.pendingOperations} عملية في الانتظار',
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
  Widget _buildDetails(BuildContext context, AppStateManager stateManager) {
    final Map<String, dynamic> summary = stateManager.getStateSummary();

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
          ...summary.entries.map((MapEntry<String, dynamic> entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: <Widget>[
                    Text(
                      '${entry.key}: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
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
class InteractiveSyncIndicator extends StatelessWidget {
  const InteractiveSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppStateManager>(
        builder: (context, stateManager, child) {
          return PopupMenuButton<String>(
            child: const SyncStatusIndicator(compact: true),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _handleRefresh(context, stateManager);
                  break;
                case 'details':
                  _showDetailsDialog(context, stateManager);
                  break;
                case 'clear':
                  _handleClear(context, stateManager);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('تحديث'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('التفاصيل'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('مسح'),
                  ],
                ),
              ),
            ],
          );
        },
      );

  void _handleRefresh(BuildContext context, AppStateManager stateManager) {
    // إعادة تعيين الحالة
    stateManager.resetState();

    // إظهار رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث الحالة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, AppStateManager stateManager) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
              ...stateManager
                  .getStateSummary()
                  .entries
                  .map((MapEntry<String, dynamic> entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: <Widget>[
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
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
    );
  }

  void _handleClear(BuildContext context, AppStateManager stateManager) {
    // مسح البيانات المشتركة
    stateManager.clearSharedData();

    // إظهار رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح البيانات المشتركة'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
