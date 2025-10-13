import 'package:flutter/material.dart';
import '../utils/responsive_breakpoints.dart';

/// حوار التأكيد المحسن
class ModernConfirmationDialog extends StatelessWidget {
  const ModernConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
    this.confirmColor = Colors.red,
    this.icon,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
        ),
        elevation: 8,
        child: ConstrainedBox(
          constraints: context.dialogConstraints,
          child: Container(
            constraints: BoxConstraints(
              minHeight: context.isSmallScreen ? 200 : 250,
              minWidth: context.isSmallScreen ? 280 : 320,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                context.isSmallScreen ? 12 : 16,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  isDark ? Colors.grey[800]! : Colors.white,
                  isDark ? Colors.grey[700]! : Colors.grey[50]!,
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
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء رأس الحوار
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            confirmColor,
            confirmColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
          topRight: Radius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(
              context.responsiveSpacing * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                context.isSmallScreen ? 8 : 12,
              ),
            ),
            child: Icon(
              icon ?? (isDestructive ? Icons.warning : Icons.help_outline),
              color: Colors.white,
              size: context.isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: context.responsiveSpacing * 0.5),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء محتوى الحوار
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: context.responsivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // الرسالة الرئيسية
          Text(
            message,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),

          if (isDestructive) ...<Widget>[
            SizedBox(height: context.responsiveSpacing * 0.5),

            // تحذير إضافي للإجراءات المدمرة
            Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: isDark ? Colors.red[900] : Colors.red[50],
                borderRadius: BorderRadius.circular(
                  context.isSmallScreen ? 8 : 12,
                ),
                border: Border.all(
                  color: isDark ? Colors.red[700]! : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.red[300] : Colors.red[600],
                    size: context.isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.3),
                  Expanded(
                    child: Text(
                      'هذا الإجراء لا يمكن التراجع عنه',
                      style: TextStyle(
                        color: isDark ? Colors.red[300] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsiveFontSize(12),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
          bottomRight: Radius.circular(
            context.isSmallScreen ? 12 : 16,
          ),
        ),
      ),
      child: context.shouldUseVerticalLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm();
                  },
                  icon: Icon(
                    isDestructive ? Icons.delete : Icons.check,
                    size: context.isSmallScreen ? 16 : 18,
                  ),
                  label: Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSpacing * 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.responsiveSpacing * 0.3),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(
                    Icons.cancel,
                    size: context.isSmallScreen ? 16 : 18,
                  ),
                  label: Text(
                    cancelText,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSpacing * 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(
                      Icons.cancel,
                      size: context.isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsiveSpacing * 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    icon: Icon(
                      isDestructive ? Icons.delete : Icons.check,
                      size: context.isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsiveSpacing * 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// حوار تأكيد الحذف المحسن
class ModernDeleteConfirmationDialog extends StatelessWidget {
  const ModernDeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.itemName,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String? itemName;

  @override
  Widget build(BuildContext context) => ModernConfirmationDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmText: 'حذف',
        icon: Icons.delete_forever,
        isDestructive: true,
      );
}

/// حوار تأكيد الحفظ المحسن
class ModernSaveConfirmationDialog extends StatelessWidget {
  const ModernSaveConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => ModernConfirmationDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmText: 'حفظ',
        confirmColor: Colors.green,
        icon: Icons.save,
      );
}
