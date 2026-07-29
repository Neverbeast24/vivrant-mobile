class AiChatMessage {
  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.followUp,
  });

  final int id;
  final String role; // user | viva
  final String content;
  final String? followUp;

  bool get isUser => role == 'user';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
        id: (json['id'] as num).toInt(),
        role: json['role'] as String? ?? 'viva',
        content: json['content'] as String? ?? '',
        followUp: json['follow_up'] as String?,
      );
}
