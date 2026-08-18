import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor = colorScheme.surfaceContainerHighest;
    Color textColor = colorScheme.onSurface;
    IconData iconData = icon ?? Icons.info_outline_rounded;
    Color iconColor = colorScheme.primary;

    if (isError) {
      bgColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      iconData = icon ?? Icons.error_outline_rounded;
      iconColor = colorScheme.error;
    } else if (isSuccess) {
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      iconData = icon ?? Icons.check_circle_outline_rounded;
      iconColor = colorScheme.primary;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError
                ? colorScheme.error.withAlpha(80)
                : colorScheme.outlineVariant.withAlpha(100),
          ),
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
