import 'package:speech_to_text/speech_to_text.dart';

/// Wraps on-device speech-to-text. Uses the phone's built-in recognizer —
/// no server, no cost. Requires the RECORD_AUDIO permission (added in CI).
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (_available) return true;
    _available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ready = await init();
    if (!ready) return false;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stop() async => _speech.stop();
  Future<void> cancel() async => _speech.cancel();
}
