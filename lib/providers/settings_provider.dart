import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/language.dart';
import '../models/practice_mode.dart';

class SettingsProvider extends ChangeNotifier {
  Language? _learningLanguage;
  Language? _nativeLanguage;
  PracticeMode _practiceMode = PracticeMode.basicConversation;

  Language? get learningLanguage => _learningLanguage;
  Language? get nativeLanguage => _nativeLanguage;
  PracticeMode get practiceMode => _practiceMode;

  // Load settings from SharedPreferences on app start
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final learningLangJson = prefs.getString('learning_language');
      if (learningLangJson != null) {
        _learningLanguage = Language.fromJson(jsonDecode(learningLangJson));
      }

      final nativeLangJson = prefs.getString('native_language');
      if (nativeLangJson != null) {
        _nativeLanguage = Language.fromJson(jsonDecode(nativeLangJson));
      }

      final practiceModeString = prefs.getString('practice_mode');
      if (practiceModeString != null) {
        _practiceMode = PracticeMode.values.firstWhere(
          (e) => e.name == practiceModeString,
          orElse: () => PracticeMode.basicConversation,
        );
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading settings: $e');
    }
  }

  // Set learning language and persist to SharedPreferences
  Future<void> setLearningLanguage(Language language) async {
    _learningLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_language', jsonEncode(language.toJson()));
    notifyListeners();
  }

  // Set native language and persist to SharedPreferences
  Future<void> setNativeLanguage(Language language) async {
    _nativeLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('native_language', jsonEncode(language.toJson()));
    notifyListeners();
  }

  // Set practice mode and persist to SharedPreferences
  Future<void> setPracticeMode(PracticeMode mode) async {
    _practiceMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('practice_mode', mode.name);
    notifyListeners();
  }
}
