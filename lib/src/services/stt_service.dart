import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (errorNotification) {
          print('Local STT Error: ${errorNotification.errorMsg}');
        },
        onStatus: (status) {
          print('Local STT Status: $status');
        },
      );
    } catch (e) {
      print('Local STT Initialization Exception: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String? localeId,
  }) async {
    final initialized = await initialize();
    if (!initialized) {
      onError('Speech recognition not available or permission denied.');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;

  Future<List<stt.LocaleName>> getAvailableLocales() async {
    final initialized = await initialize();
    if (!initialized) return [];
    return await _speech.locales();
  }
}
