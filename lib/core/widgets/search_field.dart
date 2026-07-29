import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

/// Branded search field used across list panels.
class VivrantSearchField extends StatelessWidget {
  const VivrantSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search…',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: c.ink.withValues(alpha: 0.45),
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: c.ink.withValues(alpha: 0.45),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
