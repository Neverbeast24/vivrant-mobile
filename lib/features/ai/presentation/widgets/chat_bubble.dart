import 'package:flutter/material.dart';

import '../../../../core/theme/vivrant_colors.dart';

/// Chat bubble for user vs Viva messages.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
  });

  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? c.accentSoft : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.ink.withValues(alpha: 0.08)),
        ),
        child: Text(
          content,
          style: TextStyle(color: c.ink, height: 1.4),
        ),
      ),
    );
  }
}
