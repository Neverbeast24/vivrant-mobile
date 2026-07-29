class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.href,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? body;
  final String? href;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        href: json['href'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}
