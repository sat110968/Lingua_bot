class Language {
  final String code;
  final String name;
  final String nativeName;

  // Keep a single shared list of Language instances so widgets use the same objects.
  static final List<Language> _all = [
    const Language(code: 'en', name: 'English', nativeName: 'English'),
    // const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    // const Language(code: 'fr', name: 'French', nativeName: 'Français'),
    // const Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
    // const Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    // const Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    // const Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    // const Language(code: 'zh', name: 'Chinese', nativeName: '中文'),
    // const Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    // const Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
    // const Language(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    const Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    // const Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    // const Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    // const Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
    // const Language(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    const Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
    // const Language(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
    // const Language(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    // const Language(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    // const Language(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
    // const Language(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
    // const Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    // const Language(code: 'as', name: 'Assamese', nativeName: 'অসমীয়া'),
    // const Language(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
  ];

  // Public accessors
  static List<Language> getLanguages() => List.unmodifiable(_all);
  static Language get english => _all.firstWhere((l) => l.code == 'en');

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  @override
  String toString() => name;

  // For saving to SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nativeName': nativeName,
    };
  }

  // Create from JSON
  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'],
      name: json['name'],
      nativeName: json['nativeName'],
    );
  }

  // Compare languages by unique 'code' so Dropdown and equality checks work across instances.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}