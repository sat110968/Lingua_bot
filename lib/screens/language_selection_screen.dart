import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../models/language.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/language_selector.dart';
import '../models/practice_mode.dart';
import 'chat_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // App Logo and Title
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            //gradient: AppTheme.of(context).primaryGradient,
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language Tutor',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'AI-powered language practice',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                // FIX: Use AppColors for static color constants.
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // I want to learn section
                    Text(
                      'I want to learn',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) => LearningLanguageSelector(
                        // FIX: Pass the nullable value directly. The LanguageSelector
                        // widget is designed to handle null and show a hint text.
                        selectedLanguage: settings.learningLanguage,
                        onLanguageSelected: (language) {
                          settings.setLearningLanguage(language);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // My native language section
                    Text(
                      'My native language is',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) => NativeLanguageSelector(
                        // FIX: Pass the nullable value directly.
                        selectedLanguage: settings.nativeLanguage,
                        onLanguageSelected: (language) {
                          settings.setNativeLanguage(language);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 64),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: Consumer<SettingsProvider>(
                        builder: (context, settings, _) => ElevatedButton(
                          // Only allow continue when both languages are selected
                          onPressed: settings.learningLanguage != null && settings.nativeLanguage != null
                              ? () {
                                  _showPracticeModeSelection(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color.fromARGB(255, 235, 209, 209),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color.fromARGB(255, 251, 228, 228),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // FIX: Use AppColors for static color constants.
                            //color: AppColors.textMuted,
                            color: const Color.fromARGB(255, 117, 117, 117),
                          ),
                          children: const [
                            TextSpan(text: '✨ Practice speaking, listening, reading, \nand writing in any language ✨'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showPracticeModeSelection(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom sheet handle
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Practice Mode',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How would you like to practice ${settings.learningLanguage?.name ?? 'your new language'}?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Practice mode cards
                        ..._buildPracticeModeCards(context, settings),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  List<Widget> _buildPracticeModeCards(BuildContext context, SettingsProvider settings) {
    final theme = Theme.of(context);
    
    return PracticeMode.values.map((mode) {
      final isSelected = settings.practiceMode == mode;
      
      return GestureDetector(
        onTap: () {
          // Save the chosen practice mode
          settings.setPracticeMode(mode);
          Navigator.pop(context); // Close bottom sheet
          // Use direct pushReplacement to the ChatScreen so it works even without named routes
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Mode icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mode == PracticeMode.conversation ? Icons.chat_bubble_outline :
                    mode == PracticeMode.vocabulary ? Icons.menu_book :
                    Icons.rule,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Mode description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected ? AppTheme.primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          // FIX: Use AppColors for static color constants.
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}