import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
// Use a prefix to avoid name collision with your own AudioRecorder class.
import 'package:record/record.dart' as record;

class AudioRecorder {
  // Instantiate the recorder from the 'record' package.
  final _audioRecorder = record.AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;

  /// Initialize the recorder
  Future<void> init() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      print('Error initializing audio recorder: $e');
      rethrow;
    }
  }

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // For web, the path argument is required but ignored. The actual path is a blob URL returned by stop().
        if (kIsWeb) {
          await _audioRecorder.start(const record.RecordConfig(), path: '');
        } else {
          final dir = await getApplicationDocumentsDirectory();
          _recordedFilePath =
              '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          // For mobile, you must provide an encoder in the RecordConfig.
          await _audioRecorder.start(
            const record.RecordConfig(encoder: record.AudioEncoder.aacLc),
            path: _recordedFilePath!,
          );
        }
        _isRecording = true;
      }
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        // The stop method now returns the path, which is especially useful for web.
        final path = await _audioRecorder.stop();
        _isRecording = false;
        // On mobile, the path from stop() will be the same as _recordedFilePath.
        // On web, it will be a blob URL.
        _recordedFilePath = path;
        return _recordedFilePath;
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Play recorded audio
  Future<void> playRecording() async {
    if (_recordedFilePath != null) {
      try {
        if (kIsWeb) {
          // For web, we'll need to handle blob URLs differently
          print('Web audio playback not fully implemented yet');
          return;
        }
        
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
        _isPlaying = true;

        // Update playing status when audio completes
        _audioPlayer.onPlayerComplete.listen((_) {
          _isPlaying = false;
        });
      } catch (e) {
        print('Error playing recording: $e');
        _isPlaying = false;
      }
    }
  }

  /// Stop playing audio
  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  /// Delete recorded audio file
  Future<void> deleteRecording() async {
    if (_recordedFilePath != null) {
      if (!kIsWeb) {
        try {
          final file = File(_recordedFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
          _recordedFilePath = null;
        } catch (e) {
          print('Error deleting recording: $e');
        }
      } else {
        _recordedFilePath = null;
      }
    }
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Get the path of recorded file
  String? get recordedFilePath => _recordedFilePath;

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}