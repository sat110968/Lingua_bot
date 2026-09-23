class LanguageAccentMapper {
  static const Map<String, Map<String, String>> accentMapping = {
    'en': {
      'nativeCode': 'en-US',
      'accent': 'American',
      'description': 'English - American English',
    },
    'ta': {
      'nativeCode': 'ta-IN',
      'accent': 'Indian Tamil',
      'description': 'Tamil - Indian Tamil with native accent',
    },
    'hi': {
      'nativeCode': 'hi-IN',
      'accent': 'Indian Hindi',
      'description': 'Hindi - Indian Hindi with native accent',
    },
    'ja': {
      'nativeCode': 'ja-JP',
      'accent': 'Native Japanese',
      'description': 'Japanese - Native Japanese pronunciation',
    },
    'es': {
      'nativeCode': 'es-ES',
      'accent': 'Spain Spanish',
      'description': 'Spanish - Spain Spanish with native accent',
    },
    'fr': {
      'nativeCode': 'fr-FR',
      'accent': 'Native French',
      'description': 'French - Native French pronunciation',
    },
    'de': {
      'nativeCode': 'de-DE',
      'accent': 'Native German',
      'description': 'German - Native German pronunciation',
    },
    'pt': {
      'nativeCode': 'pt-BR',
      'accent': 'Brazilian Portuguese',
      'description': 'Portuguese - Brazilian Portuguese',
    },
    'ru': {
      'nativeCode': 'ru-RU',
      'accent': 'Native Russian',
      'description': 'Russian - Native Russian pronunciation',
    },
    'zh': {
      'nativeCode': 'zh-CN',
      'accent': 'Mandarin Chinese',
      'description': 'Chinese - Mandarin with native accent',
    },
    'ko': {
      'nativeCode': 'ko-KR',
      'accent': 'Native Korean',
      'description': 'Korean - Native Korean pronunciation',
    },
  };

  static String getNativeTtsCode(String languageCode) {
    final code = languageCode.split('-').first.toLowerCase();
    return accentMapping[code]?['nativeCode'] ?? 'en-US';
  }

  static String getAccentDescription(String languageCode) {
    final code = languageCode.split('-').first.toLowerCase();
    return accentMapping[code]?['accent'] ?? 'Standard';
  }

  static String getFullDescription(String languageCode) {
    final code = languageCode.split('-').first.toLowerCase();
    return accentMapping[code]?['description'] ?? 'English - Standard';
  }
}
