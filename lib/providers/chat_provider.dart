import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Adds a user message to the chat and triggers the AI response flow.
  Future<void> sendMessage({
    required String userMessage,
    required String learningLanguage,
    required String nativeLanguage,
    required String mode,
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

    // 2. Get the AI response.
    try {
      final response = await _geminiService.generateResponse(
        history: _messages,
        message: userMessage,
        learningLanguage: learningLanguage,
        nativeLanguage: nativeLanguage,
        mode: mode,
      );

      // 3. Add the AI's message.
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: response,
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