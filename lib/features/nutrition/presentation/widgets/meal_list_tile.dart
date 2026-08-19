import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/models.dart';

/// List row for a [NutritionLog] with icon and optional delete action.
class MealListTile extends StatelessWidget {
  const MealListTile({
    super.key,
    required this.meal,
    this.onDelete,
    this.onEdit,
  });

  final NutritionLog meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: const IconWell(icon: Icons.restaurant_outlined),
      title: meal.mealName,
      subtitle:
          '${meal.mealType} · ${meal.calories?.toStringAsFixed(0) ?? '—'} kcal',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          if (onDelete != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}
