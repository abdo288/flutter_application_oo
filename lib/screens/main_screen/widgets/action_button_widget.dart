import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  const ActionButtonWidget({
    super.key,
    required this.context,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
    required this.backgroundColor,
    this.iconSize = 24,
  });

  final BuildContext context;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color backgroundColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: iconSize),
          tooltip: tooltip,
          splashRadius: 20,
        ),
      );
}
