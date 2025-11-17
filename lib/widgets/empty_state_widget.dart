import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Modern empty state widget with animations
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionText,
    this.onActionPressed,
    this.subtitle,
  });

  final String message;
  final IconData icon;
  final String? title;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final String? subtitle;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    if (mounted) {
      try {
        _controller.forward();
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) => FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Animated icon with circular background
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                              AppConstants.secondaryColor
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: AppConstants.iconSizeHuge,
                          color: isDark
                              ? AppConstants.primaryLightColor
                              : AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing24),

                    // Title
                    if (widget.title != null) ...<Widget>[
                      Text(
                        widget.title!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppConstants.fontWeightBold,
                          color: isDark ? Colors.white : AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing12),
                    ],

                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppConstants.textSecondaryColor.withValues(
                                alpha: 0.7,
                              )
                            : AppConstants.textSecondaryColor,
                        height: AppConstants.lineHeightRelaxed,
                      ),
                    ),

                    // Subtitle
                    if (widget.subtitle != null) ...<Widget>[
                      const SizedBox(height: AppConstants.spacing12),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppConstants.lightTextColor.withValues(
                                  alpha: 0.6,
                                )
                              : AppConstants.lightTextColor,
                        ),
                      ),
                    ],

                    // Action button
                    if (widget.actionText != null &&
                        widget.onActionPressed != null) ...<Widget>[
                      const SizedBox(height: AppConstants.spacing32),
                      ElevatedButton.icon(
                        onPressed: widget.onActionPressed,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(widget.actionText!),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing32,
                            vertical: AppConstants.spacing16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                          elevation: AppConstants.elevation4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }
}
