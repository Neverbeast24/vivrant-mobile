List<T> applyIdOrder<T>(
  List<T> items,
  List<int> order,
  int Function(T item) idOf,
) {
  if (order.isEmpty || items.isEmpty) return items;
  final byId = <int, T>{
    for (final item in items) idOf(item): item,
  };
  final seen = <int>{};
  final out = <T>[];
  for (final id in order) {
    final item = byId[id];
    if (item == null || !seen.add(id)) continue;
    out.add(item);
  }
  for (final item in items) {
    if (seen.add(idOf(item))) out.add(item);
  }
  return out;
}

List<int> parseModuleListOrder(Map<String, dynamic> settings, String module) {
  final raw = settings['list_order'];
  if (raw is! Map) return const [];
  final value = raw[module];
  if (value is! List) return const [];
  return value
      .map((id) => id is num ? id.round() : int.tryParse(id.toString()) ?? 0)
      .where((id) => id > 0)
      .take(200)
      .toList();
}

List<T> moveItem<T>(List<T> list, int from, int to) {
  if (from == to || from < 0 || to < 0 || from >= list.length || to >= list.length) {
    return list;
  }
  final next = List<T>.from(list);
  final item = next.removeAt(from);
  next.insert(to, item);
  return next;
}

int normalizeReorderIndex(int oldIndex, int newIndex) {
  if (newIndex > oldIndex) return newIndex - 1;
  return newIndex;
}
