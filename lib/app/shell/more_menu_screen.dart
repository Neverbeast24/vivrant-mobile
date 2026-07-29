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
            eyebrow: 'Modules',
            title: 'Everything',
            highlight: 'else',
          ),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VivrantColors.ink,
            ),
            decoration: InputDecoration(
              hintText: 'Search modules…',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: VivrantColors.ink.withValues(alpha: 0.45),
              ),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: VivrantColors.ink.withValues(alpha: 0.45),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _GroupChip(
                  label: 'All',
                  selected: _selectedGroup == null,
                  onTap: () => setState(() => _selectedGroup = null),
                ),
                ...filterGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _GroupChip(
                      label: group.label,
                      selected: _selectedGroup == group,
                      count: catalog.where((m) => m.group == group).length,
                      onTap: () => setState(() => _selectedGroup = group),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (visibleGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                message: 'No modules found. Try another search or category.',
              ),
            )
          else
            for (final group in visibleGroups) ...[
              SectionLabel(
                group.label,
                trailing: Text(
                  '${grouped[group]!.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: VivrantColors.ink.withValues(alpha: 0.45),
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

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label ($count)';
    return FilterChip(
      label: Text(text),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: VivrantColors.accentSoft,
      backgroundColor: VivrantColors.panel,
      side: BorderSide(
        color: selected
            ? VivrantColors.accent.withValues(alpha: 0.35)
            : VivrantColors.ink.withValues(alpha: 0.1),
      ),
      labelStyle: TextStyle(
        color: selected ? VivrantColors.accentDeep : VivrantColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
