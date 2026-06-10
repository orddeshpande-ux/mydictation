import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _isInitialized = true;
    } catch (e) {
      print('Local TTS Initialization Exception: $e');
    }
  }

  Future<void> speak(String text, {String locale = 'en-IN'}) async {
    await _initialize();
    if (text.trim().isNotEmpty) {
      await _tts.setLanguage(locale);
      _isSpeaking = true;
      await _tts.speak(text);
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  bool get isSpeaking => _isSpeaking;

  /// Convert locale ID format from STT (en_IN) to TTS (en-IN)
  String convertLocale(String sttLocale) {
    return sttLocale.replaceAll('_', '-');
  }

  void setCompletionHandler(Function callback) {
    _tts.setCompletionHandler(() => callback());
  }
}

