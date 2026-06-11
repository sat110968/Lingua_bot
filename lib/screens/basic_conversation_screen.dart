import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/practice_mode.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/text_to_speech_service.dart';
import '../theme.dart';
import '../widgets/chat_message_widget.dart';
import 'mode_selection_screen.dart';

/// Basic Conversation Screen - 25 Words Per Day Vocabulary Practice
class BasicConversationScreen extends StatefulWidget {
  const BasicConversationScreen({super.key});

  @override
  State<BasicConversationScreen> createState() => _BasicConversationScreenState();
}

class _BasicConversationScreenState extends State<BasicConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _sendInitialMessage(settings);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendInitialMessage(SettingsProvider settings) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final welcomeMessage =
        'Start your daily 25-word vocabulary practice! I will teach you new words with examples and pronunciation. Ready to learn?';

    chatProvider.addMessage(
      ChatMessage(
        content: welcomeMessage,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );

    // Auto play welcome message
    final ttsService = Provider.of<TextToSpeechService>(context, listen: false);
    ttsService.speak(welcomeMessage, languageCode: 'en-IN');
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) return;

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
      // Send to backend with explicit mode
      await chatProvider.sendMessage(
        userMessage: message,
        mode: 'basic_conversation', // EXPLICIT MODE
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
            languageCode: settings.learningLanguage?.code ?? 'en-IN',
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
        title: const Text('📚 Basic Conversation - 25 Words Practice'),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${settings.learningLanguage?.name ?? "English"} ← ${settings.nativeLanguage?.name ?? "Hindi"}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
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
                Expanded(
                  child: Text(
                    'Learn 3-5 new words daily with pronunciation, examples, and practice.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
                    enabled: !_isLoading,
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
                    onSubmitted: _isLoading ? null : _sendMessage,
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
                  onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
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
