import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../models/practice_mode.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/speech_to_text_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/recording_button.dart';
import 'language_selection_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _isVoiceInputMode = true;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _checkPermissions();
    
    // Use WidgetsBinding to safely interact with context after the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.messages.isEmpty) {
        _sendWelcomeMessage();
      }
      // Listen to message additions to scroll and play TTS.
      chatProvider.addListener(_onNewMessage);
    });
  }
  
  @override
  void dispose() {
    // Clean up listeners and controllers to prevent memory leaks.
    Provider.of<ChatProvider>(context, listen: false).removeListener(_onNewMessage);
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNewMessage() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _scrollToBottom();
    
    // Automatically play TTS for new AI messages.
    if (chatProvider.messages.isNotEmpty) {
      final lastMessage = chatProvider.messages.last;
      final ttsService = Provider.of<TextToSpeechService>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      if (lastMessage.role == MessageRole.assistant && (lastMessage.isError == false)) {
        // Check if the message content contains the separator.
        if (lastMessage.content.contains('|||')) {
          final parts = lastMessage.content.split('|||');
          final learningText = parts[0].trim();
          final nativeText = parts[1].trim();

          // Play the first part in the learning language.
          ttsService.speak(
            learningText,
            languageCode: settings.learningLanguage?.code,
          );

          // You might add a slight delay here before playing the explanation.
          Future.delayed(const Duration(seconds: 1), () {
            // Play the second part in the native language.
            ttsService.speak(
              nativeText,
              languageCode: settings.nativeLanguage?.code,
            );
          });

        } else {
          // If there's no separator, play the whole message in the learning language.
          ttsService.speak(
            lastMessage.content,
            languageCode: settings.learningLanguage?.code,
          );
        }
      } else if (lastMessage.isError == true) {
        // Play an audible error message so user notices the problem.
        // Use TTS fallback to read the error; replace with a short beep asset if available.
        ttsService.speak(
          'Sorry, an error occurred. ${lastMessage.content}',
          languageCode: settings.learningLanguage?.code,
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    if (!(await Permission.microphone.status).isGranted) {
      await Permission.microphone.request();
    }
  }

  void _sendWelcomeMessage() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final welcomeMessageContent = 'Welcome to your ${settings.learningLanguage?.name ?? "language"} ${settings.practiceMode.name} practice! Tap the mic to start.';
    
    chatProvider.addMessage(ChatMessage(
      content: welcomeMessageContent,
      role: MessageRole.assistant,
      isError: false,
    ));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // This is the core logic 
    chatProvider.sendMessage(
      userMessage: text,
      learningLanguage: settings.learningLanguage?.name ?? 'English',
      nativeLanguage: settings.nativeLanguage?.name ?? 'English',
      mode: settings.practiceMode.name,
    );
    
    if (!_isVoiceInputMode) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    Provider.of<ChatProvider>(context);
    Provider.of<SpeechToTextService>(context);
    Provider.of<TextToSpeechService>(context);

    return WillPopScope(
      onWillPop: () async {
        // Allow pop by default; you can show confirm dialog here if needed
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to language selection and replace current screen.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
              );
            },
          ),
          title: Text(settingsProvider.learningLanguage?.name ?? 'LinguaBot'),
          centerTitle: true,
          // 1. ADD THE BACK ARROW BUTTON HERE (The 'leading' widget)
        actions: [
          // NEW: Reset Conversation Button
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Reset Conversation',
            onPressed: () {
              // You should show a confirmation dialog here (recommended)
              // For a quick fix, call the provider method directly:
              Provider.of<ChatProvider>(context, listen: false).resetChat();
            },
          ),
    
          // EXISTING: Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() => _showSettings = !_showSettings);
              _showSettings ? _animationController.forward() : _animationController.reverse();
            },
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.settings),
            //     onPressed: () {
            //       setState(() => _showSettings = !_showSettings);
            //       _showSettings ? _animationController.forward() : _animationController.reverse();
             //   },
            ),
          ],
        ),
        body: Column(
          children: [
            // Animated settings panel
            SizeTransition(
              sizeFactor: _animationController,
              child: _buildSettingsPanel(context, settingsProvider),
            ),
            // Chat messages list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chat, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) => ChatMessageWidget(message: chat.messages[index]),
                  );
                },
              ),
            ),
            // Loading indicator
            Consumer<ChatProvider>(
              builder: (context, chat, child) {
                return chat.isLoading ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ) : const SizedBox.shrink();
              },
            ),
            // Input area
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  // Helper widget for the settings panel
  Widget _buildSettingsPanel(BuildContext context, SettingsProvider settings) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Practice Mode', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PracticeMode.values.map((mode) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(mode.displayName),
                    selected: settings.practiceMode == mode,
                    onSelected: (selected) {
                      if (selected) settings.setPracticeMode(mode);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the text/voice input area
  Widget _buildInputArea(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final speechService = Provider.of<SpeechToTextService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isVoiceInputMode ? Icons.keyboard : Icons.mic),
            onPressed: () => setState(() => _isVoiceInputMode = !_isVoiceInputMode),
          ),
          Expanded(
            child: _isVoiceInputMode
                ? RecordingButton(
                    speechToTextService: speechService,
                    onResult: _sendMessage,
                    languageCode: settings.learningLanguage?.code ?? 'en',
                  )
                : TextField(
                    controller: _textController,
                    decoration: const InputDecoration.collapsed(hintText: 'Type a message...'),
                    onSubmitted: _sendMessage,
                  ),
          ),
          if (!_isVoiceInputMode)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _sendMessage(_textController.text),
            ),
        ],
      ),
    );
  }
}