import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cached_response.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._geminiService);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages');
      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        _messages = decoded.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      _error = 'Failed to load messages: $e';
    }
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('chat_messages', messagesJson);
  }

  Future<String?> fetchCurriculumData(String mode, String learningLanguage) async {
    if (mode != 'Simple English' && mode != 'Vocabulary') return null;
    try {
      // Assume Supabase is loaded from main.dart. 
      // The catch block below will cleanly handle cases where tables don't exist yet.
      
      // We grab 20 words sequentially per day.
      // Replace '0' here with a sharedPreferences value tracking the user's progress for a real app!
      int userWordProgressIndex = 0; 
      int wordsPerDayMap = 20; 

      final res = await Supabase.instance.client
          .from('vocabulary_words')
          .select('word, native_meaning, example_sentence')
          .eq('learning_language', learningLanguage)
          .eq('course_identifier', 'global_english_hindi')
          .range(userWordProgressIndex, userWordProgressIndex + wordsPerDayMap - 1); 
          
      if (res != null && res is List && res.isNotEmpty) {
        String curriculum = "WORDS FOR TODAY:\n";
        for (var row in res) {
           curriculum += "- ${row['word']} (Meaning: ${row['native_meaning']}). Example: ${row['example_sentence']}\n";
        }
        return curriculum;
      }
    } catch (e) {
      if (kDebugMode) print('Curriculum fetch skipped or error (ensure tables exist in Supabase): $e');
    }
    return null;
  }

  Future<void> sendMessage({
    required String userMessage,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
    required String speechLanguage,
    String? audioPath,
  }) async {
    // 1. Add the user's message ONCE.
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: userMessage,
      timestamp: DateTime.now(),
      audioPath: audioPath,
      isError: false,
    ));
    _isLoading = true;
    notifyListeners();
    await _saveMessages();

    try {
      String responseText = '';
      bool usedCache = false;

      // 2. Try to fetch from Supabase cache
      final embedding = await _geminiService.generateEmbedding(userMessage);
      
      if (embedding != null) {
        try {
          // Wrap in try-catch in case Supabase is not configured yet
          final res = await Supabase.instance.client.rpc(
            'match_cached_responses',
            params: {
              'query_embedding': embedding,
              'match_threshold': 0.95,
              'match_count': 1,
              'p_learning_language': learningLanguage,
              'p_native_language': nativeLanguage,
              'p_practice_mode': mode,
            },
          );

          if (res != null && res is List && res.isNotEmpty) {
            final cached = CachedResponse.fromJson(res.first);
            responseText = cached.aiResponse;
            usedCache = true;
            if (kDebugMode) print('🔥 Cache hit! Similarity: ${cached.similarity}');
          }
        } catch (e) {
          if (kDebugMode) print('Supabase cache read skipped or error: $e');
        }
      }

      // Fetch today's curriculum directly from the Supabase database
      final curriculumData = await fetchCurriculumData(mode, learningLanguage);
      
      // 3. If no cache hit, get AI response
      if (!usedCache) {
        responseText = await _geminiService.generateResponse(
          history: _messages,
          message: userMessage,
          learningLanguage: learningLanguage,
          nativeLanguage: nativeLanguage,
          mode: mode,
          curriculumData: curriculumData,
          speechLanguage: speechLanguage,
        );

        // 4. Save new response to Supabase cache asynchronously
        if (embedding != null) {
          try {
            Supabase.instance.client.from('ai_responses_cache').insert({
              'user_query': userMessage,
              'ai_response': responseText,
              'learning_language': learningLanguage,
              'native_language': nativeLanguage,
              'practice_mode': mode,
              'embedding': embedding,
            }).then((_) {
               if (kDebugMode) print('💾 Saved to Supabase cache!');
            }).catchError((e) {
               if (kDebugMode) print('Supabase write error: $e');
            });
          } catch (e) {
            // ignore if not configured
          }
        }
      }

      // 5. Add the AI's message.
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: responseText,
        timestamp: DateTime.now(),
        isError: false,
      ));
    } catch (e) {
      // 4. Add an error message if something goes wrong.
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: "Sorry, I couldn't process that. Please try again.",
        timestamp: DateTime.now(),
        isError: true,
      ));
      _error = 'AI Error: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      await _saveMessages();
    }
  }

  Future<void> sendMessageWithStream({
    required String userMessage,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
  }) async {
    final chatHistory = _messages;
    final stream = _geminiService.sendMessageStream(
      history: chatHistory,
      message: userMessage,
      learningLanguage: learningLanguage,
      nativeLanguage: nativeLanguage,
      mode: mode,
    );

    String partialResponse = '';
    await for (final partialText in stream) {
      partialResponse += partialText;
      // Optionally, update a temporary message in your UI here
      // e.g., set a "streaming" message and call notifyListeners()
    }

    // After streaming completes, add the full response as a ChatMessage
    _messages.add(ChatMessage(
      role: MessageRole.assistant, // <-- Corrected from MessageRole.model
      content: partialResponse,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Public helper to add a message (used by ChatScreen for welcome/system messages)
  Future<void> addMessage(ChatMessage message) async {
    _messages.add(message);
    notifyListeners();
    await _saveMessages();
  }

  /// Clears the chat history and resets the conversation.
  Future<void> resetChat() async {
    _messages.clear();
    notifyListeners();
    // Optionally, save the cleared state to SharedPreferences
    await _saveMessages();
    // You could also add a new welcome message here if desired.
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}