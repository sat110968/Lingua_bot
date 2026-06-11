import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'basic_conversation_screen.dart';
import 'practical_conversation_screen.dart';
import 'grammar_screen.dart';
import 'language_selection_screen.dart';

/// Mode Selection Screen - Choose Learning Mode
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Learning Mode'),
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
                '${settings.learningLanguage?.name ?? "English"} ← ${settings.nativeLanguage?.name ?? "Hindi"}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            // Mode Selection Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Conversation Card
                  _buildModeCard(
                    context,
                    icon: '📚',
                    title: 'Basic Conversation',
                    subtitle: '25 Words Per Day',
                    description: 'Learn 3-5 new words daily with pronunciation, examples, and practice conversations.',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const BasicConversationScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Practical Conversation Card
                  _buildModeCard(
                    context,
                    icon: '💬',
                    title: 'Practical Conversation',
                    subtitle: 'Real-World Dialogue',
                    description: 'Have natural conversations on any topic - business, travel, hobbies, daily life, and more.',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const PracticalConversationScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Grammar Practice Card
                  _buildModeCard(
                    context,
                    icon: '✏️',
                    title: 'Grammar Practice',
                    subtitle: 'Grammar Rules & Exercises',
                    description: 'Master grammar rules, sentence structure, common mistakes, and correct usage.',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const GrammarScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
