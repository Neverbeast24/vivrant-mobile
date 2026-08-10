import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Groceries + pantry entry (mirrors web Kitchen hub).
class KitchenHubScreen extends StatelessWidget {
  const KitchenHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const PageHeader(
            eyebrow: 'Kitchen',
            title: 'Shop and',
            highlight: 'stock',
          ),
          Text(
            'Shopping list for what you need, pantry for what you have.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ModuleTile(
            icon: Icons.shopping_basket_outlined,
            label: 'Shopping',
            caption: 'Smart grocery list',
            onTap: () => context.push('/groceries'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.kitchen_outlined,
            label: 'Pantry',
            caption: 'Stock at a glance',
            onTap: () => context.push('/pantry'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.add_box_outlined,
            label: 'Add pantry item',
            caption: 'Log new stock',
            onTap: () => context.push('/pantry/add'),
          ),
        ],
      ),
    );
  }
}
