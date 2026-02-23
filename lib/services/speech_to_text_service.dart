import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// A service to handle speech-to-text functionality using the speech_to_text package.
/// This service is simplified to be more robust and easier to manage.
class SpeechToTextService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  String? _lastError;
  Completer<bool>? _listeningCompleter;

  // --- Public Getters ---
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  String get lastRecognizedText => _lastRecognizedText;

  // --- Stream for UI Updates ---
  // This stream will emit text as it's being recognized.
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textStreamController.stream;

  /// Initializes the speech recognition service.
  /// Must be called once before any other methods.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // The initialize method handles permission requests internally on most platforms.
      _isInitialized = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode, // Use kDebugMode for logging
      );
      return _isInitialized;
    } catch (e) {
      _lastError = "Failed to initialize speech service: ${e.toString()}";
      return false;
    }
  }

  /// Starts listening for speech.
  /// Requires a `languageCode` (e.g., 'en-US').
  /// Returns `true` if listening started successfully.
  Future<bool> startListening(String languageCode) async {
    if (!_isInitialized) {
      _lastError = "Service not initialized.";
      return false;
    }
    if (_isListening) {
      _lastError = "Already listening.";
      return false;
    }

    try {
      _lastRecognizedText = '';
      _lastError = null;
      _listeningCompleter = Completer<bool>();

      _speechToText.listen(
        onResult: _onResult,
        localeId: languageCode,
        listenFor: const Duration(seconds: 30), // Max duration for a single listen session
        pauseFor: const Duration(seconds: 3),  // Shorter pause time
      );

      // Wait for the status to become 'listening' or for an error, with a timeout.
      return await _listeningCompleter!.future.timeout(const Duration(seconds: 5));

    } catch (e) {
      _lastError = "An unexpected error occurred while starting to listen: ${e.toString()}";
      _listeningCompleter?.complete(false);
      return false;
    }
  }

  /// Stops the current listening session.
  void stopListening() {
    if (!_isListening) return;
    _speechToText.stop();
    _isListening = false;
  }

  /// Cancels the current listening session immediately.
  void cancelListening() {
    if (!_isListening) return;
    _speechToText.cancel();
    _isListening = false;
  }

  // --- Internal Callbacks for the speech_to_text package ---

  /// Called when a speech recognition result is received.
  void _onResult(SpeechRecognitionResult result) {
    _lastRecognizedText = result.recognizedWords;
    _textStreamController.add(_lastRecognizedText);

    // When the result is final, we can consider the listening session complete.
    if (result.finalResult) {
      _isListening = false;
    }
  }

  /// Called when a speech recognition error occurs.
  void _onError(SpeechRecognitionError error) {
    _lastError = 'Error: ${error.errorMsg} - ${error.permanent ? "Permanent" : "Temporary"}';
    _isListening = false;
    if (_listeningCompleter != null && !_listeningCompleter!.isCompleted) {
      _listeningCompleter!.complete(false);
    }
    _textStreamController.addError(_lastError!);
  }

  /// Called when the status of the speech recognition service changes.
  void _onStatus(String status) {
    if (kDebugMode) {
      print('Speech recognition status: $status');
    }
    if (status == 'listening') {
      _isListening = true;
      if (_listeningCompleter != null && !_listeningCompleter!.isCompleted) {
        _listeningCompleter!.complete(true);
      }
    } else if (status == 'done' || status == 'notListening') {
      _isListening = false;
      if (_listeningCompleter != null && !_listeningCompleter!.isCompleted) {
        _listeningCompleter!.complete(false);
      }
    }
  }

  /// Disposes the stream controller.
  void dispose() {
    _textStreamController.close();
  }
}