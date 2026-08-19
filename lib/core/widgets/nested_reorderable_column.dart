import 'package:flutter/material.dart';

import '../utils/list_order.dart';

/// Nested reorderable list for saved module rows inside a parent [ListView].
class NestedReorderableColumn extends StatelessWidget {
  const NestedReorderableColumn({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.keyOf,
    required this.onReorder,
    this.enabled = true,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Object Function(int index) keyOf;
  final void Function(int from, int to) onReorder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || itemCount < 2) {
      return Column(
        children: [
          for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
        ],
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      onReorder: (oldIndex, newIndex) {
        onReorder(oldIndex, normalizeReorderIndex(oldIndex, newIndex));
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 1,
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        return KeyedSubtree(
          key: ValueKey(keyOf(index)),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
