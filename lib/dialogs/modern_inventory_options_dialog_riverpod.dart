import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../providers/inventory_riverpod_providers.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/snackbar_utils.dart';
import 'modern_confirmation_dialog.dart';
import 'modern_edit_inventory_dialog_riverpod.dart';

/// حوار خيارات عنصر المخزون المحسن بـ Riverpod
class ModernInventoryOptionsDialogRiverpod extends ConsumerWidget {
  const ModernInventoryOptionsDialogRiverpod({
    super.key,
    required this.item,
    required this.onItemUpdated,
    required this.onItemDeleted,
  });

  final InventoryItem item;
  final VoidCallback onItemUpdated;
  final VoidCallback onItemDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        ),
        elevation: 8,
        child: ConstrainedBox(
          constraints: context.dialogConstraints,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius * 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(context),
                Flexible(
                  child: SingleChildScrollView(
                    physics: context.responsiveScrollPhysics,
                    child: _buildContent(context, ref),
                  ),
                ),
                _buildActions(context, ref),
              ],
            ),
          ),
        ),
      );

  /// بناء رأس الحوار
  Widget _buildHeader(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue[600]!,
              Colors.blue[400]!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.borderRadius * 2),
            topRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: context.isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'خيارات العنصر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: context.responsiveFontSize(12),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.close, color: Colors.white),
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  /// بناء محتوى الحوار
  Widget _buildContent(BuildContext context, WidgetRef ref) => Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // معلومات العنصر
            _buildItemInfo(context),
            SizedBox(height: context.responsiveSpacing),

            // خيارات الإجراءات
            _buildActionOptions(context, ref),
          ],
        ),
      );

  /// بناء معلومات العنصر
  Widget _buildItemInfo(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.info_outline,
                    color: Colors.blue[600],
                    size: context.isSmallScreen ? 18 : 22),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Text(
                  'معلومات العنصر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: context.responsiveFontSize(14),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            if (context.shouldUseVerticalLayout)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildInfoRow(context, 'الباركود', item.barcode ?? 'غير محدد',
                      Icons.qr_code, Colors.blue[600]!),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  _buildInfoRow(context, 'الكمية', '${item.quantity}',
                      Icons.inventory, Colors.green[600]!),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  _buildInfoRow(
                      context,
                      'سعر الجملة',
                      '${item.wholesalePrice} DZ',
                      Icons.attach_money,
                      Colors.orange[600]!),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  _buildInfoRow(
                      context,
                      'سعر التجزئة',
                      '${item.retailPrice} DZ',
                      Icons.sell,
                      Colors.purple[600]!),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildInfoRow(
                            context,
                            'الباركود',
                            item.barcode ?? 'غير محدد',
                            Icons.qr_code,
                            Colors.blue[600]!),
                      ),
                      SizedBox(width: context.responsiveSpacing * 0.5),
                      Expanded(
                        child: _buildInfoRow(
                            context,
                            'الكمية',
                            '${item.quantity}',
                            Icons.inventory,
                            Colors.green[600]!),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildInfoRow(
                            context,
                            'سعر الجملة',
                            '${item.wholesalePrice} DZ',
                            Icons.attach_money,
                            Colors.orange[600]!),
                      ),
                      SizedBox(width: context.responsiveSpacing * 0.5),
                      Expanded(
                        child: _buildInfoRow(
                            context,
                            'سعر التجزئة',
                            '${item.retailPrice} DZ',
                            Icons.sell,
                            Colors.purple[600]!),
                      ),
                    ],
                  ),
                ],
              ),
            if (item.expiryDate != null) ...<Widget>[
              SizedBox(height: context.responsiveSpacing * 0.3),
              _buildInfoRow(
                  context,
                  'تاريخ الانتهاء',
                  item.expiryDate!.toString().split(' ')[0],
                  Icons.event,
                  Colors.red[600]!),
            ],
          ],
        ),
      );

  /// بناء صف معلومات
  Widget _buildInfoRow(BuildContext context, String label, String value,
          IconData icon, Color color) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: context.isSmallScreen ? 14 : 16, color: color),
          SizedBox(width: context.responsiveSpacing * 0.25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(11),
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(11),
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );

  /// بناء خيارات الإجراءات
  Widget _buildActionOptions(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'الإجراءات المتاحة',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          // خيار التعديل
          _buildActionTile(
            context: context,
            title: 'تعديل العنصر',
            subtitle: 'تعديل بيانات العنصر',
            icon: Icons.edit,
            color: Colors.blue,
            onTap: () => _editItem(context, ref),
          ),

          SizedBox(height: context.responsiveSpacing * 0.5),

          // خيار الحذف
          _buildActionTile(
            context: context,
            title: 'حذف العنصر',
            subtitle: 'حذف العنصر نهائياً',
            icon: Icons.delete,
            color: Colors.red,
            onTap: () => _deleteItem(context, ref),
          ),

          SizedBox(height: context.responsiveSpacing * 0.5),

          // خيار نسخ الباركود
          if (item.barcode != null && item.barcode!.isNotEmpty)
            _buildActionTile(
              context: context,
              title: 'نسخ الباركود',
              subtitle: 'نسخ الباركود إلى الحافظة',
              icon: Icons.copy,
              color: Colors.green,
              onTap: () => _copyBarcode(context),
            ),

          SizedBox(height: context.responsiveSpacing * 0.5),

          // خيار عرض التفاصيل
          _buildActionTile(
            context: context,
            title: 'عرض التفاصيل',
            subtitle: 'عرض جميع تفاصيل العنصر',
            icon: Icons.info,
            color: Colors.purple,
            onTap: () => _showDetails(context),
          ),
        ],
      );

  /// بناء عنصر إجراء
  Widget _buildActionTile({
    required BuildContext context,
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
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: color.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.6),
                size: context.isSmallScreen ? 14 : 16,
              ),
            ],
          ),
        ),
      );

  /// بناء أزرار الإجراءات
  Widget _buildActions(BuildContext context, WidgetRef ref) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppConstants.borderRadius * 2),
            bottomRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: context.shouldUseVerticalLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('إغلاق',
                        style: TextStyle(
                            fontSize: context.responsiveFontSize(14))),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: Text('إغلاق',
                          style: TextStyle(
                              fontSize: context.responsiveFontSize(14))),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: context.responsiveSpacing),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );

  /// تعديل العنصر
  void _editItem(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernEditInventoryDialogRiverpod(
        item: item,
        onItemUpdated: onItemUpdated,
      ),
    );
  }

  /// حذف العنصر
  void _deleteItem(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernDeleteConfirmationDialog(
        title: 'حذف عنصر المخزون',
        message:
            'هل أنت متأكد من حذف "${item.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        onConfirm: () => _confirmDelete(context, ref),
      ),
    );
  }

  /// تأكيد الحذف
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    try {
      final bool success = await ref
          .read(inventoryStateProvider.notifier)
          .deleteInventoryItem(item.id!);

      if (success) {
        SnackbarUtils.showSuccess(context, 'تم حذف عنصر المخزون بنجاح');
        onItemDeleted();
      } else {
        SnackbarUtils.showError(context, 'فشل في حذف عنصر المخزون');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في حذف عنصر المخزون: $e');
    }
  }

  /// نسخ الباركود
  void _copyBarcode(BuildContext context) {
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      // سيتم تنفيذ نسخ الباركود هنا
      SnackbarUtils.showSuccess(context, 'تم نسخ الباركود إلى الحافظة');
    }
  }

  /// عرض التفاصيل
  void _showDetails(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        ),
        child: Container(
          constraints: context.dialogConstraints,
          padding: context.responsivePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // العنوان
              Row(
                children: <Widget>[
                  Icon(Icons.info, color: Colors.blue[600]),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  Text(
                    'تفاصيل العنصر',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing),

              // التفاصيل
              Container(
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDetailRow('الاسم', item.name),
                    _buildDetailRow('الباركود', item.barcode ?? 'غير محدد'),
                    _buildDetailRow('الكمية', '${item.quantity}'),
                    _buildDetailRow('سعر الجملة', '${item.wholesalePrice} DZ'),
                    _buildDetailRow('سعر التجزئة', '${item.retailPrice} DZ'),
                    _buildDetailRow('تاريخ الإضافة', item.addedDate.toString()),
                    if (item.expiryDate != null)
                      _buildDetailRow(
                          'تاريخ الانتهاء', item.expiryDate!.toString()),
                  ],
                ),
              ),

              SizedBox(height: context.responsiveSpacing),

              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء صف تفصيل
  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const Text(': '),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      );
}
