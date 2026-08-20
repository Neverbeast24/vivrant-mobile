// Parse pasted notepad / spreadsheet lists into cell rows.
// Kept in lockstep with viva-server `src/lib/lists/parse-quick-list.ts`.

final _headerRe = RegExp(
  r'^(name|item|title|grocery|meal|expense|qty|quantity|category|price|amount|#)$',
  caseSensitive: false,
);

double? asNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final n = double.tryParse(value.replaceAll(RegExp(r'[₱$,]'), '').trim());
  return n;
}

List<String> splitCsv(String line) {
  final cells = <String>[];
  var current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      quoted = !quoted;
      continue;
    }
    if (ch == ',' && !quoted) {
      cells.add(current.toString().trim());
      current = StringBuffer();
      continue;
    }
    current.write(ch);
  }
  cells.add(current.toString().trim());
  return cells;
}

/// Turn a pasted block into rows of cells (tabs, commas, or one name per line).
List<List<String>> parseSpreadsheetPaste(String text, {int maxRows = 40}) {
  final lines = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
  if (lines.isEmpty) return const [];

  final hasTab = lines.any((line) => line.contains('\t'));
  final commaLines = lines.where((line) => line.contains(',')).length;
  final useComma = !hasTab && commaLines >= (lines.length / 2).ceil();

  final rows = <List<String>>[];
  for (final line in lines) {
    final raw = hasTab
        ? line.split('\t')
        : useComma
            ? splitCsv(line)
            : [line];
    final cells = raw
        .map((cell) => cell.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''))
        .toList();
    if (cells.isNotEmpty && cells.first.isNotEmpty) rows.add(cells);
  }
  if (rows.isNotEmpty && _headerRe.hasMatch(rows.first.first)) {
    rows.removeAt(0);
  }
  if (rows.length > maxRows) return rows.sublist(0, maxRows);
  return rows;
}

class TypedListLine {
  const TypedListLine({
    required this.name,
    this.quantity,
    this.category,
    this.amount,
  });

  final String name;
  final String? quantity;
  final String? category;
  final double? amount;
}

TypedListLine mapTypedLine(
  List<String> cells,
  Iterable<String> knownCategories,
) {
  final categories = {
    for (final value in knownCategories) value.toLowerCase(),
  };
  final name = cells.isNotEmpty ? cells.first.trim() : '';
  String? quantity;
  String? category;
  double? amount;

  for (final cell in cells.skip(1)) {
    if (cell.isEmpty) continue;
    final lower = cell.toLowerCase();
    final numeric = asNumber(cell);
    final looksNumeric =
        RegExp(r'^-?\d').hasMatch(cell.replaceAll(RegExp(r'[₱$,\s]'), ''));
    if (categories.contains(lower)) {
      category = lower;
    } else if (looksNumeric && numeric != null) {
      amount = numeric;
    } else {
      quantity ??= cell;
    }
  }

  return TypedListLine(
    name: name,
    quantity: quantity,
    category: category,
    amount: amount,
  );
}
