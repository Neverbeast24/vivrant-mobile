import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Kitchen directory — shopping and pantry live on their own pages.
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
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Kitchen',
            title: 'Shop and',
            highlight: 'stock',
          ),
          Text(
            'Shopping and pantry each get their own page — nothing stacked here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SectionGap(),
          ...staggerAppear([
            ModuleTile(
              icon: Icons.shopping_basket_outlined,
              label: 'Shopping',
              caption: 'Checklist and restock',
              onTap: () => context.push('/groceries'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.kitchen_outlined,
              label: 'Pantry',
              caption: 'Stock levels and low items',
              onTap: () => context.push('/pantry'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.tune_rounded,
              label: 'List tools',
              caption: 'Low stock, restock, and smart plan',
              onTap: () => context.push('/groceries/tools'),
            ),
          ]),
        ],
      ),
    );
  }
}
