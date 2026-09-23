import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/text_to_speech_service.dart';
import '../theme.dart';
import '../widgets/chat_message_widget.dart';
import 'grammar_selection_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String? grammarTopic;

  const ConversationScreen({super.key, this.grammarTopic});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _dialogueActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startDialogue();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startDialogue() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final ttsService = Provider.of<TextToSpeechService>(context, listen: false);

    final languageName = settings.learningLanguage?.name ?? 'Language';
    final topicDisplay = widget.grammarTopic != null ? ' - ${widget.grammarTopic}' : '';

    final welcomeMessage =
        'Let\'s practice $languageName conversation$topicDisplay. I\'ll provide pronunciation for each word with collapsible details. Ready? Start speaking!';

    chatProvider.addMessage(
      ChatMessage(
        content: welcomeMessage,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );

    setState(() => _dialogueActive = true);
    ttsService.speak(welcomeMessage, languageCode: settings.learningLanguage?.code ?? 'en');
  }

  void _sendMessage(String message) async {
    if (message.isEmpty || !_dialogueActive) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final ttsService = Provider.of<TextToSpeechService>(context, listen: false);

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
      await chatProvider.sendMessage(
        userMessage: message,
        mode: 'conversation',
        learningLanguage: settings.learningLanguage?.code ?? 'en',
        nativeLanguage: settings.nativeLanguage?.code ?? 'hi',
        speechLanguage: settings.learningLanguage?.code ?? 'en',
        grammarTopic: widget.grammarTopic,
      );

      _scrollToBottom();

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

  void _stopDialogue() {
    setState(() => _dialogueActive = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dialogue Stopped'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewDialogue();
            },
            child: const Text('Next Dialogue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GrammarSelectionScreen()),
              );
            },
            child: const Text('Back to Topics'),
          ),
        ],
      ),
    );
  }

  void _startNewDialogue() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.resetChat();
    _startDialogue();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '💬 ${settings.learningLanguage?.name ?? "Language"}${widget.grammarTopic != null ? ' - ${widget.grammarTopic}' : ''}',
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GrammarSelectionScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '👩 ${settings.learningLanguage?.name ?? "English"}',
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
                Expanded(
                  child: Text(
                    'Speak naturally. I\'ll provide pronunciation and corrections in your native language.',
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
          // Input Area with Stop Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !_isLoading && _dialogueActive,
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
                        onSubmitted: _isLoading || !_dialogueActive ? null : _sendMessage,
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
                      onPressed: _isLoading || !_dialogueActive ? null : () => _sendMessage(_textController.text),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stop Button
                if (_dialogueActive)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _stopDialogue,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop Dialogue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
