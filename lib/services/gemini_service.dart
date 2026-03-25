import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GeminiService {
  // Read the API key from the loaded .env file
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Corrected: Use the stable v1 endpoint with a supported free model
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

 String _getSystemPrompt(String learningLanguage, String nativeLanguage, String mode) {
  // We can add a topic variable later, for now, we'll focus on the mode.
  // Example: String? grammarTopic = "Tenses";

  return '''
You are an expert language tutor and conversation partner for $learningLanguage.
The user's native language is $nativeLanguage.
You are helping them practice $learningLanguage in a '$mode' session.
Your persona is encouraging, patient, and engaging.
Your responses are powered by Gemini Flash, so they should be fast, natural, and conversational.

---
### CORE RULES
1.  **PRIMARY LANGUAGE (Uninterrupted Flow):** The main conversational response and questions MUST ALWAYS be presented first and fully in $learningLanguage. This is the main focus of the user's reading.
2.  **DUAL-LANGUAGE SUPPORT (High Nativity):** After the main $learningLanguage response is complete, you MUST provide a natural, idiomatic $nativeLanguage translation/explanation of your reply. **Crucially, the $nativeLanguage translation must use highly natural, conversational, and idiomatic phrasing (like a native speaker talking to a friend) to achieve maximum nativity and flow.** This is placed in a clearly separated block for reference.
3.  **CORRECTION FLOW:** This is the most important rule.
    * When the user makes an error, DO NOT correct it immediately. Prioritize conversational flow.
    * Instead, gently ask in $learningLanguage if they would like a correction. (e.g., "That was a good sentence! I noticed a small detail. Would you like me to explain?" or "Great effort! Would you like a quick tip on that last part?").
    * **IF THEY SAY YES:** You will switch to the "Correction Format" (see below).
    * **IF THEY SAY NO:** Continue the conversation in $learningLanguage without making the correction.

---
### SESSION MODE RULES

**If the mode is 'conversation':**
* Focus on natural, flowing dialogue.
* Ask engaging questions about daily life, opinions, or culture.
* Prioritize fluency and confidence-building. Be less critical of minor errors.

**If the mode is 'vocabulary':**
* Subtly introduce 1-2 new, relevant words per interaction.
* Use the new word in a clear example sentence in $learningLanguage.
* Ask the user to try using the new word.
* If the user asks for pronunciation, provide a simple, **text-based phonetic guide in $nativeLanguage** that helps the user mimic the correct native 'accent' or sound.

**If the mode is 'grammar':**
* Focus the conversation on exercises that target a specific grammar rule.
* (Optional: If a grammarTopic is provided, like 'Tenses', focus all examples and corrections on that topic).
* When the user agrees to a correction, your explanation MUST be in-depth and detailed.

---
### RESPONSE FORMATTING (STRICTLY FOLLOW)

**1. Standard Conversation Format (Use for ALL regular replies):**
You MUST use this exact multi-line format with the "|||" separator, ensuring the $learningLanguage text is fully presented first.

[Your full, conversational response in $learningLanguage]
|||
[Your highly natural, conversational, and idiomatic translation/explanation of the above in $nativeLanguage]

**2. Correction Format (IMPORTANT: Use *only* after the user agrees to be corrected):**
You MUST use this exact multi-line format with the "|||" separator.
CORRECTION_START
[The corrected version of the user's sentence/phrase in $learningLanguage]
|||
[A detailed, in-depth explanation of the grammar/vocabulary rule in $nativeLanguage. **Ensure the tone is highly native, friendly, and conversational, using real-world analogies or context.**]
|||
[Two or three correct example sentences in $learningLanguage]
|||
[A follow-up question in $learningLanguage to seamlessly restart the conversation]
CORRECTION_END
''';
}

  Future<String> generateResponse({
    required List<ChatMessage> history,
    required String message,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
  }) async {
    // Security check for API key
    if (_apiKey.isEmpty) {
      debugPrint('❌ Gemini API Error: API key is missing in .env file.');
      return _buildFallback(message, learningLanguage, nativeLanguage);
    }
    
    try {
      debugPrint('🔵 Attempting Gemini call with model: gemini-1.5-flash');
      debugPrint('🔵 Message: $message');

      // Corrected: Build a structured history for the v1 API
      final List<Map<String, dynamic>> contents = [
        {
          'role': 'model',
          'parts': [
            {'text': _getSystemPrompt(learningLanguage, nativeLanguage, mode)}
          ],
        },
      ];

      final historyToInclude =
          history.length <= 10 ? history : history.sublist(history.length - 10);

      for (final msg in historyToInclude) {
        contents.add({
          'role': msg.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': msg.content}
          ],
        });
      }

      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {'key': _apiKey});
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
            'topP': 0.8,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Check for valid candidates first
        final candidates = responseData['candidates'];
        if (candidates != null && candidates is List && candidates.isNotEmpty) {
          final text = candidates[0]['content']?['parts']?[0]?['text'];
          if (text != null) {
            debugPrint('✅ Gemini response received successfully');
            return text;
          }
        }
        
        // If no valid candidates, check for a block reason
        final promptFeedback = responseData['promptFeedback'];
        if (promptFeedback != null && promptFeedback is Map) {
          final blockReason = promptFeedback['blockReason'];
          if (blockReason != null) {
            debugPrint('❌ Gemini API Blocked: $blockReason');
            return _buildFallback(message, learningLanguage, nativeLanguage, error: 'Response was blocked for safety reasons.');
          }
        }
        
        // If neither, throw a generic error
        throw Exception('Empty or invalid response from Gemini API');

      } else if (response.statusCode == 429) {
        debugPrint('❌ Gemini API HTTP Error: 429 Too Many Requests');
        debugPrint('❌ Details: ${response.body}');
        return _buildFallback(
          message,
          learningLanguage,
          nativeLanguage,
          error: 'You have reached the Gemini API rate limit. Please wait and try again later.',
        );
      } else if (response.statusCode == 503) {
        debugPrint('❌ Gemini API HTTP Error: 503 Service Unavailable');
        debugPrint('❌ Details: ${response.body}');
        return _buildFallback(
          message,
          learningLanguage,
          nativeLanguage,
          error: 'The AI service is temporarily overloaded. Please try again in a moment.',
        );
      } else {
        debugPrint('❌ Gemini API HTTP Error: ${response.statusCode} ${response.body}');
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e, s) {
      debugPrint('❌ GeminiService Error: $e');
      debugPrint('❌ Stack trace: $s');
      return _buildFallback(message, learningLanguage, nativeLanguage);
    }
  }

  Stream<String> sendMessageStream({
    required List<ChatMessage> history,
    required String message,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
  }) async* {
    if (_apiKey.isEmpty) {
      yield "API key missing.";
      return;
    }

    final List<Map<String, dynamic>> contents = [
      {
        'role': 'model',
        'parts': [
          {'text': _getSystemPrompt(learningLanguage, nativeLanguage, mode)}
        ],
      },
    ];

    final historyToInclude =
        history.length <= 10 ? history : history.sublist(history.length - 10);

    for (final msg in historyToInclude) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': message}
      ],
    });

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'key': _apiKey});
    final requestBody = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
        'topP': 0.8,
        'topK': 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = requestBody;

    final response = await request.send();

    if (response.statusCode == 200) {
      await for (var line in response.stream.transform(utf8.decoder).transform(LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        } catch (_) {
          // Ignore lines that can't be parsed
        }
      }
    } else {
      if (response.statusCode == 503) {
        yield "Error: The AI service is temporarily overloaded. Please try again in a moment.";
      } else {
        yield "Error: ${response.statusCode}";
      }
    }
  }

  String _buildFallback(String message, String learningLanguage, String nativeLanguage, {String? error}) {
    final explanation = error ?? "Sorry, I had trouble generating a full reply. Please ask again in $nativeLanguage for now.";
    return '''
I'm facing a temporary issue, so here's a quick response in $learningLanguage:

${message.isEmpty ? "Let's keep practicing!" : message}

|||
$explanation
''';
  }
}