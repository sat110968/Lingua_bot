import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define consistent colors for reuse
abstract class AppColors {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color secondary = Color(0xFF00ACC1); // Cyan
  static const Color accent = Color(0xFFFFAB00); // Amber
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
}

// The custom theme extension that now includes the required gradients.
@immutable
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.primaryGradient,
    required this.secondaryGradient,
  });

  // FIX: Added the missing gradient properties.
  final Gradient primaryGradient;
  final Gradient secondaryGradient;

  @override
  AppTheme copyWith({Gradient? primaryGradient, Gradient? secondaryGradient}) {
    return AppTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) {
      return this;
    }
    return AppTheme(
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      secondaryGradient: Gradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
    );
  }

  // Static constant for easy access to the light theme extension
  static const light = AppTheme(
    primaryGradient: LinearGradient(
      colors: [AppColors.primary, Color(0xFF8E24AA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [AppColors.secondary, Color(0xFF00838F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Static constant for easy access to the dark theme extension
  static const dark = AppTheme(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF8E24AA), AppColors.primary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF00838F), AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // --- Static Theme Data ---

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: Colors.red,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: AppColors.text),
        titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[light],
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      error: Colors.redAccent,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: AppColors.darkText),
        titleLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[dark],
  );

  //static var primaryColor;

  //static var textMuted;

  //static var animatedGradient;

  static Color get primaryColor => AppColors.primary;

  static Color get textMuted => AppColors.textMuted;

  static Gradient get animatedGradient => const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static AppTheme of(BuildContext context) {
    return Theme.of(context).extension<AppTheme>() ?? AppTheme.light;
  }
}