import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/vivrant_colors.dart';

/// List vs spreadsheet vs paste entry, shared by groceries, pantry, nutrition, spending.
enum EasyEntryMode { list, sheet, paste }

const _entryPrefix = 'vivrant-entry-';

Future<EasyEntryMode> loadEasyEntryMode(
  String storageKey, [
  EasyEntryMode fallback = EasyEntryMode.list,
]) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_entryPrefix$storageKey');
    if (saved == 'form' || saved == 'list') return EasyEntryMode.list;
    if (saved == 'sheet') return EasyEntryMode.sheet;
    if (saved == 'paste') return EasyEntryMode.paste;
  } catch (_) {}
  return fallback;
}

Future<void> saveEasyEntryMode(String storageKey, EasyEntryMode mode) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_entryPrefix$storageKey', mode.name);
  } catch (_) {}
}

/// Segmented control for [EasyEntryMode].
class EasyEntryToggle extends StatelessWidget {
  const EasyEntryToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final EasyEntryMode value;
  final ValueChanged<EasyEntryMode> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(context, EasyEntryMode.list, 'List', Icons.view_list_outlined),
            _chip(context, EasyEntryMode.sheet, 'Sheet', Icons.table_chart_outlined),
            _chip(
              context,
              EasyEntryMode.paste,
              'Quick list',
              Icons.playlist_add_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hint ??
              (value == EasyEntryMode.sheet
                  ? 'Excel-style table. Name is enough.'
                  : value == EasyEntryMode.paste
                      ? 'Paste names, one per line.'
                      : 'Simple list. Add with just a name.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    EasyEntryMode mode,
    String label,
    IconData icon,
  ) {
    final c = VivrantColors.of(context);
    final selected = value == mode;
    return FilterChip(
      avatar: Icon(icon, size: 16, color: selected ? c.accent : c.muted),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onChanged(mode),
      selectedColor: c.accentSoft,
      backgroundColor: c.panel,
      side: BorderSide(
        color: selected
            ? c.accent.withValues(alpha: 0.35)
            : c.ink.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        color: selected ? c.accentDeep : c.ink,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}
