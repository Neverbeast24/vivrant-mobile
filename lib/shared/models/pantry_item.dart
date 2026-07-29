class PantryItem {
  PantryItem({
    required this.id,
    required this.name,
    this.category = 'other',
    this.stockLevel = 50,
  });

  final int id;
  final String name;
  final String category;
  final int stockLevel;

  bool get isLowStock => stockLevel <= 25;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        stockLevel: (json['stock_level'] as num?)?.toInt() ?? 50,
      );

  PantryItem copyWith({
    int? id,
    String? name,
    String? category,
    int? stockLevel,
  }) =>
      PantryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        stockLevel: stockLevel ?? this.stockLevel,
      );
}
