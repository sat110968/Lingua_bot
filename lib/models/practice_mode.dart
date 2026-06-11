enum PracticeMode {
  basicConversation('Basic Conversation'),
  practicalConversation('Practical Conversation'),
  vocabulary('Vocabulary Practice'),
  grammar('Grammar Practice');

  final String displayName;

  const PracticeMode(this.displayName);
}

extension PracticeModeExtension on PracticeMode {
  String get name {
    switch (this) {
      case PracticeMode.basicConversation:
        return 'Basic Conversation';
      case PracticeMode.practicalConversation:
        return 'Practical Conversation';
      case PracticeMode.vocabulary:
        return 'Vocabulary Practice';
      case PracticeMode.grammar:
        return 'Grammar Practice';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.basicConversation:
        return 'Daily practice of words and basic conversations for all beginners';
      case PracticeMode.practicalConversation:
        return 'Real-world dialogues on topics you choose - intermediate & advanced';
      case PracticeMode.vocabulary:
        return 'Learn new words, phrases, and usage in context';
      case PracticeMode.grammar:
        return 'Master grammar rules, sentence structure, and correct usage';
    }
  }

  String get apiValue {
    switch (this) {
      case PracticeMode.basicConversation:
        return 'basic_conversation';
      case PracticeMode.practicalConversation:
        return 'practical_conversation';
      case PracticeMode.vocabulary:
        return 'vocabulary';
      case PracticeMode.grammar:
        return 'grammar';
    }
  }

  String get iconPath {
    switch (this) {
      case PracticeMode.basicConversation:
        return 'assets/icons/basic.png';
      case PracticeMode.practicalConversation:
        return 'assets/icons/conversation.png';
      case PracticeMode.vocabulary:
        return 'assets/icons/vocabulary.png';
      case PracticeMode.grammar:
        return 'assets/icons/grammar.png';
    }
  }

  String get methodDescription {
    switch (this) {
      case PracticeMode.basicConversation:
        return '''
📚 Basic Conversation Method:
• Daily word-based practice
• Simple vocabulary building
• Short conversations with taught words
• Ideal for beginners (A1-A2 level)
• 10-15 minutes per session
• Pronunciation focus with slow, clear speech
''';
      case PracticeMode.practicalConversation:
        return '''
🎤 Practical Conversation Method:
• Real-world scenario dialogues
• User selects conversation topics
• Natural native-speaker interactions
• Intermediate & Advanced (B1-C1 level)
• 15-30 minutes per session
• Business, travel, daily life, hobbies, etc.
''';
      case PracticeMode.vocabulary:
        return '''
📖 Vocabulary Practice Method:
• Word meaning and usage
• Multiple example sentences
• Word form variations (verb/noun/adjective)
• Related word families
• Context-based learning
• Pronunciation practice
''';
      case PracticeMode.grammar:
        return '''
✏️ Grammar Practice Method:
• Grammar rule explanations
• Comparative examples
• Exception handling
• Common mistakes
• Practice exercises
• Real usage in context
''';
    }
  }
}