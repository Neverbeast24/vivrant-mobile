import 'package:flutter/material.dart';

/// Botanical design tokens mirrored from viva-server `globals.css`.
abstract final class VivrantColors {
  // Light
  static const ink = Color(0xFF14221B);
  static const muted = Color(0xFF4A5C54);
  static const accent = Color(0xFF0E7C66);
  static const accentDeep = Color(0xFF0A5C4C);
  static const accentSoft = Color(0xFFD7EFE6);
  static const cyan = Color(0xFF2A9D8F);
  static const paper = Color(0xFFE7EEE9);
  static const card = Color(0xFFF6FAF7);
  static const surface = Color(0xFFE8EFE9);
  static const surfaceSoft = Color(0xFFDCE8E1);
  static const panel = Color(0xFFFFFFFF);
  static const warm = Color(0xFFEAE4D6);
  static const body0 = Color(0xFFEEF4F0);
  static const body1 = Color(0xFFE3EBE5);
  static const solid = Color(0xFF14221B);
  static const solidFg = Color(0xFFFFFFFF);
  static const inverse = Color(0xFF14221B);
  static const inverseFg = Color(0xFFFFFFFF);

  // Dark
  static const darkInk = Color(0xFFE8F0EB);
  static const darkMuted = Color(0xFFC5D4CB);
  static const darkAccent = Color(0xFF3DB896);
  static const darkAccentDeep = Color(0xFF2A9D8F);
  static const darkAccentSoft = Color(0xFF16352E);
  static const darkCyan = Color(0xFF4EC4B6);
  static const darkPaper = Color(0xFF0F1612);
  static const darkCard = Color(0xFF17201A);
  static const darkSurface = Color(0xFF1C2620);
  static const darkSurfaceSoft = Color(0xFF24302A);
  static const darkPanel = Color(0xFF1C2620);
  static const darkBody0 = Color(0xFF0C1210);
  static const darkBody1 = Color(0xFF121A16);
  static const darkSolid = Color(0xFF0A100D);
  static const darkWarm = Color(0xFF2A322C);

  static const line = Color(0x1C14221B);
  static const darkLine = Color(0x33E8F0EB);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDeep, accent, cyan],
  );

  static const LinearGradient bodyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [body0, body1],
  );

  static const LinearGradient darkBodyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBody0, darkBody1],
  );
}
