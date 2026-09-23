import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'conversation_screen.dart';
import 'language_selection_screen.dart';

class GrammarSelectionScreen extends StatelessWidget {
  const GrammarSelectionScreen({super.key});

  static const List<Map<String, String>> grammarTopics = [
    {'title': 'Present Tense', 'icon': '⏱️', 'description': 'Present simple, continuous, and perfect'},
    {'title': 'Past Tense', 'icon': '⏪', 'description': 'Past simple, continuous, and perfect'},
    {'title': 'Future Tense', 'icon': '⏩', 'description': 'Future simple, continuous, and perfect'},
    {'title': 'Modal Verbs', 'icon': '🔑', 'description': 'Can, could, may, might, must, should'},
    {'title': 'Conditionals', 'icon': '❓', 'description': 'If clauses and conditional structures'},
    {'title': 'Passive Voice', 'icon': '🔄', 'description': 'Converting active to passive voice'},
    {'title': 'Question Forms', 'icon': '❔', 'description': 'Formation of questions and question tags'},
    {'title': 'Pronouns & Determiners', 'icon': '👤', 'description': 'Personal, relative, and demonstrative pronouns'},
    {'title': 'Prepositions', 'icon': '📍', 'description': 'Time, place, and movement prepositions'},
    {'title': 'Adjectives & Adverbs', 'icon': '✨', 'description': 'Comparative and superlative forms'},
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Grammar Topic'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Language Info
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                '${settings.learningLanguage?.name ?? "Language"} ← ${settings.nativeLanguage?.name ?? "Native"}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Grammar Topics Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: grammarTopics.length,
                itemBuilder: (context, index) {
                  final topic = grammarTopics[index];
                  return _buildTopicCard(
                    context,
                    title: topic['title']!,
                    icon: topic['icon']!,
                    description: topic['description']!,
                    onTap: () => _navigateToConversation(context, topic['title']!),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required String title,
    required String icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToConversation(BuildContext context, String topic) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(grammarTopic: topic),
      ),
    );
  }
}
