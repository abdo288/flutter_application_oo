import 'package:flutter/material.dart';

import '../services/cleanup/models/cleanup_result.dart';
import '../services/cleanup/models/cleanup_stats.dart';
import '../services/cleanup/models/storage_info.dart';
import '../services/data_cleanup_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';

/// شاشة تنظيف البيانات المحلية
class DataCleanupScreen extends StatefulWidget {
  const DataCleanupScreen({super.key});

  @override
  State<DataCleanupScreen> createState() => _DataCleanupScreenState();
}

class _DataCleanupScreenState extends State<DataCleanupScreen> {
  final DataCleanupService _cleanupService = DataCleanupService();

  bool _isLoading = false;
  String? _lastResult;
  StorageInfo? _storageInfo;
  CleanupStats? _currentStats;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  /// تحميل معلومات التخزين
  Future<void> _loadStorageInfo() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      debugPrint('🔄 بدء تحميل معلومات التخزين...');
      final StorageInfo info = await _cleanupService.getStorageInfo();

      if (mounted) {
        setState(() => _storageInfo = info);
        debugPrint(
            '✅ تم تحميل معلومات التخزين: ${info.fileCount} ملف، ${info.formattedSize}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل معلومات التخزين: $e');
      _showError('خطأ في تحميل معلومات التخزين: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// عرض حوار تأكيد التنظيف
  Future<bool> _showCleanupConfirmation(String title, String message) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// عرض حوار اختيار نوع التنظيف
  Future<String?> _showCleanupTypeDialog() async => await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('اختر نوع التنظيف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.blue),
                title: const Text('تنظيف محلي فقط'),
                subtitle: const Text('حذف البيانات من الجهاز فقط'),
                onTap: () => Navigator.of(context).pop('local'),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.orange),
                title: const Text('تنظيف سحابي فقط'),
                subtitle: const Text('حذف البيانات من Firebase فقط'),
                onTap: () => Navigator.of(context).pop('cloud'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('تنظيف كامل'),
                subtitle: const Text('حذف البيانات من الجهاز والسحابة'),
                onTap: () => Navigator.of(context).pop('both'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );

  /// تنفيذ التنظيف الشامل
  Future<void> _performFullCleanup() async {
    // عرض خيارات التنظيف
    final String? cleanupType = await _showCleanupTypeDialog();
    if (cleanupType == null) return;

    String title = '';
    String message = '';
    bool includeFirestore = false;

    switch (cleanupType) {
      case 'local':
        title = 'تنظيف شامل محلي';
        message = 'سيتم حذف جميع البيانات المحلية فقط. هل أنت متأكد؟';
        includeFirestore = false;
        break;
      case 'cloud':
        title = 'تنظيف شامل سحابي';
        message =
            'سيتم حذف جميع البيانات من Firebase Firestore فقط. هل أنت متأكد؟';
        includeFirestore = false; // سيتم استخدام performFirestoreCleanup
        break;
      case 'both':
        title = 'تنظيف شامل كامل';
        message = 'سيتم حذف جميع البيانات المحلية والسحابية. هل أنت متأكد؟';
        includeFirestore = true;
        break;
    }

    final bool confirmed = await _showCleanupConfirmation(title, message);
    if (!confirmed) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      CleanupResult result;
      if (cleanupType == 'cloud') {
        result = await _cleanupService.performFirestoreCleanup();
      } else {
        result = await _cleanupService.performFullCleanup(
            includeFirestore: includeFirestore);
      }

      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess(result.message);
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في التنظيف الشامل: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تنظيف البيانات غير المزامنة
  Future<void> _cleanupUnsyncedData() async {
    final bool confirmed = await _showCleanupConfirmation(
      'تنظيف البيانات غير المزامنة',
      'سيتم حذف البيانات التي لم يتم مزامنتها مع السحابة. هل أنت متأكد؟',
    );

    if (!confirmed) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final CleanupResult result = await _cleanupService.cleanupUnsyncedData();
      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess('تم تنظيف البيانات غير المزامنة بنجاح');
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في تنظيف البيانات غير المزامنة: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تنظيف العمليات المعالجة
  Future<void> _cleanupProcessedOperations() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final CleanupResult result =
          await _cleanupService.cleanupProcessedSyncOperations();
      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess('تم تنظيف العمليات المعالجة بنجاح');
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في تنظيف العمليات المعالجة: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تنظيف البيانات القديمة
  Future<void> _cleanupOldData() async {
    final bool confirmed = await _showCleanupConfirmation(
      'تنظيف البيانات القديمة',
      'سيتم حذف البيانات الأقدم من 30 يوم. هل أنت متأكد؟',
    );

    if (!confirmed) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final CleanupResult result = await _cleanupService.cleanupOldData();
      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess('تم تنظيف البيانات القديمة بنجاح');
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في تنظيف البيانات القديمة: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تنظيف الملفات المؤقتة
  Future<void> _cleanupDatabaseFiles() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final CleanupResult result = await _cleanupService.cleanupDatabaseFiles();
      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess('تم تنظيف الملفات المؤقتة بنجاح');
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في تنظيف الملفات المؤقتة: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// التنظيف الذكي
  Future<void> _performSmartCleanup() async {
    final bool confirmed = await _showCleanupConfirmation(
      'تنظيف ذكي',
      'سيتم تنظيف البيانات غير المهمة فقط. هل أنت متأكد؟',
    );

    if (!confirmed) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final CleanupResult result = await _cleanupService.performSmartCleanup();
      if (mounted) {
        setState(() {
          _lastResult = result.message;
          _currentStats = result.stats;
        });
      }

      if (result.success) {
        _showSuccess('تم التنظيف الذكي بنجاح');
        await _loadStorageInfo();
        if (mounted) {
          setState(() {}); // تحديث الواجهة لإظهار الإحصائيات الجديدة
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('خطأ في التنظيف الذكي: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('تنظيف البيانات المحلية'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: LoadingWidget(message: 'جاري التنظيف...'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // معلومات التخزين
                    _buildStorageInfoCard(),
                    const SizedBox(height: 16),

                    // إحصائيات التنظيف الأخيرة
                    if (_currentStats != null) _buildCleanupStatsCard(),
                    if (_currentStats != null) const SizedBox(height: 16),

                    // خيارات التنظيف
                    _buildCleanupOptionsCard(),
                    const SizedBox(height: 16),

                    // نتيجة العملية الأخيرة
                    if (_lastResult != null) _buildLastResultCard(),
                  ],
                ),
              ),
      );

  /// بناء بطاقة معلومات التخزين
  Widget _buildStorageInfoCard() => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.storage, color: AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'معلومات التخزين',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadStorageInfo,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_storageInfo != null) ...<Widget>[
                _buildInfoRow(
                    'إجمالي المساحة المستخدمة', _storageInfo!.formattedSize),
                _buildInfoRow(
                    'عدد الملفات', _storageInfo!.fileCount.toString()),
                if (_storageInfo!.fileDetails.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    'تفاصيل الملفات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...(_storageInfo!.fileDetails.map(
                    (String detail) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        detail,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )),
                ],
              ] else
                const Text('جاري تحميل معلومات التخزين...'),
            ],
          ),
        ),
      );

  /// بناء بطاقة إحصائيات التنظيف
  Widget _buildCleanupStatsCard() {
    if (_currentStats == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.analytics, color: AppConstants.primaryColor),
                SizedBox(width: 8),
                Text(
                  'إحصائيات التنظيف الأخيرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentStats!.productsDeleted > 0)
              _buildInfoRow('المنتجات المحذوفة',
                  _currentStats!.productsDeleted.toString()),
            if (_currentStats!.inventoryItemsDeleted > 0)
              _buildInfoRow('عناصر المخزون المحذوفة',
                  _currentStats!.inventoryItemsDeleted.toString()),
            if (_currentStats!.salesDeleted > 0)
              _buildInfoRow(
                  'المبيعات المحذوفة', _currentStats!.salesDeleted.toString()),
            if (_currentStats!.syncOperationsDeleted > 0)
              _buildInfoRow('عمليات المزامنة المحذوفة',
                  _currentStats!.syncOperationsDeleted.toString()),
            if (_currentStats!.additionalInfo != null)
              _buildInfoRow('معلومات إضافية', _currentStats!.additionalInfo!),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة خيارات التنظيف
  Widget _buildCleanupOptionsCard() => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.cleaning_services,
                      color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'خيارات التنظيف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // التنظيف الذكي
              _buildCleanupButton(
                title: 'تنظيف ذكي',
                subtitle: 'تنظيف البيانات غير المهمة فقط',
                icon: Icons.auto_fix_high,
                color: Colors.green,
                onPressed: _performSmartCleanup,
              ),
              const SizedBox(height: 12),

              // تنظيف البيانات غير المزامنة
              _buildCleanupButton(
                title: 'تنظيف البيانات غير المزامنة',
                subtitle: 'حذف البيانات التي لم يتم مزامنتها',
                icon: Icons.sync_problem,
                color: Colors.orange,
                onPressed: _cleanupUnsyncedData,
              ),
              const SizedBox(height: 12),

              // تنظيف العمليات المعالجة
              _buildCleanupButton(
                title: 'تنظيف العمليات المعالجة',
                subtitle: 'حذف عمليات المزامنة المعالجة',
                icon: Icons.queue,
                color: Colors.blue,
                onPressed: _cleanupProcessedOperations,
              ),
              const SizedBox(height: 12),

              // تنظيف البيانات القديمة
              _buildCleanupButton(
                title: 'تنظيف البيانات القديمة',
                subtitle: 'حذف البيانات الأقدم من 30 يوم',
                icon: Icons.history,
                color: Colors.purple,
                onPressed: _cleanupOldData,
              ),
              const SizedBox(height: 12),

              // تنظيف الملفات المؤقتة
              _buildCleanupButton(
                title: 'تنظيف الملفات المؤقتة',
                subtitle: 'حذف ملفات قاعدة البيانات المؤقتة',
                icon: Icons.file_copy,
                color: Colors.teal,
                onPressed: _cleanupDatabaseFiles,
              ),
              const SizedBox(height: 16),

              // التنظيف الشامل
              const Divider(),
              const SizedBox(height: 8),
              _buildCleanupButton(
                title: 'تنظيف شامل',
                subtitle: 'حذف البيانات المحلية و/أو السحابية (خطير)',
                icon: Icons.warning,
                color: Colors.red,
                onPressed: _performFullCleanup,
              ),
            ],
          ),
        ),
      );

  /// بناء بطاقة نتيجة العملية الأخيرة
  Widget _buildLastResultCard() => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.info, color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'نتيجة العملية الأخيرة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_lastResult!),
            ],
          ),
        ),
      );

  /// بناء زر التنظيف
  Widget _buildCleanupButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      );

  /// بناء صف معلومات
  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
