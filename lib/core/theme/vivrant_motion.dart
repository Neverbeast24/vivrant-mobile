import 'package:flutter/material.dart';

/// Shared durations and curves. Keep motion botanical: soft, short, never snappy.
abstract final class VivrantMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration page = Duration(milliseconds: 400);
  static const Duration pageReverse = Duration(milliseconds: 280);
  static const Duration ambient = Duration(milliseconds: 6400);

  static const int staggerMs = 52;

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve spring = Curves.easeOutBack;

  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
