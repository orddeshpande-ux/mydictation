import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OmniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;

  const OmniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = isSecondary
        ? theme.outlinedButtonTheme.style
        : theme.elevatedButtonTheme.style;

    final VoidCallback? handlePress = (onPressed == null || isLoading)
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };

    Widget buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: isSecondary
                  ? theme.colorScheme.primary
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    if (isSecondary) {
      return OutlinedButton(
        onPressed: handlePress,
        style: buttonStyle,
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: handlePress,
      style: buttonStyle,
      child: buttonChild,
    );
  }
}
