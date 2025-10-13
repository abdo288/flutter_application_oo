import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

/// حوار خيارات المخزون المحسن
class ModernInventoryOptionsDialog extends StatelessWidget {
  const ModernInventoryOptionsDialog({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dialog(
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
                    child: _buildContent(context),
                  ),
                ),
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
                      fontSize: context.responsiveFontSize(14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close,
                  color: Colors.white, size: context.isSmallScreen ? 20 : 24),
            ),
          ],
        ),
      );

  /// بناء محتوى الحوار
  Widget _buildContent(BuildContext context) => Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // معلومات سريعة
            _buildQuickInfo(context),
            SizedBox(height: context.responsiveSpacing),

            // أزرار الإجراءات
            _buildActionButtons(context),
          ],
        ),
      );

  /// بناء المعلومات السريعة
  Widget _buildQuickInfo(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: context.shouldUseVerticalLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildInfoItem(
                    context,
                    'الكمية',
                    item.quantity.toString(),
                    Icons.inventory_2,
                    Colors.blue[600]!,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  _buildInfoItem(
                    context,
                    'السعر',
                    '${item.wholesalePrice} DZ',
                    Icons.attach_money,
                    Colors.green[600]!,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  _buildInfoItem(
                    context,
                    'القيمة',
                    '${item.wholesalePrice * item.quantity} DZ',
                    Icons.calculate,
                    Colors.orange[600]!,
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'الكمية',
                      item.quantity.toString(),
                      Icons.inventory_2,
                      Colors.blue[600]!,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.blue[200],
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'السعر',
                      '${item.wholesalePrice} DZ',
                      Icons.attach_money,
                      Colors.green[600]!,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.blue[200],
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'القيمة',
                      '${item.wholesalePrice * item.quantity} DZ',
                      Icons.calculate,
                      Colors.orange[600]!,
                    ),
                  ),
                ],
              ),
      );

  /// بناء عنصر معلومات
  Widget _buildInfoItem(BuildContext context, String label, String value,
          IconData icon, Color color) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: context.isSmallScreen ? 18 : 20),
          SizedBox(height: context.responsiveSpacing * 0.3),
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context) => Column(
        children: <Widget>[
          // زر التعديل
          _buildActionButton(
            context: context,
            icon: Icons.edit,
            title: 'تعديل العنصر',
            subtitle: 'تعديل الاسم والسعر والكمية',
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // زر الحذف
          _buildActionButton(
            context: context,
            icon: Icons.delete,
            title: 'حذف العنصر',
            subtitle: 'حذف نهائي من المخزون',
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context);
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // زر الإلغاء
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.cancel, size: context.isSmallScreen ? 18 : 20),
              label: Text('إلغاء',
                  style: TextStyle(fontSize: context.responsiveFontSize(16))),
              style: OutlinedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsiveSpacing),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ),
        ],
      );

  /// بناء زر إجراء
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: context.responsivePadding,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(icon,
                      color: color, size: context.isSmallScreen ? 20 : 24),
                ),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(12),
                          color: color.withOpacity(0.8),
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
        ),
      );

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: <Widget>[
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: AppConstants.smallPadding),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('هل أنت متأكد من حذف العنصر:'),
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.inventory, color: Colors.red[600], size: 20),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'هذا الإجراء لا يمكن التراجع عنه.',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
