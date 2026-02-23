import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/chat_screen.dart';
import 'theme.dart';
import 'providers/settings_provider.dart';

class LinguaBotApp extends StatelessWidget {
  const LinguaBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The Consumer widget listens to changes in SettingsProvider.
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'LinguaBot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          // The home screen is determined by whether a learning language has been set.
          // This check is null-safe and follows the DreamFlow architecture.
          home: settings.learningLanguage != null
              ? const ChatScreen()
              : const LanguageSelectionScreen(),
          routes: {
            '/language_selection': (context) => const LanguageSelectionScreen(),
            '/chat': (context) => const ChatScreen(),
          },
        );
      },
    );
  }
}