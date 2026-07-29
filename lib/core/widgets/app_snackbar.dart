import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/vivrant_colors.dart';

enum SnackTone { success, error, info, warning }

/// Shows a branded floating toast. Prefer this over raw [SnackBar]s.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackTone tone = SnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      content: _AppSnackCard(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
        onDismiss: () => messenger.hideCurrentSnackBar(),
      ),
    ),
  );
}

class _AppSnackCard extends StatelessWidget {
  const _AppSnackCard({
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  final String message;
  final SnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = _toneStyle(dark);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.iconWell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      style.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: style.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: style.foreground,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onAction,
                        child: Text(
                          actionLabel!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: style.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: style.foreground.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SnackToneStyle _toneStyle(bool dark) {
    switch (tone) {
      case SnackTone.success:
        return _SnackToneStyle(
          label: 'Success',
          icon: Icons.check_circle_rounded,
          accent: dark ? VivrantColors.darkAccent : VivrantColors.accent,
          background: dark ? const Color(0xFF16352E) : const Color(0xFFECF8F3),
          iconWell: dark
              ? VivrantColors.darkAccent.withValues(alpha: 0.18)
              : VivrantColors.accentSoft,
          border: (dark ? VivrantColors.darkAccent : VivrantColors.accent)
              .withValues(alpha: 0.28),
          foreground: dark ? VivrantColors.darkInk : VivrantColors.ink,
        );
      case SnackTone.error:
        return _SnackToneStyle(
          label: 'Something went wrong',
          icon: Icons.error_outline_rounded,
          accent: dark ? const Color(0xFFF97066) : const Color(0xFFB42318),
          background: dark ? const Color(0xFF2A1716) : const Color(0xFFFFF1F0),
          iconWell: dark
              ? const Color(0xFFF97066).withValues(alpha: 0.16)
              : const Color(0xFFFEE4E2),
          border: (dark ? const Color(0xFFF97066) : const Color(0xFFB42318))
              .withValues(alpha: 0.28),
          foreground: dark ? VivrantColors.darkInk : VivrantColors.ink,
        );
      case SnackTone.warning:
        return _SnackToneStyle(
          label: 'Heads up',
          icon: Icons.warning_amber_rounded,
          accent: dark ? const Color(0xFFFDB022) : const Color(0xFFB54708),
          background: dark ? const Color(0xFF2A2114) : const Color(0xFFFFFAEB),
          iconWell: dark
              ? const Color(0xFFFDB022).withValues(alpha: 0.16)
              : const Color(0xFFFEF0C7),
          border: (dark ? const Color(0xFFFDB022) : const Color(0xFFB54708))
              .withValues(alpha: 0.28),
          foreground: dark ? VivrantColors.darkInk : VivrantColors.ink,
        );
      case SnackTone.info:
        return _SnackToneStyle(
          label: 'Notice',
          icon: Icons.info_outline_rounded,
          accent: dark ? VivrantColors.darkCyan : VivrantColors.cyan,
          background: dark ? VivrantColors.darkPanel : VivrantColors.panel,
          iconWell: dark
              ? VivrantColors.darkCyan.withValues(alpha: 0.16)
              : VivrantColors.accentSoft,
          border: VivrantColors.ink.withValues(alpha: dark ? 0.2 : 0.08),
          foreground: dark ? VivrantColors.darkInk : VivrantColors.ink,
        );
    }
  }
}

class _SnackToneStyle {
  const _SnackToneStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
    required this.iconWell,
    required this.border,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color iconWell;
  final Color border;
  final Color foreground;
}
