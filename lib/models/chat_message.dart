enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? audioPath;
  final bool isError;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.audioPath,
    this.isError = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  // Convert to a map for storing in SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'isError': isError,
    };
  }

  // Create message from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],
      isError: json['isError'] ?? false,
    );
  }
}