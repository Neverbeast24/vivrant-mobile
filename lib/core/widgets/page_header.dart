import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/vivrant_colors.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.highlight,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? highlight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.accent,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                              height: 1.15,
                            ),
                      ),
                      if (highlight != null)
                        TextSpan(
                          text: ' $highlight',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: c.accentDeep,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
