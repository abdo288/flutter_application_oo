import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/inventory_alert.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة عرض تنبيه المخزون
class InventoryAlertCard extends StatelessWidget {
  const InventoryAlertCard({
    super.key,
    required this.alert,
    this.onMarkAsRead,
    this.onDelete,
  });
  final InventoryAlert alert;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing * 0.5, // زيادة المسافة
          vertical: context.responsiveSpacing * 0.5, // زيادة المسافة
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _getAlertColor().withValues(alpha: 0.1),
              blurRadius: context.isSmallScreen ? 6 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 12 : 16,
            ),
            side: BorderSide(
              color: _getAlertColor().withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 12 : 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    isDark ? Colors.grey[800]! : Colors.white,
                    _getAlertColor().withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // رأس البطاقة
                    Row(
                      children: <Widget>[
                        // أيقونة التنبيه
                        Container(
                          padding: EdgeInsets.all(
                            context.responsiveSpacing * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: _getAlertColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              context.isSmallScreen ? 8 : 12,
                            ),
                            border: Border.all(
                              color: _getAlertColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            alert.alertIcon,
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(26),
                            ),
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing * 0.5),

                        // معلومات التنبيه
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                alert.alertMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(16),
                                  fontWeight: FontWeight.bold,
                                  color: _getAlertColor(),
                                ),
                              ),
                              SizedBox(height: context.responsiveSpacing * 0.2),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.access_time,
                                    size: context.responsiveFontSize(16),
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(
                                      width: context.responsiveSpacing * 0.2),
                                  Flexible(
                                    child: Text(
                                      _formatDate(alert.alertDate),
                                      style: TextStyle(
                                        fontSize:
                                            context.responsiveFontSize(12),
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // حالة القراءة
                        if (!alert.isRead)
                          Container(
                            width: context.isSmallScreen ? 8 : 12,
                            height: context.isSmallScreen ? 8 : 12,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppConstants.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // تفاصيل إضافية
                    if (alert.description != null) ...<Widget>[
                      SizedBox(height: context.responsiveSpacing * 0.5),
                      Container(
                        padding: context.responsivePadding,
                        decoration: BoxDecoration(
                          color: _getAlertColor().withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            context.isSmallScreen ? 6 : 8,
                          ),
                          border: Border.all(
                            color: _getAlertColor().withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline,
                              size: context.isSmallScreen ? 14 : 16,
                              color: _getAlertColor(),
                            ),
                            SizedBox(width: context.responsiveSpacing * 0.3),
                            Expanded(
                              child: Text(
                                alert.description!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(12),
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // معلومات الكمية
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    Container(
                      padding: context.responsivePadding,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          context.isSmallScreen ? 6 : 8,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(
                              context.responsiveSpacing * 0.3,
                            ),
                            decoration: BoxDecoration(
                              color: _getAlertColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                context.isSmallScreen ? 4 : 6,
                              ),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              size: context.isSmallScreen ? 14 : 16,
                              color: _getAlertColor(),
                            ),
                          ),
                          SizedBox(width: context.responsiveSpacing * 0.5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'الكمية الحالية: ${alert.currentQuantity}',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(12),
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (alert.threshold != null) ...<Widget>[
                                  SizedBox(
                                      height: context.responsiveSpacing * 0.1),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.warning_amber,
                                        size: context.isSmallScreen ? 12 : 14,
                                        color: Colors.orange[600],
                                      ),
                                      SizedBox(
                                          width:
                                              context.responsiveSpacing * 0.2),
                                      Flexible(
                                        child: Text(
                                          'الحد الأدنى: ${alert.threshold}',
                                          style: TextStyle(
                                            fontSize:
                                                context.responsiveFontSize(10),
                                            color: Colors.orange[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // أزرار الإجراءات
                    if (onMarkAsRead != null || onDelete != null) ...<Widget>[
                      SizedBox(height: context.responsiveSpacing * 0.5),
                      context.shouldUseVerticalLayout
                          ? Column(
                              children: [
                                if (onDelete != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildActionButton(
                                      context,
                                      onPressed: onDelete!,
                                      icon: Icons.delete_outline,
                                      label:
                                          AppLocalizations.of(context).delete,
                                      color: Colors.red,
                                      isDark: isDark,
                                    ),
                                  ),
                                if (onMarkAsRead != null && !alert.isRead) ...[
                                  SizedBox(
                                      height: context.responsiveSpacing * 0.3),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildActionButton(
                                      context,
                                      onPressed: onMarkAsRead!,
                                      icon: Icons.check_circle_outline,
                                      label: 'تم القراءة',
                                      color: AppConstants.primaryColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Wrap(
                              alignment: WrapAlignment.end,
                              spacing: context.responsiveSpacing * 0.3,
                              children: <Widget>[
                                if (onDelete != null)
                                  _buildActionButton(
                                    context,
                                    onPressed: onDelete!,
                                    icon: Icons.delete_outline,
                                    label: AppLocalizations.of(context).delete,
                                    color: Colors.red,
                                    isDark: isDark,
                                  ),
                                if (onMarkAsRead != null && !alert.isRead)
                                  _buildActionButton(
                                    context,
                                    onPressed: onMarkAsRead!,
                                    icon: Icons.check_circle_outline,
                                    label: 'تم القراءة',
                                    color: AppConstants.primaryColor,
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAlertColor() {
    switch (alert.alertType) {
      case AlertType.outOfStock:
        return Colors.red;
      case AlertType.lowStock:
        return Colors.orange;
      case AlertType.expiringSoon:
        return Colors.amber;
    }
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 6 : 8,
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.isSmallScreen ? 32 : 36,
            minWidth: context.isSmallScreen ? 80 : 100,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.5,
            vertical: context.responsiveSpacing * 0.3,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 6 : 8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: context.isSmallScreen ? 14 : 16,
              ),
              SizedBox(width: context.responsiveSpacing * 0.2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFontSize(10),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
