import 'package:flutter/material.dart';

/// Widget لأزرار الإجراءات
class ActionButtonsWidget extends StatelessWidget {
  const ActionButtonsWidget({
    super.key,
    required this.actions,
    this.spacing = 8.0,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<ActionButton> actions;
  final double spacing;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      children: actions
          .map((ActionButton action) => Padding(
                padding: EdgeInsets.only(
                  right: actions.indexOf(action) < actions.length - 1
                      ? spacing
                      : 0,
                ),
                child: action,
              ))
          .toList(),
    );
}

/// زر الإجراء
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = ActionButtonType.primary,
    this.size = ActionButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ActionButtonType type;
  final ActionButtonSize size;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !isEnabled || isLoading || onPressed == null;

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: _getButtonStyle(type, size),
      child: isLoading
          ? SizedBox(
              width: _getIconSize(),
              height: _getIconSize(),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getTextColor(type),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: _getIconSize(),
                  ),
                  SizedBox(width: _getSpacing()),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  ButtonStyle _getButtonStyle(ActionButtonType type, ActionButtonSize size) {
    final ButtonColors colors = _getColors(type);
    final EdgeInsets padding = _getPadding(size);

    return ElevatedButton.styleFrom(
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(size)),
        side: BorderSide(
          color: colors.border,
        ),
      ),
      elevation: type == ActionButtonType.primary ? 2 : 0,
    );
  }

  ButtonColors _getColors(ActionButtonType type) {
    switch (type) {
      case ActionButtonType.primary:
        return const ButtonColors(
          background: Colors.blue,
          foreground: Colors.white,
          border: Colors.blue,
        );
      case ActionButtonType.secondary:
        return ButtonColors(
          background: Colors.grey[100]!,
          foreground: Colors.grey[800]!,
          border: Colors.grey[300]!,
        );
      case ActionButtonType.success:
        return const ButtonColors(
          background: Colors.green,
          foreground: Colors.white,
          border: Colors.green,
        );
      case ActionButtonType.warning:
        return const ButtonColors(
          background: Colors.orange,
          foreground: Colors.white,
          border: Colors.orange,
        );
      case ActionButtonType.danger:
        return const ButtonColors(
          background: Colors.red,
          foreground: Colors.white,
          border: Colors.red,
        );
      case ActionButtonType.outline:
        return const ButtonColors(
          background: Colors.transparent,
          foreground: Colors.blue,
          border: Colors.blue,
        );
    }
  }

  EdgeInsets _getPadding(ActionButtonSize size) {
    switch (size) {
      case ActionButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ActionButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ActionButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double _getBorderRadius(ActionButtonSize size) {
    switch (size) {
      case ActionButtonSize.small:
        return 4;
      case ActionButtonSize.medium:
        return 8;
      case ActionButtonSize.large:
        return 12;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ActionButtonSize.small:
        return 12;
      case ActionButtonSize.medium:
        return 14;
      case ActionButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ActionButtonSize.small:
        return 16;
      case ActionButtonSize.medium:
        return 18;
      case ActionButtonSize.large:
        return 20;
    }
  }

  double _getSpacing() {
    switch (size) {
      case ActionButtonSize.small:
        return 4;
      case ActionButtonSize.medium:
        return 6;
      case ActionButtonSize.large:
        return 8;
    }
  }

  Color _getTextColor(ActionButtonType type) => _getColors(type).foreground;
}

/// ألوان الزر
class ButtonColors {
  const ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

/// نوع الزر
enum ActionButtonType {
  primary,
  secondary,
  success,
  warning,
  danger,
  outline,
}

/// حجم الزر
enum ActionButtonSize {
  small,
  medium,
  large,
}

/// Widget لأزرار الإجراءات السريعة
class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({
    super.key,
    required this.actions,
    this.spacing = 8.0,
  });

  final List<QuickAction> actions;
  final double spacing;

  @override
  Widget build(BuildContext context) => Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: actions.map((QuickAction action) => action).toList(),
    );
}

/// إجراء سريع
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.blue,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
