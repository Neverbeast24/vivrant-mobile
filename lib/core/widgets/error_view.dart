import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Error + retry wrapper for failed network loads.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
    );
  }
}
