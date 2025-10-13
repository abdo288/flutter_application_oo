import 'package:flutter/material.dart';
import '../database/drift_database.dart';
import '../services/unified_sync_manager.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  bool _isSyncing = false;
  int _pendingOperations = 0;

  @override
  void initState() {
    super.initState();
    _checkSyncStatus();
  }

  Future<void> _checkSyncStatus() async {
    try {
      final AppDatabase db = AppDatabase.instance;
      final int pendingCount = await db.getUnprocessedOperationsCount();

      if (mounted) {
        setState(() {
          _pendingOperations = pendingCount;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة المزامنة: $e');
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final UnifiedSyncManager syncManager = UnifiedSyncManager();
      await syncManager.performImmediateSync();

      // إعادة فحص الحالة
      await _checkSyncStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تشغيل المزامنة'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المزامنة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingOperations == 0 && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isSyncing ? Colors.blue : Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_isSyncing) ...<Widget>[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'جاري المزامنة...',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ] else ...<Widget>[
            const Icon(
              Icons.sync_problem,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              '$_pendingOperations عملية معلقة',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _triggerSync,
              child: const Icon(
                Icons.sync,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
