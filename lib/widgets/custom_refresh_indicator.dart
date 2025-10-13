import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom refresh indicator with modern design
class CustomRefreshIndicator extends StatelessWidget {
  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.strokeWidth = 2.5,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppConstants.primaryColor,
      backgroundColor: backgroundColor ??
          (isDark ? theme.colorScheme.surface : Colors.white),
      displacement: displacement,
      strokeWidth: strokeWidth,
      child: child,
    );
  }
}

/// Advanced custom refresh indicator with custom animation
class AdvancedRefreshIndicator extends StatefulWidget {
  const AdvancedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<AdvancedRefreshIndicator> createState() =>
      _AdvancedRefreshIndicatorState();
}

class _AdvancedRefreshIndicatorState extends State<AdvancedRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        try {
          _controller.stop();
          _controller.reset();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? AppConstants.primaryColor,
      notificationPredicate: widget.notificationPredicate,
      child: widget.child,
    );
  }
}

/// Custom refresh header widget
class CustomRefreshHeader extends StatelessWidget {
  const CustomRefreshHeader({
    super.key,
    required this.refreshState,
    this.color,
  });

  final RefreshIndicatorMode refreshState;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    Widget child;
    String text;

    switch (refreshState) {
      case RefreshIndicatorMode.drag:
        child = Icon(
          Icons.arrow_downward_rounded,
          color: primaryColor,
          size: AppConstants.iconSizeLarge,
        );
        text = 'اسحب للتحديث';
        break;
      case RefreshIndicatorMode.armed:
        child = Icon(
          Icons.refresh_rounded,
          color: primaryColor,
          size: AppConstants.iconSizeLarge,
        );
        text = 'أفلت للتحديث';
        break;
      case RefreshIndicatorMode.refresh:
        child = SizedBox(
          width: AppConstants.iconSizeLarge,
          height: AppConstants.iconSizeLarge,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
        text = 'جارٍ التحديث...';
        break;
      case RefreshIndicatorMode.done:
        child = Icon(
          Icons.check_circle_rounded,
          color: AppConstants.successColor,
          size: AppConstants.iconSizeLarge,
        );
        text = 'تم التحديث';
        break;
      case RefreshIndicatorMode.inactive:
        return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: AppConstants.spacing8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppConstants.textSecondaryColor,
              fontWeight: AppConstants.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Refresh indicator modes
enum RefreshIndicatorMode {
  inactive,
  drag,
  armed,
  refresh,
  done,
}
