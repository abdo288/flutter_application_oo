import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.all(context.responsiveSpacing * 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
            child: Container(
              padding: context.responsivePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // الأيقونة
                  Container(
                    padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
                    decoration: BoxDecoration(
                      color: (valueColor ?? AppConstants.primaryColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        context.isSmallScreen ? 8 : 12,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: context.isSmallScreen ? 24 : 32,
                      color: valueColor ?? AppConstants.primaryColor,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),

                  // العنوان
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: context.responsiveFontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),

                  // القيمة
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: valueColor ??
                            (isDark ? Colors.white : AppConstants.textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
