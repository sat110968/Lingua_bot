import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey = 'OPENAI-API-KEY'; // Will be replaced in production
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Store system message based on selected language and mode
  String _getSystemMessage(String learningLanguage, String nativeLanguage, String mode) {
    return '''You are an expert language tutor for $learningLanguage. The user's native language is $nativeLanguage.
You're helping them practice $learningLanguage through conversation in a $mode practice session.
Keep responses natural, conversational and appropriate for language learners.
Correct major errors gently, but maintain conversation flow.
If the mode is 'vocabulary', focus on introducing new words and checking understanding.
If the mode is 'grammar', pay more attention to sentence structure and grammar rules.
If the mode is 'conversation', focus on natural dialogue and cultural context.
Speak primarily in $learningLanguage but offer explanations in $nativeLanguage when helpful.
Keep responses concise (under 100 words) and engaging.''';
  }

  Future<String> sendMessage({
    required String userMessage,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
    required List<Map<String, String>> chatHistory,
  }) async {
    final systemMessage = _getSystemMessage(learningLanguage, nativeLanguage, mode);
    
    // Build the messages array including history
    final List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': systemMessage},
    ];
    
    // Add chat history (limited to last 10 messages to keep context manageable)
    final historyToInclude = chatHistory.length <= 10 
        ? chatHistory 
        : chatHistory.sublist(chatHistory.length - 10);
    
    for (final message in historyToInclude) {
      messages.add({
        'role': message['role']!,
        'content': message['content']!,
      });
    }
    
    // Add the current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return responseData['choices'][0]['message']['content'];
      } else {
        print('OpenAI API error: ${response.statusCode} ${response.body}');
        return "I'm sorry, I couldn't process your message right now. Please try again.";
      }
    } catch (e) {
      print('Exception in OpenAI service: $e');
      return "I'm sorry, there was a problem connecting to the language tutor service. Please check your connection and try again.";
    }
  }
}