class CachedResponse {
  final String id;
  final String userQuery;
  final String aiResponse;
  final double similarity;

  CachedResponse({
    required this.id,
    required this.userQuery,
    required this.aiResponse,
    required this.similarity,
  });

  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      id: json['id'] as String,
      userQuery: json['user_query'] as String,
      aiResponse: json['ai_response'] as String,
      // Ensure similarity is parsed securely
      similarity: (json['similarity'] is int) 
          ? (json['similarity'] as int).toDouble() 
          : json['similarity'] as double,
    );
  }
}
