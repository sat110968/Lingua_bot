import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../models/language.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/language_selector.dart';
import '../models/practice_mode.dart';
import 'grammar_selection_screen.dart';
import 'conversation_screen.dart';

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
                        selectedLanguage: settings.nativeLanguage,
                        onLanguageSelected: (language) {
                          settings.setNativeLanguage(language);
                        },
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Practice Type Selection
                    Text(
                      'What would you like to do?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) => Column(
                        children: [
                          _buildPracticeTypeCard(
                            context,
                            theme,
                            icon: Icons.chat_bubble_outline,
                            title: 'Conversation',
                            description: 'Natural dialogues on any topic - basic to advanced',
                            isEnabled: settings.learningLanguage != null && settings.nativeLanguage != null,
                            onTap: () => _startConversation(context, settings),
                          ),
                          const SizedBox(height: 16),
                          _buildPracticeTypeCard(
                            context,
                            theme,
                            icon: Icons.rule,
                            title: 'Grammar',
                            description: 'Conversation practice focused on specific grammar topics',
                            isEnabled: settings.learningLanguage != null && settings.nativeLanguage != null,
                            onTap: () => _selectGrammarTopic(context, settings),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildPracticeTypeCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: isEnabled
              ? [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ]
              : [
                  Colors.grey.withValues(alpha: 0.05),
                  Colors.grey.withValues(alpha: 0.02),
                ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEnabled
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppTheme.primaryColor : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isEnabled ? AppColors.textMuted : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward,
                color: isEnabled ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startConversation(BuildContext context, SettingsProvider settings) {
    settings.setPracticeMode(PracticeMode.conversation);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConversationScreen()),
    );
  }

  void _selectGrammarTopic(BuildContext context, SettingsProvider settings) {
    settings.setPracticeMode(PracticeMode.grammar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GrammarSelectionScreen()),
    );
  }
}
