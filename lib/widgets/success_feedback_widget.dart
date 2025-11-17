import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Success feedback widget with celebration animation
class SuccessFeedbackWidget extends StatefulWidget {
  const SuccessFeedbackWidget({
    super.key,
    required this.message,
    this.title = 'نجح!',
    this.icon = Icons.check_circle_outline_rounded,
    this.onDismiss,
    this.actionText,
    this.onActionPressed,
    this.autoDismiss = true,
    this.dismissDuration = const Duration(seconds: 3),
  });

  final String message;
  final String title;
  final IconData icon;
  final VoidCallback? onDismiss;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool autoDismiss;
  final Duration dismissDuration;

  @override
  State<SuccessFeedbackWidget> createState() => _SuccessFeedbackWidgetState();
}

class _SuccessFeedbackWidgetState extends State<SuccessFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _checkmarkController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppConstants.animationSlow,
      vsync: this,
    );

    _checkmarkController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: Curves.easeInOut,
      ),
    );

    if (mounted) {
      try {
        _controller.forward();
        _checkmarkController.forward();
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }

    // Auto dismiss
    if (widget.autoDismiss) {
      Future<void>.delayed(widget.dismissDuration, () {
        if (mounted && widget.onDismiss != null) {
          widget.onDismiss!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _checkmarkController.dispose();
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Animated success icon with checkmark
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // Background circles
                      for (int i = 0; i < 3; i++)
                        AnimatedBuilder(
                          animation: _checkmarkController,
                          builder: (BuildContext context, Widget? child) => Transform.scale(
                              scale: 1 + (i * 0.2 * _checkmarkAnimation.value),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppConstants.successColor
                                      .withValues(alpha: 0.1 / (i + 1)),
                                ),
                              ),
                            ),
                        ),
                      // Main icon container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppConstants.successColor.withValues(alpha: 0.2),
                              AppConstants.successDarkColor
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppConstants.successColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: AppConstants.iconSizeHuge,
                          color: AppConstants.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacing24),

                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppConstants.fontWeightBold,
                    color: isDark
                        ? AppConstants.successLightColor
                        : AppConstants.successDarkColor,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing12),

                // Message
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.successColor.withValues(alpha: 0.1)
                        : AppConstants.successColor.withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: AppConstants.successColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppConstants.textSecondaryColor
                          : AppConstants.textSecondaryColor,
                      height: AppConstants.lineHeightRelaxed,
                    ),
                  ),
                ),

                // Action button
                if (widget.actionText != null &&
                    widget.onActionPressed != null) ...<Widget>[
                  const SizedBox(height: AppConstants.spacing32),
                  ElevatedButton.icon(
                    onPressed: widget.onActionPressed,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(widget.actionText!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing32,
                        vertical: AppConstants.spacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      elevation: AppConstants.elevation4,
                    ),
                  ),
                ],

                // Dismiss button
                if (widget.onDismiss != null && !widget.autoDismiss) ...<Widget>[
                  const SizedBox(height: AppConstants.spacing16),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text('إغلاق'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact success snackbar
class SuccessSnackbar extends SnackBar {
  SuccessSnackbar({
    super.key,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    super.duration = const Duration(seconds: 3),
  }) : super(
          content: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: AppConstants.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          margin: const EdgeInsets.all(AppConstants.spacing16),
        );
}

/// Show success dialog
Future<void> showSuccessDialog(
  BuildContext context, {
  required String message,
  String title = 'نجح!',
  IconData icon = Icons.check_circle_outline_rounded,
  String? actionText,
  VoidCallback? onActionPressed,
  bool barrierDismissible = true,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacing24),
            child: SuccessFeedbackWidget(
              message: message,
              title: title,
              icon: icon,
              actionText: actionText,
              onActionPressed: onActionPressed,
              onDismiss: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              autoDismiss: false,
            ),
          ),
        ),
    );
