import 'package:flutter/material.dart';
import 'package:h2orbit/utils/theme.dart';

/// One place for every snackbar so they all look and behave the same.
void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: isError ? const Color(0xFF7A2230) : AppTheme.deepCyan,
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppTheme.danger : AppTheme.lightCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppTheme.lightCyan,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}
