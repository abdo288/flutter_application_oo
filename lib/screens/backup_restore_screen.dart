import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/stream_app_provider.dart';
import '../services/backup_service.dart';
import '../services/restore_service.dart';
import '../utils/constants.dart';

/// شاشة النسخ الاحتياطي واستعادة البيانات
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<BackupInfo> _localBackups = <BackupInfo>[];
  List<RestoreHistory> _restoreHistory = <RestoreHistory>[];

  // إعدادات النسخ الاحتياطي
  bool _autoBackupEnabled = false;
  int _backupFrequency = 7;
  bool _cloudBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل البيانات والإعدادات
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await BackupService.initialize();

      _autoBackupEnabled = BackupService.autoBackupEnabled;
      _backupFrequency = BackupService.backupFrequency;
      _cloudBackupEnabled = BackupService.cloudBackupEnabled;

      _localBackups = await BackupService.getLocalBackups();
      _restoreHistory = await RestoreService.getRestoreHistory();
    } catch (e) {
      _showErrorDialog('خطأ في تحميل البيانات', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('النسخ الاحتياطي والاستعادة'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const <Widget>[
              Tab(text: 'النسخ الاحتياطي', icon: Icon(Icons.backup)),
              Tab(text: 'الاستعادة', icon: Icon(Icons.restore)),
              Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildBackupTab(),
                  _buildRestoreTab(),
                  _buildSettingsTab(),
                ],
              ),
      );

  /// تبويب النسخ الاحتياطي
  Widget _buildBackupTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // معلومات آخر نسخة احتياطية
            _buildLastBackupInfo(),
            const SizedBox(height: 20),

            // أزرار النسخ الاحتياطي
            _buildBackupButtons(),
            const SizedBox(height: 20),

            // قائمة النسخ الاحتياطية المحلية
            _buildLocalBackupsList(),
          ],
        ),
      );

  /// تبويب الاستعادة
  Widget _buildRestoreTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // أزرار الاستعادة
            _buildRestoreButtons(),
            const SizedBox(height: 20),

            // قائمة النسخ الاحتياطية للاستعادة
            _buildBackupsForRestore(),
            const SizedBox(height: 20),

            // تاريخ عمليات الاستعادة
            _buildRestoreHistory(),
          ],
        ),
      );

  /// تبويب الإعدادات
  Widget _buildSettingsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // إعدادات النسخ الاحتياطي التلقائي
            _buildAutoBackupSettings(),
            const SizedBox(height: 20),

            // إعدادات النسخ الاحتياطي السحابي
            _buildCloudBackupSettings(),
            const SizedBox(height: 20),

            // إعدادات إضافية
            _buildAdditionalSettings(),
          ],
        ),
      );

  /// معلومات آخر نسخة احتياطية
  Widget _buildLastBackupInfo() {
    final DateTime? lastBackup = BackupService.lastBackupTime;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.info_outline, color: AppConstants.primaryColor),
                SizedBox(width: 8),
                Text(
                  'معلومات آخر نسخة احتياطية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastBackup != null) ...<Widget>[
              Text(
                  'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(lastBackup)}'),
              const SizedBox(height: 4),
              Text('المدة: ${_getTimeAgo(lastBackup)}'),
            ] else ...<Widget>[
              const Text('لم يتم إنشاء نسخة احتياطية بعد'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _createFullBackup,
                icon: const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// أزرار النسخ الاحتياطي
  Widget _buildBackupButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'إنشاء نسخة احتياطية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // نسخة احتياطية شاملة
          ElevatedButton.icon(
            onPressed: _createFullBackup,
            icon: const Icon(Icons.backup),
            label: const Text('نسخة احتياطية شاملة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // نسخة احتياطية للمنتجات فقط
          OutlinedButton.icon(
            onPressed: _createProductsBackup,
            icon: const Icon(Icons.inventory),
            label: const Text('نسخة احتياطية للمنتجات فقط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // نسخة احتياطية للمخزون فقط
          OutlinedButton.icon(
            onPressed: _createInventoryBackup,
            icon: const Icon(Icons.warehouse),
            label: const Text('نسخة احتياطية للمخزون فقط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      );

  /// قائمة النسخ الاحتياطية المحلية
  Widget _buildLocalBackupsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'النسخ الاحتياطية المحلية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_localBackups.isNotEmpty)
                TextButton.icon(
                  onPressed: _refreshBackups,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_localBackups.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'لا توجد نسخ احتياطية محلية',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._localBackups.map(_buildBackupCard),
        ],
      );

  /// بطاقة النسخة الاحتياطية
  Widget _buildBackupCard(BackupInfo backup) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            _getBackupIcon(backup.type),
            color: AppConstants.primaryColor,
          ),
          title: Text(backup.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('النوع: ${_getBackupTypeName(backup.type)}'),
              Text('الحجم: ${backup.formattedSize}'),
              Text('التاريخ: ${backup.formattedDate}'),
              Text('عدد البيانات: ${backup.dataCount}'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (String value) => _handleBackupAction(value, backup),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('مشاركة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('حذف'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      );

  /// أزرار الاستعادة
  Widget _buildRestoreButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'استعادة البيانات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // استعادة من ملف
          ElevatedButton.icon(
            onPressed: _restoreFromFile,
            icon: const Icon(Icons.file_upload),
            label: const Text('استعادة من ملف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // استعادة من السحابة
          OutlinedButton.icon(
            onPressed: _restoreFromCloud,
            icon: const Icon(Icons.cloud_download),
            label: const Text('استعادة من السحابة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      );

  /// قائمة النسخ الاحتياطية للاستعادة
  Widget _buildBackupsForRestore() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'النسخ الاحتياطية المتاحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_localBackups.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'لا توجد نسخ احتياطية للاستعادة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._localBackups.map(_buildRestoreBackupCard),
        ],
      );

  /// بطاقة النسخة الاحتياطية للاستعادة
  Widget _buildRestoreBackupCard(BackupInfo backup) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            _getBackupIcon(backup.type),
            color: AppConstants.primaryColor,
          ),
          title: Text(backup.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('النوع: ${_getBackupTypeName(backup.type)}'),
              Text('التاريخ: ${backup.formattedDate}'),
              Text('عدد البيانات: ${backup.dataCount}'),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () => _restoreFromBackup(backup),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('استعادة'),
          ),
        ),
      );

  /// تاريخ عمليات الاستعادة
  Widget _buildRestoreHistory() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'تاريخ عمليات الاستعادة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_restoreHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearRestoreHistory,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('مسح التاريخ'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_restoreHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'لا توجد عمليات استعادة سابقة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._restoreHistory.take(10).map(_buildHistoryCard),
        ],
      );

  /// بطاقة تاريخ الاستعادة
  Widget _buildHistoryCard(RestoreHistory history) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            history.success ? Icons.check_circle : Icons.error,
            color: history.success ? Colors.green : Colors.red,
          ),
          title: Text(history.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('التاريخ: ${history.formattedDate}'),
              Text('تم استعادة: ${history.restoredCount} عنصر'),
              if (history.skippedCount > 0)
                Text('تم تخطي: ${history.skippedCount} عنصر'),
              if (history.errorCount > 0)
                Text('أخطاء: ${history.errorCount} عنصر',
                    style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );

  /// إعدادات النسخ الاحتياطي التلقائي
  Widget _buildAutoBackupSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'النسخ الاحتياطي التلقائي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // تفعيل النسخ الاحتياطي التلقائي
              SwitchListTile(
                title: const Text('تفعيل النسخ الاحتياطي التلقائي'),
                subtitle:
                    const Text('إنشاء نسخة احتياطية تلقائياً حسب الجدولة'),
                value: _autoBackupEnabled,
                onChanged: (bool value) async {
                  setState(() => _autoBackupEnabled = value);
                  await BackupService.setAutoBackupEnabled(value);
                  _showSuccessMessage(
                      'تم تحديث إعدادات النسخ الاحتياطي التلقائي');
                },
                activeThumbColor: AppConstants.primaryColor,
              ),

              // تكرار النسخ الاحتياطي
              if (_autoBackupEnabled) ...<Widget>[
                const SizedBox(height: 16),
                const Text('تكرار النسخ الاحتياطي:'),
                Slider(
                  value: _backupFrequency.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: 'كل $_backupFrequency أيام',
                  onChanged: (double value) async {
                    setState(() => _backupFrequency = value.round());
                    await BackupService.setBackupFrequency(_backupFrequency);
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ],
          ),
        ),
      );

  /// إعدادات النسخ الاحتياطي السحابي
  Widget _buildCloudBackupSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'النسخ الاحتياطي السحابي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // تفعيل النسخ الاحتياطي السحابي
              SwitchListTile(
                title: const Text('تفعيل النسخ الاحتياطي السحابي'),
                subtitle:
                    const Text('رفع النسخ الاحتياطية إلى Firebase Storage'),
                value: _cloudBackupEnabled,
                onChanged: (bool value) async {
                  setState(() => _cloudBackupEnabled = value);
                  await BackupService.setCloudBackupEnabled(value);
                  _showSuccessMessage(
                      'تم تحديث إعدادات النسخ الاحتياطي السحابي');
                },
                activeThumbColor: AppConstants.primaryColor,
              ),

              if (_cloudBackupEnabled) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'النسخ الاحتياطية السحابية تتطلب اتصال بالإنترنت ومساحة تخزين في Firebase',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  /// إعدادات إضافية
  Widget _buildAdditionalSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'إعدادات إضافية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // إنشاء نسخة احتياطية تلقائية الآن
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('إنشاء نسخة احتياطية تلقائية الآن'),
                subtitle: const Text('فحص الحاجة لنسخة احتياطية تلقائية'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _createAutoBackup,
              ),

              const Divider(),

              // مسح جميع النسخ الاحتياطية المحلية
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('مسح جميع النسخ الاحتياطية المحلية'),
                subtitle:
                    const Text('حذف جميع النسخ الاحتياطية المحفوظة محلياً'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _clearAllLocalBackups,
              ),
            ],
          ),
        ),
      );

  // ========== دوال العمليات ==========

  /// إنشاء نسخة احتياطية شاملة
  Future<void> _createFullBackup() async {
    setState(() => _isLoading = true);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final BackupResult result = await BackupService.createFullBackupStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
        includeCloud: _cloudBackupEnabled,
      );

      if (result.success) {
        _showSuccessDialog(
          'تم إنشاء النسخة الاحتياطية بنجاح',
          'تم حفظ ${result.dataCount} عنصر في النسخة الاحتياطية',
        );
        await _loadData();
      } else {
        _showErrorDialog(
            'فشل في إنشاء النسخة الاحتياطية', result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في إنشاء النسخة الاحتياطية', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// إنشاء نسخة احتياطية للمنتجات
  Future<void> _createProductsBackup() async {
    setState(() => _isLoading = true);

    try {
      final BackupResult result = await BackupService.createProductsBackup();

      if (result.success) {
        _showSuccessMessage('تم إنشاء نسخة احتياطية للمنتجات بنجاح');
        await _loadData();
      } else {
        _showErrorDialog('فشل في إنشاء نسخة احتياطية للمنتجات',
            result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في إنشاء نسخة احتياطية للمنتجات', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// إنشاء نسخة احتياطية للمخزون
  Future<void> _createInventoryBackup() async {
    setState(() => _isLoading = true);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final BackupResult result =
          await BackupService.createInventoryBackupStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
      );

      if (result.success) {
        _showSuccessMessage('تم إنشاء نسخة احتياطية للمخزون بنجاح');
        await _loadData();
      } else {
        _showErrorDialog('فشل في إنشاء نسخة احتياطية للمخزون',
            result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في إنشاء نسخة احتياطية للمخزون', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// استعادة من ملف
  Future<void> _restoreFromFile() async {
    final bool? shouldBackup = await _showConfirmDialog(
      'إنشاء نسخة احتياطية قبل الاستعادة؟',
      'يُنصح بإنشاء نسخة احتياطية قبل الاستعادة لحماية البيانات الحالية',
    );

    if (shouldBackup == null) return;

    setState(() => _isLoading = true);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final RestoreResult result =
          await RestoreService.restoreFromUserFileStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
        backupBeforeRestore: shouldBackup,
      );

      if (result.success) {
        _showSuccessDialog(
          'تمت الاستعادة بنجاح',
          result.summary,
        );
        await _loadData();
      } else {
        _showErrorDialog('فشل في الاستعادة', result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في الاستعادة', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// استعادة من السحابة
  Future<void> _restoreFromCloud() async {
    // يمكن إضافة واجهة لإدخال رابط السحابة
    _showInfoDialog('قريباً', 'هذه الميزة ستكون متاحة قريباً');
  }

  /// استعادة من نسخة احتياطية محددة
  Future<void> _restoreFromBackup(BackupInfo backup) async {
    final bool? shouldBackup = await _showConfirmDialog(
      'إنشاء نسخة احتياطية قبل الاستعادة؟',
      'يُنصح بإنشاء نسخة احتياطية قبل الاستعادة لحماية البيانات الحالية',
    );

    if (shouldBackup == null) return;

    setState(() => _isLoading = true);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final RestoreResult result = await RestoreService.restoreFromFileStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
        filePath: backup.filePath,
        backupBeforeRestore: shouldBackup,
      );

      if (result.success) {
        _showSuccessDialog(
          'تمت الاستعادة بنجاح',
          result.summary,
        );
        await _loadData();
      } else {
        _showErrorDialog('فشل في الاستعادة', result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في الاستعادة', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// إنشاء نسخة احتياطية تلقائية
  Future<void> _createAutoBackup() async {
    setState(() => _isLoading = true);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      await BackupService.createAutoBackupStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
      );
      _showSuccessMessage('تم فحص الحاجة للنسخة الاحتياطية التلقائية');
      await _loadData();
    } catch (e) {
      _showErrorDialog('خطأ في النسخ الاحتياطي التلقائي', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// تحديث قائمة النسخ الاحتياطية
  Future<void> _refreshBackups() async {
    await _loadData();
  }

  /// مسح تاريخ الاستعادة
  Future<void> _clearRestoreHistory() async {
    final bool? confirmed = await _showConfirmDialog(
      'مسح تاريخ الاستعادة؟',
      'هل أنت متأكد من مسح جميع سجلات عمليات الاستعادة؟',
    );

    if (confirmed == true) {
      await RestoreService.clearRestoreHistory();
      await _loadData();
      _showSuccessMessage('تم مسح تاريخ الاستعادة');
    }
  }

  /// مسح جميع النسخ الاحتياطية المحلية
  Future<void> _clearAllLocalBackups() async {
    final bool? confirmed = await _showConfirmDialog(
      'مسح جميع النسخ الاحتياطية؟',
      'هل أنت متأكد من حذف جميع النسخ الاحتياطية المحلية؟ لا يمكن التراجع عن هذا الإجراء.',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        for (final BackupInfo backup in _localBackups) {
          await BackupService.deleteLocalBackup(backup.filePath);
        }

        await _loadData();
        _showSuccessMessage('تم مسح جميع النسخ الاحتياطية المحلية');
      } catch (e) {
        _showErrorDialog('خطأ في مسح النسخ الاحتياطية', e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// معالجة إجراءات النسخة الاحتياطية
  Future<void> _handleBackupAction(String action, BackupInfo backup) async {
    switch (action) {
      case 'share':
        final bool success = await BackupService.shareBackup(backup.filePath);
        if (success) {
          _showSuccessMessage('تم فتح خيارات المشاركة');
        } else {
          _showErrorDialog(
              'خطأ في المشاركة', 'فشل في مشاركة النسخة الاحتياطية');
        }
        break;

      case 'delete':
        final bool? confirmed = await _showConfirmDialog(
          'حذف النسخة الاحتياطية؟',
          'هل أنت متأكد من حذف هذه النسخة الاحتياطية؟',
        );

        if (confirmed == true) {
          final bool success =
              await BackupService.deleteLocalBackup(backup.filePath);
          if (success) {
            _showSuccessMessage('تم حذف النسخة الاحتياطية');
            await _loadData();
          } else {
            _showErrorDialog('خطأ في الحذف', 'فشل في حذف النسخة الاحتياطية');
          }
        }
        break;
    }
  }

  // ========== دوال المساعدة ==========

  /// الحصول على أيقونة نوع النسخة الاحتياطية
  IconData _getBackupIcon(String type) {
    switch (type) {
      case 'full_backup':
        return Icons.backup;
      case 'products_only':
        return Icons.inventory;
      case 'inventory_only':
        return Icons.warehouse;
      default:
        return Icons.file_copy;
    }
  }

  /// الحصول على اسم نوع النسخة الاحتياطية
  String _getBackupTypeName(String type) {
    switch (type) {
      case 'full_backup':
        return 'نسخة احتياطية شاملة';
      case 'products_only':
        return 'منتجات فقط';
      case 'inventory_only':
        return 'مخزون فقط';
      default:
        return 'غير معروف';
    }
  }

  /// الحصول على الوقت المنقضي
  String _getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعات';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقائق';
    } else {
      return 'الآن';
    }
  }

  // ========== دوال الحوارات ==========

  /// عرض حوار النجاح
  void _showSuccessDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// عرض حوار الخطأ
  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار المعلومات
  void _showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار التأكيد
  Future<bool?> _showConfirmDialog(String title, String message) =>
      showDialog<bool>(
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
              child: const Text('موافق'),
            ),
          ],
        ),
      );
}
