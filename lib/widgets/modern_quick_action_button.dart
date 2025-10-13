import 'package:flutter/material.dart';

import '../utils/responsive_breakpoints.dart';

/// زر الإجراء السريع محسن بتصميم HTML
class ModernQuickActionButton extends StatefulWidget {
  const ModernQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  State<ModernQuickActionButton> createState() =>
      _ModernQuickActionButtonState();
}

class _ModernQuickActionButtonState extends State<ModernQuickActionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? const Color(0xFF2563EB);

    return GestureDetector(
      onTapDown: (_) {
        if (mounted) {
          try {
            _scaleController.forward();
            _rotationController.forward();
          } catch (e) {
            // تجاهل الأخطاء إذا تم التخلص من المتحكمات
          }
        }
      },
      onTapUp: (_) {
        if (mounted) {
          try {
            _scaleController.reverse();
            _rotationController.reverse();
          } catch (e) {
            // تجاهل الأخطاء إذا تم التخلص من المتحكمات
          }
        }
        widget.onTap();
      },
      onTapCancel: () {
        if (mounted) {
          try {
            _scaleController.reverse();
            _rotationController.reverse();
          } catch (e) {
            // تجاهل الأخطاء إذا تم التخلص من المتحكمات
          }
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.3,
            ),
            decoration: BoxDecoration(
              gradient: widget.gradient ??
                  LinearGradient(
                    colors: [
                      buttonColor,
                      buttonColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                child: Padding(
                  padding: EdgeInsets.all(context.responsiveSpacing * 1.2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الأيقونة
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: context.responsiveFontSize(28),
                        ),
                      ),

                      SizedBox(height: context.responsiveSpacing * 0.5),

                      // النص
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
