import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

/// Horizontally scrollable spreadsheet-style table (light + dark).
class ExcelTable extends StatelessWidget {
  const ExcelTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.highlightLastRow = false,
  });

  final List<String> headers;
  final List<List<Widget>> rows;
  final Map<int, TableColumnWidth>? columnWidths;
  final bool highlightLastRow;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final border = BorderSide(color: c.ink.withValues(alpha: 0.12));
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.ink.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          columnWidths: columnWidths,
          border: TableBorder(
            horizontalInside: border,
            verticalInside: border,
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: c.accentSoft),
              children: [
                for (final header in headers)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      header.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: c.muted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ),
              ],
            ),
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: highlightLastRow && i == rows.length - 1
                      ? c.accentSoft.withValues(alpha: c.isDark ? 0.45 : 0.65)
                      : i.isEven
                          ? c.panel
                          : c.card,
                ),
                children: [
                  for (final cell in rows[i])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        child: IconTheme.merge(
                          data: IconThemeData(color: c.muted, size: 18),
                          child: cell,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ExcelCellField extends StatelessWidget {
  const ExcelCellField({
    super.key,
    required this.controller,
    this.width = 120,
    this.hint,
    this.keyboardType,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final double width;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        onSubmitted: onSubmitted,
        cursorColor: c.accent,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.ink,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
      ),
    );
  }
}

class ExcelDropdown<T> extends StatelessWidget {
  const ExcelDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return DropdownButton<T>(
      value: value,
      isDense: true,
      underline: const SizedBox.shrink(),
      dropdownColor: c.card,
      iconEnabledColor: c.muted,
      style: TextStyle(
        color: c.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
