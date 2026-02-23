import 'dart:async';
import 'package:flutter/material.dart';
import '../services/speech_to_text_service.dart';
import '../theme.dart';
import 'dart:math' as math;

/// A button that handles voice recording and speech-to-text conversion.
class RecordingButton extends StatefulWidget {
  final SpeechToTextService speechToTextService;
  final String languageCode;
  final Function(String) onResult;

  const RecordingButton({
    Key? key,
    required this.speechToTextService,
    required this.languageCode,
    required this.onResult,
  }) : super(key: key);

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _textStreamSubscription;
  
  bool _isListening = false;
  String _recognizedText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Subscribe to the text stream from the service
    _textStreamSubscription = widget.speechToTextService.textStream.listen(
      (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
            _errorMessage = null; // Clear error on new text
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
            _isListening = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textStreamSubscription?.cancel();
    super.dispose();
  }

  /// Toggles the listening state of the speech recognition service.
  Future<void> _toggleListening() async {
    if (_isListening) {
      // If currently listening, stop it and process the result.
      widget.speechToTextService.stopListening();
      if (_recognizedText.isNotEmpty) {
        widget.onResult(_recognizedText);
      }
      setState(() {
        _isListening = false;
      });
    } else {
      // If not listening, start it.
      final started = await widget.speechToTextService.startListening(widget.languageCode);
      if (started) {
        setState(() {
          _isListening = true;
          _errorMessage = null;
        });
      } else {
        // If it failed to start, show an error message.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.speechToTextService.lastError ?? 'Failed to start voice recognition.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated recording button
        GestureDetector(
          onTap: _toggleListening,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2.0 * math.pi,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.animatedGradient,
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? AppTheme.primaryColor : theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppTheme.primaryColor : theme.colorScheme.secondary).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Display recognized text or status
        Container(
          height: 40,
          alignment: Alignment.center,
          child: _isListening
              ? Text(
                  _recognizedText.isEmpty ? 'Listening...' : _recognizedText,
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                )
              : Text(
                  _errorMessage ?? 'Tap the mic to speak',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _errorMessage != null ? Colors.red : AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }
}