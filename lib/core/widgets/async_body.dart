import 'package:flutter/material.dart';

import 'error_view.dart';
import 'fade_slide_in.dart';
import 'loading_view.dart';
import '../theme/vivrant_motion.dart';

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
    Widget body;
    if (loading) {
      body = const LoadingView(key: ValueKey('loading'));
    } else if (error != null) {
      body = ErrorView(
        key: const ValueKey('error'),
        message: error!,
        onRetry: onRetry,
      );
    } else {
      body = FadeSlideIn(
        key: const ValueKey('body'),
        child: child,
      );
    }

    return AnimatedSwitcher(
      duration: VivrantMotion.base,
      switchInCurve: VivrantMotion.enter,
      switchOutCurve: VivrantMotion.exit,
      child: body,
    );
  }
}
