# LinguaBot AI Coding Instructions

## Project Overview
Flutter-based AI language learning app with voice-enabled conversation practice. Uses **Google Gemini 1.5 Flash** (free) for AI tutoring, Provider for state management, and SharedPreferences for persistence.

## Architecture Essentials

### State Management Pattern
Uses Provider with two main providers accessed via `Provider.of<T>(context, listen: false)`:
- **SettingsProvider**: Persists `learningLanguage`, `nativeLanguage`, `practiceMode`
- **ChatProvider**: Manages message history, sends to Gemini, auto-saves to SharedPreferences

Always call `notifyListeners()` after state mutations.

### Service Layer
Services are initialized in `main.dart` and injected via MultiProvider:
```dart
Provider<SpeechToTextService>.value(value: speechToTextService)
ChangeNotifierProvider.value(value: textToSpeechService)
```

### Dual-Language Response Format
**Critical Pattern**: Gemini responses use `|||` separator for bilingual output:
```
[Learning language response]
|||
[Native language translation/explanation]
```

Parsing happens in [chat_screen.dart](lib/screens/chat_screen.dart#L71-L90) for TTS playback. Always preserve this format when modifying AI prompts in [gemini_service.dart](lib/services/gemini_service.dart#L16-L77).

## Key Workflows

### Building & Running
**Use PowerShell script** for clean builds: `.\build.ps1`
- Runs `flutter clean`, removes `.dart_tool`, `.gradle`, reinstalls deps
- Builds release APK with `--no-tree-shake-icons` flag
- Output: `build/app/outputs/flutter-apk/app-release.apk`

For quick runs: `flutter run` (requires connected device/emulator)

### Environment Setup
1. Create `.env` file in project root (gitignored)
2. Add: `GEMINI_API_KEY=your_key_here`
3. Get free key: https://aistudio.google.com/app/apikey
4. Loaded in [main.dart](lib/main.dart#L18) via `flutter_dotenv`

### Message Flow
1. User input (text/voice) → [chat_screen.dart](lib/screens/chat_screen.dart#L142-L155)
2. `ChatProvider.sendMessage()` → adds user message, sets `isLoading=true`
3. `GeminiService.generateResponse()` → builds conversation history (last 10 msgs) + system prompt
4. API response parsed → assistant message added → `notifyListeners()` → auto-save
5. TTS auto-plays both language parts sequentially

## Project-Specific Conventions

### Practice Mode Context
System prompts in `GeminiService._getSystemPrompt()` include mode-specific rules:
- **conversation**: Natural dialogue, avoid immediate corrections
- **vocabulary**: Introduce 1-2 new words per interaction
- **grammar**: Deep explanations when user accepts corrections

Mode affects prompt engineering, not UI behavior.

### Voice Recording
[audio_recorder.dart](lib/audio_recorder.dart) uses `record` package:
- Mobile: saves to app documents dir as `.m4a` files
- Web: returns blob URL (playback not fully implemented)
- File paths stored in `ChatMessage.audioPath` for replay

### Theme System
**Always use AppColors for static colors**, not `Theme.of(context).colorScheme`:
```dart
AppColors.primary  // Deep Purple
AppColors.secondary  // Cyan
AppColors.textMuted  // Gray for timestamps
```

Custom gradients in `AppTheme` extension ([theme.dart](lib/theme.dart#L22-L28)).

### Error Handling Pattern
Services catch exceptions → return fallback text or throw → Provider catches → adds message with `isError: true` → UI shows in chat + TTS reads error.

See [gemini_service.dart](lib/services/gemini_service.dart#L88-L91) for API key validation and fallback generation.

## Common Pitfalls

1. **Don't modify `|||` separator logic** without updating both prompt formatting and parsing in chat_screen
2. **Context window limits**: History capped at 10 messages ([gemini_service.dart](lib/services/gemini_service.dart#L107-L108))
3. **Avoid blocking UI**: All API calls use async/await with loading states
4. **SharedPreferences**: All settings/messages auto-save; no manual save buttons
5. **Navigation flow**: App shows ChatScreen if `learningLanguage != null`, else LanguageSelectionScreen ([app.dart](lib/app.dart#L20-L22))

## Key Files Reference
- [lib/services/gemini_service.dart](lib/services/gemini_service.dart): AI prompt engineering, API integration
- [lib/providers/chat_provider.dart](lib/providers/chat_provider.dart): Message state, persistence logic
- [lib/screens/chat_screen.dart](lib/screens/chat_screen.dart): Message rendering, TTS orchestration
- [lib/theme.dart](lib/theme.dart): Complete visual design system with AppColors
- [build.ps1](build.ps1): Production build automation

When extending the app, preserve the dual-language format, maintain Provider patterns, and ensure all state changes trigger persistence.