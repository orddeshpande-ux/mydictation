import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Check if the required speech and microphone permissions are granted.
  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS) {
      final micStatus = await Permission.microphone.status;
      if (Platform.isIOS) {
        final speechStatus = await Permission.speech.status;
        return micStatus.isGranted && speechStatus.isGranted;
      }
      return micStatus.isGranted;
    }
    return true;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // First verify system permissions are granted
    final hasPerms = await hasPermissions();
    if (!hasPerms) {
      print('SpeechToTextService: Permissions are not granted.');
      return false;
    }

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
      onError('Speech recognition is not available on this device. Please check your microphone permissions or ensure speech services are installed.');
      return;
    }

    try {
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
    } catch (e) {
      onError('Failed to start listening: $e');
    }
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
