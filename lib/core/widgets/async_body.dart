import 'package:flutter/material.dart';

import 'error_view.dart';
import 'loading_view.dart';

/// Switches between loading / error / content for async screens.
class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    this.error,
    this.onRetry,
    required this.child,
  });

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null) {
      return ErrorView(message: error!, onRetry: onRetry);
    }
    return child;
  }
}
