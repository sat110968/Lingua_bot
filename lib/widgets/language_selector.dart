import 'package:flutter/material.dart';
import '../models/language.dart';
import '../theme.dart';

class LearningLanguageSelector extends StatelessWidget {
  final Language? selectedLanguage;
  final ValueChanged<Language> onLanguageSelected;

  const LearningLanguageSelector({
    super.key,
    this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>();
    final languages = Language.getLanguages();

    // Guard: ensure languages list is not empty
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final Gradient? gradient = appTheme?.secondaryGradient;
    // Ensure fallbackColor is non-null
    final Color fallbackColor = AppColors.secondary;
    final Color dropdownColor = Colors.grey.shade800;

    // If gradient is null, use a concrete color (never pass null where Color is required)
    final Color? decorationColor = gradient == null ? fallbackColor : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: decorationColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selectedLanguage?.code,
        hint: const Text(
          'Select learning language',
          style: TextStyle(color: Colors.white70),
        ),
        dropdownColor: dropdownColor,
        underline: const SizedBox(),
        isExpanded: true,
        items: languages.map((language) {
          return DropdownMenuItem<String>(
            value: language.code,
            child: Text(
              '${language.nativeName} (${language.name})',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (code) {
          if (code == null) return;
          final language = languages.firstWhere((l) => l.code == code);
          onLanguageSelected(language);
        },
      ),
    );
  }
}

class NativeLanguageSelector extends StatelessWidget {
  final Language? selectedLanguage;
  final ValueChanged<Language> onLanguageSelected;

  const NativeLanguageSelector({
    super.key,
    this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>();
    final languages = Language.getLanguages();

    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final Gradient? gradient = appTheme?.primaryGradient;
    final Color fallbackColor = AppColors.primary;
    final Color dropdownColor = Colors.grey.shade800;

    final Color? decorationColor = gradient == null ? fallbackColor : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: decorationColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selectedLanguage?.code,
        hint: const Text(
          'Select native language',
          style: TextStyle(color: Colors.white70),
        ),
        dropdownColor: dropdownColor,
        underline: const SizedBox(),
        isExpanded: true,
        items: languages.map((language) {
          return DropdownMenuItem<String>(
            value: language.code,
            child: Text(
              '${language.nativeName} (${language.name})',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (code) {
          if (code == null) return;
          final language = languages.firstWhere((l) => l.code == code);
          onLanguageSelected(language);
        },
      ),
    );
  }
}