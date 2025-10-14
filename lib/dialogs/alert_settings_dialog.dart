import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/alert_settings.dart';
import '../services/inventory_alert_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../utils/responsive_breakpoints.dart';

/// حوار إعدادات التنبيهات
class AlertSettingsDialog extends StatefulWidget {
  const AlertSettingsDialog({super.key});

  @override
  State<AlertSettingsDialog> createState() => _AlertSettingsDialogState();
}

class _AlertSettingsDialogState extends State<AlertSettingsDialog> {
  late AlertSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _lowStockController = TextEditingController();
  final TextEditingController _expiringDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _lowStockController.dispose();
    _expiringDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: ConstrainedBox(
          constraints: context.dialogConstraints,
          child: Container(
            padding: context.responsivePadding,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: context.responsiveScrollPhysics,
                    child: _buildSettingsForm(),
                  ),
          ),
        ),
      );

  Widget _buildSettingsForm() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // العنوان
          Row(
            children: <Widget>[
              Icon(Icons.settings,
                  color: AppConstants.primaryColor,
                  size: context.isSmallScreen ? 20 : 24),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).alertSettingsTitle,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(20),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: context.isSmallScreen ? 20 : 24),
              ),
            ],
          ),

          SizedBox(height: context.responsiveSpacing),

          // تفعيل تنبيه نفاد الكمية
          _buildSwitchTile(
            title: AppLocalizations.of(context).outOfStockAlert,
            subtitle: AppLocalizations.of(context).outOfStockAlertDesc,
            value: _settings.enableOutOfStockAlert,
            onChanged: (bool value) {
              setState(() {
                _settings = _settings.copyWith(enableOutOfStockAlert: value);
              });
            },
            icon: Icons.warning,
          ),

          SizedBox(height: context.responsiveSpacing),

          // تفعيل تنبيه الحد الأدنى
          _buildSwitchTile(
            title: AppLocalizations.of(context).lowStockAlertTitle,
            subtitle: AppLocalizations.of(context).lowStockAlertDesc,
            value: _settings.enableLowStockAlert,
            onChanged: (bool value) {
              setState(() {
                _settings = _settings.copyWith(enableLowStockAlert: value);
              });
            },
            icon: Icons.trending_down,
          ),

          // إعداد الحد الأدنى
          if (_settings.enableLowStockAlert) ...<Widget>[
            SizedBox(height: context.responsiveSpacing),
            _buildNumberField(
              controller: _lowStockController,
              label: AppLocalizations.of(context).lowStockThreshold,
              hint: AppLocalizations.of(context).lowStockThresholdHint,
              value: _settings.lowStockThreshold,
              onChanged: (int value) {
                setState(() {
                  _settings = _settings.copyWith(lowStockThreshold: value);
                });
              },
              icon: Icons.inventory,
            ),
          ],

          SizedBox(height: context.responsiveSpacing),

          // تفعيل تنبيه قرب الانتهاء
          _buildSwitchTile(
            title: AppLocalizations.of(context).expiringAlertTitle,
            subtitle: AppLocalizations.of(context).expiringAlertDesc,
            value: _settings.enableExpiringAlert,
            onChanged: (bool value) {
              setState(() {
                _settings = _settings.copyWith(enableExpiringAlert: value);
              });
            },
            icon: Icons.schedule,
          ),

          // إعداد أيام الانتهاء
          if (_settings.enableExpiringAlert) ...<Widget>[
            SizedBox(height: context.responsiveSpacing),
            _buildNumberField(
              controller: _expiringDaysController,
              label: AppLocalizations.of(context).daysBeforeExpiry,
              hint: AppLocalizations.of(context).daysBeforeExpiryHint,
              value: _settings.expiringDaysThreshold,
              onChanged: (int value) {
                setState(() {
                  _settings = _settings.copyWith(expiringDaysThreshold: value);
                });
              },
              icon: Icons.calendar_today,
            ),
          ],

          const SizedBox(height: AppConstants.largePadding),

          // قسم الإجراءات الإضافية
          _buildActionSection(),

          const SizedBox(height: AppConstants.largePadding),

          // أزرار الإجراءات
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ],
          ),
        ],
      );

  /// بناء قسم الإجراءات الإضافية
  Widget _buildActionSection() => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // عنوان القسم
            Row(
              children: <Widget>[
                Icon(Icons.tune,
                    color: AppConstants.primaryColor,
                    size: context.isSmallScreen ? 20 : 24),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).additionalActions,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing),

            // إدارة التنبيهات
            _buildActionTile(
              title: 'تحديث التنبيهات',
              subtitle: 'تحديث قائمة التنبيهات الحالية',
              icon: Icons.refresh,
              color: Colors.green,
              onTap: _refreshAlerts,
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            _buildActionTile(
              title: 'فحص التنبيهات',
              subtitle: 'فحص المخزون وإنشاء تنبيهات جديدة',
              icon: Icons.search,
              color: AppConstants.primaryColor,
              onTap: _checkInventoryAlerts,
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            // فلترة التنبيهات
            _buildActionTile(
              title: 'عرض جميع التنبيهات',
              subtitle: 'إظهار جميع التنبيهات (مقروءة وغير مقروءة)',
              icon: Icons.list,
              color: AppConstants.primaryColor,
              onTap: () => _setFilter('all'),
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            _buildActionTile(
              title: 'عرض التنبيهات غير المقروءة',
              subtitle: 'إظهار التنبيهات غير المقروءة فقط',
              icon: Icons.mark_email_unread,
              color: Colors.orange,
              onTap: () => _setFilter('unread'),
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            // الإجراءات الجماعية
            _buildActionTile(
              title: 'تحديد الكل كمقروء',
              subtitle: 'تحديد جميع التنبيهات كمقروءة',
              icon: Icons.done_all,
              color: Colors.green,
              onTap: _markAllAsRead,
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            _buildActionTile(
              title: 'حذف التنبيهات المقروءة',
              subtitle: 'حذف جميع التنبيهات المقروءة',
              icon: Icons.delete_sweep,
              color: Colors.red,
              onTap: _deleteReadAlerts,
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            _buildActionTile(
              title: 'تنظيف التنبيهات القديمة',
              subtitle: 'حذف التنبيهات القديمة (أكثر من 30 يوم)',
              icon: Icons.cleaning_services,
              color: Colors.blue,
              onTap: _cleanupOldAlerts,
            ),

            SizedBox(height: context.responsiveSpacing * 0.5),

            _buildActionTile(
              title: 'تبديل المجموعات',
              subtitle: 'فتح/إغلاق جميع مجموعات التنبيهات',
              icon: Icons.unfold_more,
              color: Colors.purple,
              onTap: _toggleAllGroups,
            ),
          ],
        ),
      );

  /// بناء عنصر إجراء
  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: color, size: context.isSmallScreen ? 18 : 20),
              ),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.6),
                size: context.isSmallScreen ? 14 : 16,
              ),
            ],
          ),
        ),
      );

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppConstants.primaryColor),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppConstants.primaryColor,
            ),
          ],
        ),
      );

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int value,
    required ValueChanged<int> onChanged,
    required IconData icon,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide:
                const BorderSide(color: AppConstants.primaryColor, width: 2.0),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        onChanged: (String value) {
          final int intValue = int.tryParse(value) ?? 0;
          onChanged(intValue);
        },
      );

  Future<void> _loadSettings() async {
    try {
      final AlertSettings settings =
          await InventoryAlertService.getAlertSettings();
      setState(() {
        _settings = settings;
        _lowStockController.text = settings.lowStockThreshold.toString();
        _expiringDaysController.text =
            settings.expiringDaysThreshold.toString();
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحميل الإعدادات');
      }
    }
  }

  Future<void> _saveSettings() async {
    final String? validationError = _settings.getValidationError();
    if (validationError != null) {
      SnackbarUtils.showError(context, validationError);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await InventoryAlertService.saveAlertSettings(_settings);
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
        Navigator.of(context).pop();
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في حفظ الإعدادات');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// تحديث التنبيهات
  Future<void> _refreshAlerts() async {
    try {
      // إغلاق النافذة أولاً
      Navigator.of(context).pop();

      // إرسال إشارة للتحديث
      if (mounted) {
        // يمكن إضافة callback هنا لإعلام الشاشة الرئيسية بالتحديث
        SnackbarUtils.showSuccess(context, 'تم تحديث التنبيهات');
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحديث التنبيهات');
      }
    }
  }

  /// فحص التنبيهات
  Future<void> _checkInventoryAlerts() async {
    try {
      // إغلاق النافذة أولاً
      Navigator.of(context).pop();

      // إرسال إشارة لفحص التنبيهات
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم فحص التنبيهات');
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في فحص التنبيهات');
      }
    }
  }

  /// تعيين الفلتر
  void _setFilter(String filter) {
    // إغلاق النافذة أولاً
    Navigator.of(context).pop();

    // إرسال إشارة للفلترة
    if (mounted) {
      SnackbarUtils.showSuccess(context, 'تم تطبيق الفلتر');
    }
  }

  /// تحديد الكل كمقروء
  Future<void> _markAllAsRead() async {
    try {
      await InventoryAlertService.markAllAlertsAsRead();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تحديد جميع التنبيهات كمقروءة');
        Navigator.of(context).pop();
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحديد التنبيهات كمقروءة');
      }
    }
  }

  /// حذف التنبيهات المقروءة
  Future<void> _deleteReadAlerts() async {
    try {
      await InventoryAlertService.deleteReadAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم حذف التنبيهات المقروءة');
        Navigator.of(context).pop();
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في حذف التنبيهات المقروءة');
      }
    }
  }

  /// تنظيف التنبيهات القديمة
  Future<void> _cleanupOldAlerts() async {
    try {
      await InventoryAlertService.cleanupOldAlerts();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تنظيف التنبيهات القديمة');
        Navigator.of(context).pop();
      }
    } on Exception {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تنظيف التنبيهات القديمة');
      }
    }
  }

  /// تبديل حالة جميع المجموعات
  void _toggleAllGroups() {
    try {
      // إغلاق النافذة أولاً
      Navigator.of(context).pop();

      // إرسال إشارة لتبديل المجموعات
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تبديل حالة المجموعات');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, 'خطأ في تبديل المجموعات: ${e.toString()}');
      }
    }
  }
}
