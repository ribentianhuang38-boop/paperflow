import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    try {
      return await _speech.initialize();
    } catch (_) {
      return false;
    }
  }

  Future<void> listen({required Function(String) onResult}) async {
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
