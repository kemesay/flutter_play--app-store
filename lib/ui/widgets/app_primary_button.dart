import 'package:flutter/material.dart';

/// Primary action button with a built-in loading state, so screens don't
/// each hand-roll their own spinner-in-a-button pattern. Visual style comes
/// from the app's elevatedButtonTheme.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label);

    if (icon != null && !isLoading) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
