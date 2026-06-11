import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/text_to_speech_service.dart';
import '../theme.dart';
import '../widgets/chat_message_widget.dart';
import 'mode_selection_screen.dart';

/// Practical Conversation Screen - Real-World Natural Dialogues
class PracticalConversationScreen extends StatefulWidget {
  const PracticalConversationScreen({super.key});

  @override
  State<PracticalConversationScreen> createState() => _PracticalConversationScreenState();
}

class _PracticalConversationScreenState extends State<PracticalConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTopicSelection();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showTopicSelection() {
    final topics = [
      '🏨 Hotel Booking',
      '🍽️ Restaurant Ordering',
      '✈️ Travel & Directions',
      '💼 Job Interview',
      '🛍️ Shopping',
      '🏥 Doctor Visit',
      '🎬 Entertainment & Hobbies',
      '💬 Casual Chat',
      '📚 School & Education',
      '💰 Banking & Finances',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose a Conversation Topic'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: topics
                .map(
                  (topic) => ListTile(
                    title: Text(topic),
                    onTap: () {
                      setState(() => _selectedTopic = topic);
                      Navigator.pop(context);
                      _startConversation(topic);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _startConversation(String topic) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final ttsService = Provider.of<TextToSpeechService>(context, listen: false);

    final welcomeMessage =
        'Great! Let\'s have a conversation about $topic. I\'m here to help you practice real-world English. Go ahead, start the conversation!';

    chatProvider.addMessage(
      ChatMessage(
        content: welcomeMessage,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );

    // Auto play welcome message
    ttsService.speak(welcomeMessage, languageCode: 'en-IN');
  }

  void _sendMessage(String message) async {
    if (message.isEmpty || _selectedTopic == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final ttsService = Provider.of<TextToSpeechService>(context, listen: false);

    // Add user message
    chatProvider.addMessage(
      ChatMessage(
        content: message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    );

    _textController.clear();
    _scrollToBottom();

    setState(() => _isLoading = true);

    try {
      // Send to backend with explicit mode and topic
      await chatProvider.sendMessage(
        userMessage: message,
        mode: 'practical_conversation', // EXPLICIT MODE
        learningLanguage: settings.learningLanguage?.code ?? 'en',
        nativeLanguage: settings.nativeLanguage?.code ?? 'hi',
        speechLanguage: settings.learningLanguage?.code ?? 'en',
      );

      _scrollToBottom();

      // Play TTS for response
      if (chatProvider.messages.isNotEmpty) {
        final lastMessage = chatProvider.messages.last;
        if (lastMessage.role == MessageRole.assistant) {
          await ttsService.speak(
            lastMessage.content,
            languageCode: settings.learningLanguage?.code ?? 'en',
          );
        }
      }
    } catch (e) {
      chatProvider.addMessage(
        ChatMessage(
          content: 'Error: ${e.toString()}',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('💬 Practical Conversation${_selectedTopic != null ? ' - $_selectedTopic' : ''}'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${settings.learningLanguage?.name ?? "English"} ← ${settings.nativeLanguage?.name ?? "Hindi"}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Have a natural conversation. I\'ll correct any errors gently.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageWidget(
                      message: chatProvider.messages[index],
                    );
                  },
                );
              },
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isLoading && _selectedTopic != null,
                    decoration: InputDecoration(
                      hintText: 'Type your response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _isLoading || _selectedTopic == null ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading || _selectedTopic == null ? null : () => _sendMessage(_textController.text),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
