import 'package:flutter/material.dart';
import '../utils/responsive_breakpoints.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.isSmallScreen ? 12 : 16),
        ),
        elevation: 8,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(context.isSmallScreen ? 12 : 16),
              topRight: Radius.circular(context.isSmallScreen ? 12 : 16),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius:
                      BorderRadius.circular(context.isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: context.isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          constraints: BoxConstraints(
            minHeight: context.isSmallScreen ? 60 : 80,
            minWidth: context.isSmallScreen ? 280 : 320,
          ),
          padding: context.responsivePadding,
          child: Text(
            message,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.5,
              vertical: context.responsiveSpacing * 0.3,
            ),
            child: context.shouldUseVerticalLayout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        icon: Icon(
                          Icons.delete,
                          size: context.isSmallScreen ? 16 : 18,
                        ),
                        label: Text(
                          'حذف',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(
                          Icons.cancel,
                          size: context.isSmallScreen ? 16 : 18,
                        ),
                        label: Text(
                          'إلغاء',
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
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: Icon(
                            Icons.cancel,
                            size: context.isSmallScreen ? 16 : 18,
                          ),
                          label: Text(
                            'إلغاء',
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
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          icon: Icon(
                            Icons.delete,
                            size: context.isSmallScreen ? 16 : 18,
                          ),
                          label: Text(
                            'حذف',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(14),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
          ),
        ],
      ),
    );
  }
}
