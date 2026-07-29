class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.spentAt,
  });

  final int id;
  final String title;
  final String category;
  final double amount;
  final DateTime spentAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        spentAt:
            DateTime.tryParse(json['spent_at'] as String? ?? '') ?? DateTime.now(),
      );
}
