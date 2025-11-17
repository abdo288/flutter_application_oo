import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

/// Animated statistics card with counter animation
class AnimatedStatCard extends StatefulWidget {
  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.info_outline_rounded,
    this.color,
    this.prefix = '',
    this.suffix = '',
    this.trend,
    this.trendValue,
    this.duration = AppConstants.animationNormal,
    this.delay = Duration.zero,
    this.onTap,
  });

  final String title;
  final num value;
  final IconData icon;
  final Color? color;
  final String prefix;
  final String suffix;
  final String? trend; // 'up', 'down', or null
  final num? trendValue;
  final Duration duration;
  final Duration delay;
  final VoidCallback? onTap;

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _counterAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _counterAnimation =
        Tween<double>(begin: 0.0, end: widget.value.toDouble()).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Delay animation start
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        try {
          _controller.forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _counterAnimation = Tween<double>(
        begin: oldWidget.value.toDouble(),
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
      if (mounted) {
        try {
          _controller
            ..reset()
            ..forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _cardColor =>
      widget.color ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppConstants.primaryColor
          : AppConstants.primaryColor);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) => FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: AppConstants.animationFast,
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()
                      ..scale(_isHovered ? 1.02 : 1.0)
                      ..translate(0.0, _isHovered ? -4.0 : 0.0),
                    margin: EdgeInsets.all(context.responsiveSpacing * 0.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          _cardColor,
                          _cardColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        context.isSmallScreen ? 8 : 12,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _cardColor.withValues(
                              alpha: _isHovered ? 0.4 : 0.2),
                          blurRadius: _isHovered ? 16 : 12,
                          offset: Offset(0, _isHovered ? 8 : 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        context.isSmallScreen ? 8 : 12,
                      ),
                      child: Container(
                        padding: context.responsivePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // Icon and trend row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(
                                    context.responsiveSpacing * 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(
                                      context.isSmallScreen ? 6 : 8,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: Colors.white,
                                    size: context.responsiveFontSize(26),
                                  ),
                                ),
                                if (widget.trend != null &&
                                    widget.trendValue != null)
                                  _buildTrendIndicator(context),
                              ],
                            ),
                            SizedBox(height: context.responsiveSpacing * 0.5),

                            // Animated value
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${widget.prefix}${_counterAnimation.value.toStringAsFixed(0)}${widget.suffix}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: AppConstants.fontWeightBold,
                                  fontSize: context.responsiveFontSize(28),
                                  letterSpacing:
                                      AppConstants.letterSpacingTight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: context.responsiveSpacing * 0.3),

                            // Title
                            Text(
                              widget.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: AppConstants.fontWeightMedium,
                                fontSize: context.responsiveFontSize(14),
                              ),
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
          ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final bool isPositive = widget.trend == 'up';
    final IconData icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing * 0.3,
        vertical: context.responsiveSpacing * 0.2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: Colors.white,
            size:
                context.responsiveFontSize(16), // استخدام responsive font size
          ),
          SizedBox(width: context.responsiveSpacing * 0.2),
          Text(
            widget.trendValue is num
                ? '${widget.trendValue!.toStringAsFixed(1)}%'
                : widget.trendValue.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsiveFontSize(12), // زيادة من 10 إلى 12
              fontWeight: AppConstants.fontWeightBold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Compact stat card variant
class CompactStatCard extends StatelessWidget {
  const CompactStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = color ?? AppConstants.primaryColor;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            context.isSmallScreen ? 6 : 8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 6 : 8,
            ),
            child: Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: isDark
                    ? cardColor.withValues(alpha: 0.2)
                    : cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  context.isSmallScreen ? 6 : 8,
                ),
                border: Border.all(
                  color: cardColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    color: cardColor,
                    size: context.responsiveFontSize(22),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cardColor,
                            fontWeight: AppConstants.fontWeightBold,
                            fontSize: context.responsiveFontSize(16),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.1),
                        Text(
                          title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppConstants.textSecondaryColor
                                : AppConstants.textSecondaryColor,
                            fontSize: context.responsiveFontSize(12),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
