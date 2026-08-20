import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/vivrant_motion.dart';

enum VivrantTransition { sharedAxis, fadeThrough }

CustomTransitionPage<T> vivrantPage<T>({
  required LocalKey key,
  required Widget child,
  VivrantTransition transition = VivrantTransition.sharedAxis,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: VivrantMotion.page,
    reverseTransitionDuration: VivrantMotion.pageReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (VivrantMotion.reduce(context)) return child;
      switch (transition) {
        case VivrantTransition.fadeThrough:
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          );
        case VivrantTransition.sharedAxis:
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Colors.transparent,
            child: child,
          );
      }
    },
  );
}

GoRoute vivrantGoRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  List<RouteBase> routes = const [],
  VivrantTransition transition = VivrantTransition.sharedAxis,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => vivrantPage(
      key: state.pageKey,
      child: builder(context, state),
      transition: transition,
    ),
    routes: routes,
  );
}
