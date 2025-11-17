import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// حاوية قسم منسّقة موحّدة لتطبيق نفس نمط تبويب نموذج المنتج على بقية التبويبات
class StyledSection extends StatelessWidget {
  const StyledSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppConstants.primaryColor.withValues(alpha: 0.08),
              AppConstants.primaryColor.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.15),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}
