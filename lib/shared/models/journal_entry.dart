class JournalEntry {
  JournalEntry({
    required this.id,
    required this.entryDate,
    this.title,
    required this.body,
    this.mood,
  });

  final int id;
  final String entryDate;
  final String? title;
  final String body;
  final int? mood;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: (json['id'] as num).toInt(),
        entryDate: json['entry_date'] as String? ?? '',
        title: json['title'] as String?,
        body: json['body'] as String? ?? '',
        mood: (json['mood'] as num?)?.toInt(),
      );
}
