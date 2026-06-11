enum VoiceGender {
  female('Female'),
  male('Male');

  final String displayName;
  const VoiceGender(this.displayName);

  String get apiValue {
    switch (this) {
      case VoiceGender.female:
        return 'female';
      case VoiceGender.male:
        return 'male';
    }
  }
}

class VoiceSetting {
  final VoiceGender gender;
  final String language;

  VoiceSetting({
    required this.gender,
    required this.language,
  });

  VoiceSetting copyWith({
    VoiceGender? gender,
    String? language,
  }) {
    return VoiceSetting(
      gender: gender ?? this.gender,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_gender': gender.apiValue,
      'language': language,
    };
  }
}
