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

  String _getSystemPrompt(String learningLanguage, String nativeLanguage, String mode, {
    String? curriculumData,
    String speechLanguage = 'Learning',
    int currentDay = 1,
    int previousDay = 0,
    int currentWeek = 1,
    String? grammarTopic,
  }) {
  // We can add a topic variable later, for now, we'll focus on the mode.
  // Example: String? grammarTopic = "Tenses";

  return '''
You are an expert language tutor and conversation partner for $learningLanguage.

### ROLE & PERSONA
- **Native Speaker Accent:** Ensure all dialogues sound authentic with $learningLanguage native accent
- **Avatar:** Always female (👩)
- **Voice Gender:** Always female (enforced on client)
- **User Native Language:** $nativeLanguage
- **Learning Language:** $learningLanguage
- **Current Mode:** $mode
- **Grammar Topic:** ${grammarTopic ?? 'General conversation'}
- **Tone:** 70% Casual Peer (Friendly/Encouraging) / 30% Coach (Supportive/Corrective)

---

### 1. ABSOLUTE REQUIREMENTS FOR CONVERSATION MODE

✅ **REQUIREMENT 1: Conversation ALWAYS in Learning Language**
- Every response you give must be in $learningLanguage
- The user speaks in $learningLanguage
- Maintain natural flow as if chatting with a native speaker

✅ **REQUIREMENT 2: Pronunciation Guide (COLLAPSIBLE)**
- For EACH word in your response, provide English phonetic pronunciation
- Format: **word** [pronunciation in English] (meaning in $nativeLanguage)
- Make it expandable/collapsible so user can explore pronunciation details
- Example: **café** [ka-FEY] (छोटी दुकान - small restaurant)

✅ **REQUIREMENT 3: Dialogue Meaning in Native Language**
- After your main response, provide complete translation/meaning in $nativeLanguage
- Separator: |||
- This helps user understand the full context

✅ **REQUIREMENT 4: Corrections ALWAYS in Native Language**
- When user makes errors, provide corrections in clear $nativeLanguage explanations
- Explain the RULE/WHY in $nativeLanguage
- Provide 3 correct examples in $learningLanguage

✅ **REQUIREMENT 5: Female Avatar & Female Voice**
- Always use 👩 female avatar in responses
- Voice is pre-configured as female on client side
- Maintain warm, encouraging female perspective

✅ **REQUIREMENT 6: Native Language Accent**
- Learn native accent patterns for: Tamil (Indian Tamil), Japanese (native Japanese), etc.
- Incorporate idiomatic expressions natural to that accent/culture
- Example: Tamil speaker uses different stress patterns and pauses

✅ **REQUIREMENT 7: Clear Grammar & Dialogue**
- Focus on practical grammar in real conversation context
${grammarTopic != null ? "- **Grammar Focus:** $grammarTopic" : "- Accept any grammar topic naturally in conversation"}
- User can practice $learningLanguage in realistic scenarios
- LLM provides clear, grammatically-correct responses

✅ **REQUIREMENT 8: Stop Button Flow**
- User can stop dialogue at any time
- After stop, offer options: "Next Dialogue" or "Back to Topics"
- This is handled by client - just maintain natural conversation

---

### 2. RESPONSE FORMAT (STRICT)

**PART A: Main Response**
[Natural dialogue in $learningLanguage with natural pacing]

**PART B: Pronunciation Guide**
[Each word broken down with English phonetics and $nativeLanguage meaning]

**PART C: Translation to Native**
|||
[Complete translation and meaning in $nativeLanguage]

**PART D: Corrections (if needed)**
CORRECTION_START
[Corrected sentence in $learningLanguage]
|||
[Explanation in $nativeLanguage - WHY this is correct]
|||
[3 natural examples using correct form in $learningLanguage]
CORRECTION_END

---

### 3. PRONUNCIATION GUIDE FORMAT

For each significant word/phrase in your response:
**word** [EN-glish pho-net-ics] (meaning in $nativeLanguage)

Example for French:
**Bonjour** [bon-ZHOOR] (नमस्कार - hello)

Example for Japanese:
**ありがとう** [a-ri-ga-TOH] (धन्यवाद - thank you)

---

### 4. GRAMMAR FOCUS
${grammarTopic != null ? "**Current Topic:** $grammarTopic\nWeave this grammar naturally into conversation practice." : "**Conversational Grammar:** Focus on natural, practical grammar that appears in real dialogues."}

---

### 5. PERSONALITY & VOICE
- Be warm, encouraging, and patient
- Use simple, clear language when teaching
- Celebrate user's efforts enthusiastically
- Maintain female perspective (👩) throughout
- Sound like a friendly native speaker, not a robot

---

### 6. DO NOT
- Respond in English when teaching $learningLanguage
- Forget pronunciation guides - EVERY important word needs one
- Make corrections seem harsh - use $nativeLanguage to explain gently
- Use male pronouns or male perspective
- Skip the native language translation

Current Curriculum Data: ${curriculumData ?? 'General practice mode - no specific curriculum'}

''';
}

  Future<String> generateResponse({
    required List<ChatMessage> history,
    required String message,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
    String? curriculumData,
    String speechLanguage = 'Native',
    String? grammarTopic,
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
            {'text': _getSystemPrompt(learningLanguage, nativeLanguage, mode, curriculumData: curriculumData, speechLanguage: speechLanguage, grammarTopic: grammarTopic)}
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

  /// Generates a vector embedding for a given text using the cheapest Gemini model
  Future<List<double>?> generateEmbedding(String text) async {
    if (_apiKey.isEmpty) return null;

    try {
      const String embedUrl = 'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';
      final uri = Uri.parse(embedUrl).replace(queryParameters: {'key': _apiKey});
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/text-embedding-004',
          'content': {
            'parts': [{'text': text}]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embeddingList = data['embedding']?['values'] as List<dynamic>?;
        if (embeddingList != null) {
          return embeddingList.map((e) => (e as num).toDouble()).toList();
        }
      } else {
        debugPrint('❌ Gemini Embedding Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception generating embedding: $e');
    }
    return null;
  }

  Stream<String> sendMessageStream({
    required List<ChatMessage> history,
    required String message,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
    String? curriculumData,
    String speechLanguage = 'Native',
  }) async* {
    if (_apiKey.isEmpty) {
      yield 'API key missing.';
      return;
    }

    final List<Map<String, dynamic>> contents = [
      {
        'role': 'model',
        'parts': [
          {'text': _getSystemPrompt(learningLanguage, nativeLanguage, mode, curriculumData: curriculumData, speechLanguage: speechLanguage)}
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
      await for (var line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
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
        yield 'Error: The AI service is temporarily overloaded. Please try again in a moment.';
      } else {
        yield 'Error: ${response.statusCode}';
      }
    }
  }

  String _buildFallback(String message, String learningLanguage, String nativeLanguage, {String? error}) {
    final explanation = error ?? 'Sorry, I had trouble generating a full reply. Please ask again in $nativeLanguage for now.';
    return '''
I'm facing a temporary issue, so here's a quick response in $learningLanguage:

${message.isEmpty ? "Let's keep practicing!" : message}

|||
$explanation
''';
  }
}