enum PracticeMode {
  conversation('Conversation Practice'),
  vocabulary('Vocabulary Practice'),
  grammar('Grammar Practice');

  final String displayName;

  const PracticeMode(this.displayName);
}

extension PracticeModeExtension on PracticeMode {
  String get name {
    switch (this) {
      case PracticeMode.conversation:
        return 'Conversation Practice';
      case PracticeMode.vocabulary:
        return 'Vocabulary Practice';
      case PracticeMode.grammar:
        return 'Grammar Practice';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.conversation:
        return 'Real-world natural conversations on topics you choose';
      case PracticeMode.vocabulary:
        return 'Learn new words, phrases, and usage in context';
      case PracticeMode.grammar:
        return 'Master grammar rules, sentence structure, and correct usage';
    }
  }

  String get apiValue {
    switch (this) {
      case PracticeMode.conversation:
        return 'conversation';
      case PracticeMode.vocabulary:
        return 'vocabulary';
      case PracticeMode.grammar:
        return 'grammar';
    }
  }

  String get iconPath {
    switch (this) {
      case PracticeMode.conversation:
        return 'assets/icons/conversation.png';
      case PracticeMode.vocabulary:
        return 'assets/icons/vocabulary.png';
      case PracticeMode.grammar:
        return 'assets/icons/grammar.png';
    }
  }

  String get methodDescription {
    switch (this) {
      case PracticeMode.conversation:
        return '''
🎤 Conversation Practice Method:
• Real-world natural dialogues
• User selects conversation topics
• Natural native-speaker interactions
• All proficiency levels (A1-C1)
• Pronunciation guide for each word
• Corrections in native language
• Female voice with native accent
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
