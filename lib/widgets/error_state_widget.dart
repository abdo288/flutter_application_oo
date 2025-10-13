import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Modern error state widget with animations
class ErrorStateWidget extends StatefulWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'حدث خطأ',
    this.icon = Icons.error_outline_rounded,
    this.showRetryButton = true,
    this.retryButtonText = 'إعادة المحاولة',
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final IconData icon;
  final bool showRetryButton;
  final String retryButtonText;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;

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
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
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

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    // Add a slight delay for visual feedback
    await Future<void>.delayed(const Duration(milliseconds: 300));

    widget.onRetry();

    // Reset state after callback
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Animated error icon
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
                          colors: [
                            AppConstants.errorColor.withValues(alpha: 0.1),
                            AppConstants.errorLightColor
                                .withValues(alpha: 0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppConstants.errorColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: AppConstants.iconSizeHuge,
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),

                  // Title
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: AppConstants.fontWeightBold,
                        color: isDark
                            ? AppConstants.errorLightColor
                            : AppConstants.errorDarkColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),

                  // Message
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.errorColor.withValues(alpha: 0.1)
                            : AppConstants.errorColor.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                          color: AppConstants.errorColor.withValues(alpha: 0.2),
                          width: 1,
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
                  ),

                  // Retry button
                  if (widget.showRetryButton) ...[
                    const SizedBox(height: AppConstants.spacing32),
                    SlideTransition(
                      position: _slideAnimation,
                      child: ElevatedButton.icon(
                        onPressed: _isRetrying ? null : _handleRetry,
                        icon: _isRetrying
                            ? SizedBox(
                                width: AppConstants.iconSizeMedium,
                                height: AppConstants.iconSizeMedium,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          _isRetrying
                              ? 'جارٍ المحاولة...'
                              : widget.retryButtonText,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.errorColor,
                          foregroundColor: Colors.white,
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
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
