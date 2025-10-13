import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Modern bottom navigation bar with animations and badges
class ModernBottomNavigation extends StatefulWidget {
  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
    this.showLabels = true,
    this.enableHaptics = true,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final List<ModernNavItem> items;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  final bool showLabels;
  final bool enableHaptics;

  @override
  State<ModernBottomNavigation> createState() => _ModernBottomNavigationState();
}

class _ModernBottomNavigationState extends State<ModernBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: AppConstants.animationNormal,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Animate the current item
    if (mounted) {
      try {
        _controllers[widget.currentIndex].forward();
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }
  }

  @override
  void didUpdateWidget(ModernBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (mounted) {
        try {
          _controllers[oldWidget.currentIndex].reverse();
          _controllers[widget.currentIndex].forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;
    final unselectedColor = widget.unselectedColor ??
        (isDark
            ? AppConstants.textSecondaryColor
            : AppConstants.lightTextColor);
    final backgroundColor = widget.backgroundColor ??
        (isDark ? theme.colorScheme.surface : Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppConstants.buttonHeightLarge + AppConstants.spacing16,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing8,
            vertical: AppConstants.spacing8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(
                index,
                widget.items[index],
                selectedColor,
                unselectedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    ModernNavItem item,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final isSelected = index == widget.currentIndex;
    final color = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: AnimatedBuilder(
        animation: _controllers[index],
        builder: (context, child) {
          return InkWell(
            onTap: () {
              if (widget.enableHaptics) {
                // Add haptic feedback here if needed
              }
              widget.onTap(index);
            },
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacing8,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimations[index],
                        child: FadeTransition(
                          opacity: _fadeAnimations[index],
                          child: Icon(
                            isSelected
                                ? item.selectedIcon ?? item.icon
                                : item.icon,
                            color: color,
                            size: AppConstants.iconSizeLarge,
                          ),
                        ),
                      ),
                      if (item.badge != null && item.badge! > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding:
                                const EdgeInsets.all(AppConstants.spacing4),
                            decoration: BoxDecoration(
                              color: AppConstants.errorColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                item.badge! > 99 ? '99+' : '${item.badge}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: item.badge! > 99 ? 8 : 10,
                                  fontWeight: AppConstants.fontWeightBold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Label
                  if (widget.showLabels) ...[
                    const SizedBox(height: AppConstants.spacing4),
                    FadeTransition(
                      opacity: _fadeAnimations[index],
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: AppConstants.fontSizeCaption,
                          fontWeight: isSelected
                              ? AppConstants.fontWeightSemiBold
                              : AppConstants.fontWeightMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Navigation item model
class ModernNavItem {
  const ModernNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
  });

  final IconData icon;
  final String label;
  final IconData? selectedIcon;
  final int? badge;
}

/// Floating bottom navigation bar variant
class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.unselectedColor,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final List<ModernNavItem> items;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Container(
        height: AppConstants.buttonHeightLarge,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppConstants.shadowDarkColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ModernBottomNavigation(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          selectedColor: selectedColor,
          unselectedColor: unselectedColor,
          showLabels: false,
        ),
      ),
    );
  }
}
