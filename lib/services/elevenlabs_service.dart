import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class ElevenLabsService with ChangeNotifier {
  static const String _apiKey = "f1443dfa10e6ba876ab85ac593382605173aab712ae28563e23c435b59e2d8ea";
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentlyPlayingMessageId;
  bool _isPlaying = false;

  String? get currentlyPlayingMessageId => _currentlyPlayingMessageId;
  bool get isPlaying => _isPlaying;

  ElevenLabsService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentlyPlayingMessageId = null;
      }
      notifyListeners();
    });
  }

  Future<String?> speak(String text, String messageId) async {
    if (text.isEmpty) return null;

    if (_isPlaying) {
      await stop();
      if (_currentlyPlayingMessageId == messageId) {
        // If the same message is tapped again, stop it and don't restart.
        return null;
      }
    }

    _currentlyPlayingMessageId = messageId;
    notifyListeners();

    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM'); // Alice voice

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': _apiKey,
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$messageId.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        await _audioPlayer.play(DeviceFileSource(filePath));
        return filePath;
      } else {
        print('ElevenLabs API Error: ${response.statusCode} ${response.body}');
        _currentlyPlayingMessageId = null;
        notifyListeners();
        throw Exception('Failed to generate speech from ElevenLabs');
      }
    } catch (e) {
      print('Error in speak method: $e');
      _currentlyPlayingMessageId = null;
      notifyListeners();
      throw Exception('Failed to generate speech from ElevenLabs');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentlyPlayingMessageId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
