import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// Test helper setup for common test utilities
void setupTests() {
  setUpAll(() {
    // Global test setup
  });

  tearDown(() {
    // Reset mocks between tests
  });
}

/// Mock classes for testing
class MockHttpClient extends Mock {}

class MockSharedPreferences extends Mock {}

class MockSupabaseClient extends Mock {}

class MockAuthService extends Mock {}

class MockGeminiService extends Mock {}

class MockLoggingService extends Mock {}

/// Helper to verify no interactions with mock
void verifyNoInteractions(Mock mock) {
  verifyNever(mock as dynamic);
}

/// Helper to create test fixtures
class TestFixtures {
  static Map<String, dynamic> createUserJson({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'created_at': DateTime.now().toIso8601String(),
      'profile_image_url': null,
      'native_language': 'Hindi',
      'learning_language': 'English',
    };
  }

  static Map<String, dynamic> createVocabularyWordJson({
    String word = 'hello',
    String nativeMeaning = 'नमस्ते',
    String learningLanguage = 'English',
    String courseIdentifier = 'global_english_hindi',
  }) {
    return {
      'id': 1,
      'word': word,
      'native_meaning': nativeMeaning,
      'example_sentence': 'Hello, how are you?',
      'learning_language': learningLanguage,
      'native_language': 'Hindi',
      'course_identifier': courseIdentifier,
      'difficulty_level': 1,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createChatMessageJson({
    String role = 'user',
    String content = 'Test message',
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'audioPath': null,
      'isError': false,
    };
  }
}

/// Custom matchers
Matcher isVocabularyWord() => isA<Map<String, dynamic>>()
    .having((w) => w['word'], 'word', isNotEmpty)
    .having((w) => w['native_meaning'], 'native_meaning', isNotEmpty);
