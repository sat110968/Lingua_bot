enum PracticeMode {
  conversation('Conversation'),
  vocabulary('Vocabulary'),
  grammar('Grammar');

  final String displayName;

  const PracticeMode(this.displayName);
}

extension PracticeModeExtension on PracticeMode {
  String get name {
    switch (this) {
      case PracticeMode.conversation:
        return 'Conversation';
      case PracticeMode.vocabulary:
        return 'Vocabulary';
      case PracticeMode.grammar:
        return 'Grammar';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.conversation:
        return 'Natural dialogue practicing everyday situations';
      case PracticeMode.vocabulary:
        return 'Focus on learning new words and phrases';
      case PracticeMode.grammar:
        return 'Practice correct sentence structure and grammar rules';
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
}