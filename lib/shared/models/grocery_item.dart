class GroceryItem {
  GroceryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.category = 'other',
    this.isChecked = false,
    this.estimatedPrice,
  });

  final int id;
  final String name;
  final String? quantity;
  final String category;
  final bool isChecked;
  final double? estimatedPrice;

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String?,
        category: json['category'] as String? ?? 'other',
        isChecked: json['is_checked'] as bool? ?? false,
        estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      );
}
