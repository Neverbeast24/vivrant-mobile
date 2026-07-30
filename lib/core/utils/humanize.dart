/// Turns API keys like `lower_back` into `Lower back`.
String humanizeLabel(String value) {
  final cleaned = value.trim().replaceAll('_', ' ');
  if (cleaned.isEmpty) return cleaned;
  return cleaned
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1)}';
      })
      .join(' ');
}
