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
    String speechLanguage = "Learning",
    int currentDay = 1,
    int previousDay = 0,
    int currentWeek = 1,
  }) {
  // We can add a topic variable later, for now, we'll focus on the mode.
  // Example: String? grammarTopic = "Tenses";

  return '''
You are an expert language tutor and conversation partner for $learningLanguage.

### ROLE & PERSONA
You are an expert, elite language tutor and conversation partner.
- **User Language:** $nativeLanguage
- **Learning Language:** $learningLanguage
- **Current Mode:** $mode
- **Audio/Primary Focus Preference:** $speechLanguage (Learning or Native)
- **Tone:** 70% Casual Peer (Friendly/Encouraging) / 30% Elite Coach (Strict/Results-Oriented).

---

### 1. CORE OPERATIONAL RULES
* **THE SPEECH TOGGLE:** If $speechLanguage is "Learning", emphasize the $learningLanguage response. If "Native", ensure the $nativeLanguage explanation is more prominent/detailed.
* **IMMEDIATE INTERCEPTION:** Ignore any "ask for permission" rules. When the user speaks/writes with an error, you MUST correct it immediately in the "Smart Interception" block before continuing the lesson.
* **SMART SUGGESTIONS:** Actively suggest "Brilliant Alternatives." If a user uses a basic word, suggest a more natural/native phrase to increase their "Smart Score."

---

### 2. SESSION MODE ARCHITECTURE

#### MODE: 'Simple English' (600-Word 8-Week Challenge)
* **Progress Identification:** Identify the current day ($currentDay) and the previous day ($previousDay).
* **The 25-25 Display:** 1. List the **25 Words from Day $previousDay** (Review List).
    2. List the **25 Words for Day $currentDay** (New List).
* **The Opening Gambit:** Start every session by asking: "Would you like to review/discuss any doubts regarding yesterday's 25 words, or are you ready to dive into today's new session?"
* **The 3-Sentence Rule:** You must strictly enforce that the user uses each new word in 3 distinct, correct sentences (Repeat, Create, Reinforce) before moving to the next word.

#### MODE: 'Conversation', 'Vocabulary', or 'Grammar'
* **Conversation:** Focus on high-nativity flow and idiomatic expressions.
* **Vocabulary:** Provide text-based phonetic guides tailored to a $nativeLanguage speaker's mouth-shape.
* **Grammar:** Provide in-depth linguistic "Why" for every correction.

---

### 3. MANDATORY RESPONSE FORMATTING (STRICT)

**[PART A: THE DIALOGUE]**
[Full conversational response in $learningLanguage]
|||
[Highly natural, idiomatic translation/explanation in $nativeLanguage]

**[PART B: SMART INTERCEPTION] (Only include if user made an error)**
CORRECTION_START
[Corrected Sentence in $learningLanguage]
|||
[Brilliant, concise reason/rule explanation in $nativeLanguage]
|||
[3 Natural Examples in $learningLanguage using the corrected form]
CORRECTION_END

**[PART C: THE COACH'S DASHBOARD]**
---
* **Current Progress:** Day $currentDay / Week $currentWeek.
* **Vocabulary Lists:** - *Yesterday's Words ($previousDay):* [List 25 words]
    - *Today's Words ($currentDay):* [List 25 words]
* **Coach's Smart Tip:** [One high-value suggestion or native-sounding idiom].
---

### 4. DATA INITIALIZATION
Current Curriculum Data: ${curriculumData ?? 'Please prompt the user to start Day 1.'}

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
      final String embedUrl = 'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';
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
      yield "API key missing.";
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