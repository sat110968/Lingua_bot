import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../services/text_to_speech_service.dart';
import '../theme.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxMessageWidth = screenWidth * 0.75;

    // Use a Consumer to listen for changes in the TextToSpeechService.
    return Consumer<TextToSpeechService>(
      builder: (context, ttsService, child) {
        // Determine if this specific message is currently playing.
        final isPlaying = ttsService.currentlyPlayingMessageId == message.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(context),
              
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxMessageWidth),
                child: Container(
                  margin: EdgeInsets.only(
                    left: isUser ? 16 : 8,
                    right: isUser ? 8 : 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    // FIX: Use AppColors for static colors.
                    color: isUser
                        ? AppColors.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isUser 
                                  ? Colors.white.withOpacity(0.7) 
                                  // FIX: Use AppColors for static colors.
                                  : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          
                          // Play button logic is now self-contained within the widget.
                          if (!isUser) ...
                          [
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final settings = Provider.of<SettingsProvider>(context, listen: false);
                                if (isPlaying) {
                                  ttsService.stop();
                                } else {
                                  ttsService.speak(
                                    message.content,
                                    messageId: message.id,
                                    languageCode: settings.learningLanguage?.code,
                                  );
                                }
                              },
                              child: Icon(
                                isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                size: 18,
                                // FIX: Use AppColors for static colors.
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (isUser) _buildAvatar(context, isUser: true),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
    // FIX: Access the theme extension correctly via the context.
    final appThemeExtension = Theme.of(context).extension<AppTheme>();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // FIX: Use the gradient from the theme extension.
        gradient: isUser 
            ? null 
            : appThemeExtension?.primaryGradient,
        // FIX: Use AppColors for static colors.
        color: isUser ? AppColors.textMuted.withOpacity(0.2) : null,
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.school,
          // FIX: Use AppColors for static colors.
          color: isUser ? AppColors.textMuted : Colors.white,
          size: 18,
        ),
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    String hourFormat = timestamp.hour.toString().padLeft(2, '0');
    String minuteFormat = timestamp.minute.toString().padLeft(2, '0');

    if (messageDate == today) {
      return '$hourFormat:$minuteFormat';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $hourFormat:$minuteFormat';
    } else {
      return '${timestamp.day}/${timestamp.month} $hourFormat:$minuteFormat';
    }
  }
}