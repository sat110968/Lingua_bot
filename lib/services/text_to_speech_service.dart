import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String _currentLanguageCode = 'en-US';
  String? _currentlyPlayingMessageId;
  double _speechRate = 0.95; // Increased greatly because Chrome Web interprets 0.5 as half-speed.
  double _pitch = 1.0; // Range: 0.5 to 2.0

  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingMessageId => _currentlyPlayingMessageId;
  
  TextToSpeechService() {
    _initTts();
  }

  // Initialize text-to-speech engine
  Future<void> _initTts() async {
    try {
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        notifyListeners(); // Added for Provider pattern
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentlyPlayingMessageId = null;
        notifyListeners(); // Added for Provider pattern
      });

      _flutterTts.setErrorHandler((error) {
        _isPlaying = false;
        _currentlyPlayingMessageId = null;
        notifyListeners(); // Added for Provider pattern
        if (kDebugMode) print('TTS Error: $error');
      });
      
      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        _currentlyPlayingMessageId = null;
        notifyListeners(); // Added for Provider pattern
      });

      _flutterTts.setPauseHandler(() {
        _isPlaying = false;
        notifyListeners(); // Added for Provider pattern
      });

      _flutterTts.setContinueHandler(() {
        _isPlaying = true;
        notifyListeners(); // Added for Provider pattern
      });

      // Set initial settings
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      if (kDebugMode) print('Error initializing text-to-speech: $e');
    }
  }

  // Set language for speech
  Future<bool> setLanguage(String languageCode) async {
    try {
      // Check if the language is available
      final available = await _flutterTts.isLanguageAvailable(languageCode);
      if (available == null || available == false) {
        if (kDebugMode) print('Language $languageCode not available');
        return false;
      }

      await _flutterTts.setLanguage(languageCode);
      _currentLanguageCode = languageCode;
      return true;
    } catch (e) {
      if (kDebugMode) print('Error setting TTS language: $e');
      return false;
    }
  }

  // Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      throw ArgumentError('Speech rate must be between 0.0 and 1.0');
    }
    
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  // Set speech pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0) {
      throw ArgumentError('Pitch must be between 0.5 and 2.0');
    }
    
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  // Enhanced speak method with message ID tracking (for ChatMessage integration)
  Future<void> speak(String text, {String? messageId, String? languageCode}) async {
    if (text.isEmpty) return;
    
    // Stop any ongoing speech
    if (_isPlaying) {
      await stop();
    }

    try {
      // 1. Force the language to Indian English if they are learning English
      if (languageCode == 'en' || languageCode == 'en-US' || languageCode == 'en-GB' || languageCode == null) {
          languageCode = 'en-IN';
      }

      // 2. Strictly hunt for a Female Voice, prioritizing Indian Female
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null && voices is List) {
          Map<String, String>? perfectIndianFemale;
          Map<String, String>? fallbackFemale;
          
          for (var v in voices) {
            if (v is Map) {
              final name = v["name"]?.toString().toLowerCase() ?? '';
              final locale = v["locale"]?.toString().toLowerCase() ?? '';
              
              if (languageCode == 'en-IN' && locale.contains('en-in') && (name.contains('female') || name.contains('neerja'))) {
                 perfectIndianFemale = {"name": v["name"].toString(), "locale": v["locale"].toString()};
              }
              else if (locale.startsWith(languageCode!.split('-')[0].toLowerCase())) {
                 if (name.contains('female') || name.contains('woman') || name.contains('zira') || name.contains('samantha')) {
                    fallbackFemale = {"name": v["name"].toString(), "locale": v["locale"].toString()};
                 }
              }
            }
          }
          
          if (perfectIndianFemale != null) {
             await _flutterTts.setVoice(perfectIndianFemale);
          } else if (fallbackFemale != null) {
             await _flutterTts.setVoice(fallbackFemale);
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error hunting for female voice: $e');
      }

      // Always raise pitch slightly to emulate female tone if engine fails voice selection
      await setPitch(1.2);

      // Set language if provided
      if (languageCode != null && languageCode != _currentLanguageCode) {
        try {
           await setLanguage(languageCode);
        } catch (e) {
           // Ignore language setup failure on browsers if voice is already set
        }
      }

      _currentlyPlayingMessageId = messageId;
      await _flutterTts.speak(text);
    } catch (e) {
      _currentlyPlayingMessageId = null;
      notifyListeners();
      if (kDebugMode) print('Error speaking text: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _currentlyPlayingMessageId = null;
      notifyListeners(); // Added for Provider pattern
    } catch (e) {
      if (kDebugMode) print('Error stopping TTS: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      if (kDebugMode) print('Error pausing TTS: $e');
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      if (kDebugMode) print('Error getting available TTS languages: $e');
      return [];
    }
  }

  // Get current language code
  String getCurrentLanguage() {
    return _currentLanguageCode;
  }

  // Dispose resources
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose(); // Important for ChangeNotifier
  }
}