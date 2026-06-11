import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/chat_provider.dart';
import 'services/gemini_service.dart';
import 'services/speech_to_text_service.dart';
import 'services/text_to_speech_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  // Ensure widgets are initialized before loading env
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize services
  final geminiService = GeminiService();
  final speechToTextService = SpeechToTextService();
  final textToSpeechService = TextToSpeechService();
  
  // Create and initialize SettingsProvider
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  await speechToTextService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(geminiService),
        ),
        ChangeNotifierProvider<SpeechToTextService>.value(value: speechToTextService),
        ChangeNotifierProvider.value(value: textToSpeechService),
      ],
      // Use the imported app class which handles themes and routing
      child: const LinguaBotApp(),
    ),
  );
}