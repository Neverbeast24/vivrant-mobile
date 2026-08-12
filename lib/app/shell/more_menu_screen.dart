import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vivrant_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/constants/app_modules.dart';
import '../../shared/providers/auth_provider.dart';

class MoreMenuScreen extends ConsumerStatefulWidget {
  const MoreMenuScreen({super.key});

  @override
  ConsumerState<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends ConsumerState<MoreMenuScreen> {
  final _query = TextEditingController();
  ModuleGroup? _selectedGroup;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<AppModule> get _catalog {
    final role = ref.watch(authProvider).profile?.role;
    return modulesForRole(role);
  }

  List<AppModule> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _catalog.where((module) {
      if (_selectedGroup != null && module.group != _selectedGroup) {
        return false;
      }
      if (q.isEmpty) return true;
      return module.label.toLowerCase().contains(q) ||
          module.caption.toLowerCase().contains(q) ||
          module.group.label.toLowerCase().contains(q);
    }).toList();
  }

  Map<ModuleGroup, List<AppModule>> get _grouped {
    final grouped = <ModuleGroup, List<AppModule>>{};
    for (final module in _filtered) {
      grouped.putIfAbsent(module.group, () => []).add(module);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final catalog = _catalog;
    final grouped = _grouped;
    final visibleGroups = ModuleGroup.values
        .where((group) => grouped[group]?.isNotEmpty == true)
        .toList();
    final filterGroups = ModuleGroup.values
        .where((group) => catalog.any((m) => m.group == group))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const VivrantBrand(),
          const SizedBox(height: 24),
          const PageHeader(
            eyebrow: 'More',
            title: 'More',
            highlight: 'tools',
          ),
          VivrantSearchField(
            controller: _query,
            hintText: 'Search features…',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          VivrantFilterChips<ModuleGroup?>(
            options: [
              VivrantFilterOption(
                value: null,
                label: 'All',
                count: catalog.length,
              ),
              ...filterGroups.map(
                (group) => VivrantFilterOption(
                  value: group,
                  label: group.label,
                  count: catalog.where((m) => m.group == group).length,
                ),
              ),
            ],
            selected: _selectedGroup,
            onSelected: (group) => setState(() => _selectedGroup = group),
          ),
          const SizedBox(height: 20),
          if (visibleGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                title: 'Nothing found',
                message: 'Try another word or pick a different category.',
              ),
            )
          else
            for (final group in visibleGroups) ...[
              SectionLabel(
                group.label,
                trailing: Text(
                  '${grouped[group]!.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.ink.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...grouped[group]!.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ModuleTile(
                    icon: item.icon,
                    label: item.label,
                    caption: item.caption,
                    onTap: () => context.push(item.path),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
