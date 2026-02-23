import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class GeminiService {
  // TODO: Move this key to secure storage or env vars before release.
  static const _apiKey = 'AIzaSyDfiN5cm0F42YzyLo4geyBKu42fOqTQbhU';

  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  String _getSystemPrompt(String learningLanguage, String nativeLanguage, String mode) {
    return '''You are an expert language tutor for $learningLanguage. The user's native language is $nativeLanguage.
You're helping them practice $learningLanguage through conversation in a '$mode' practice session.
Keep responses natural, conversational and appropriate for language learners.
Correct major errors gently, but maintain conversation flow.
If the mode is 'vocabulary', focus on introducing new words and checking understanding.
If the mode is 'grammar', pay more attention to sentence structure and grammar rules.
If the mode is 'conversation', focus on natural dialogue and cultural context.
Speak primarily in $learningLanguage but offer explanations in $nativeLanguage when helpful.
Keep responses concise (under 100 words) and engaging.
Your response should follow this format:
Response in $learningLanguage
|||
Explanation or translation in $nativeLanguage
''';
  }

  Future<String> generateResponse({
    required List<ChatMessage> history,
    required String message,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
  }) async {
    try {
      debugPrint('🔵 Attempting Gemini call with model: gemini-1.5-flash-latest');
      debugPrint('🔵 Message: $message');
      
      final systemInstruction = Content.system(
        _getSystemPrompt(learningLanguage, nativeLanguage, mode),
      );
      final chatHistory = _buildHistory(history);
      final chat = _model.startChat(history: [systemInstruction, ...chatHistory]);

      final response = await chat.sendMessage(Content.text(message));
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Received empty response from Gemini.');
      }
      
      debugPrint('✅ Gemini response received successfully');
      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API Error: ${e.message}');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return _buildFallback(message, learningLanguage, nativeLanguage);
    } catch (e, s) {
      debugPrint('❌ GeminiService Generic Error: $e');
      debugPrint('❌ Stack trace: $s');
      return _buildFallback(message, learningLanguage, nativeLanguage);
    }
  }

  String _buildFallback(String message, String learningLanguage, String nativeLanguage) {
    return '''
I’m facing a temporary issue, so here’s a quick response in $learningLanguage:

${message.isEmpty ? 'Let’s keep practicing!' : message}

||
Sorry, I had trouble generating a full reply. Please ask again in $nativeLanguage for now.
''';
  }

  List<Content> _buildHistory(List<ChatMessage> messages) {
    final recentMessages =
        messages.length > 10 ? messages.sublist(messages.length - 10) : messages;

    return recentMessages.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      }
      return Content.model([TextPart(msg.content)]);
    }).toList();
  }
}