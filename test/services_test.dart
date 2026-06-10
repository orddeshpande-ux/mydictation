import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/services/brain_service.dart';
import 'package:omniscribe_ai/src/services/domain_service.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) sendCallback;

  MockHttpClient(this.sendCallback);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await sendCallback(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      contentLength: response.contentLength,
    );
  }
}

void main() {
  group('BrainService Tests', () {
    test('analyzeTranscript handles successful response', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/analyze');
        expect(request.method, 'POST');
        return http.Response(jsonEncode({'analysis': 'This is a test summary.'}), 200);
      });

      final brainService = BrainService(client: mockClient);
      final result = await brainService.analyzeTranscript('hello world', 'system prompt');
      expect(result, 'This is a test summary.');
    });

    test('analyzeTranscript handles non-200 error', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('Error', 500);
      });

      final brainService = BrainService(client: mockClient);
      final result = await brainService.analyzeTranscript('hello world', 'system prompt');
      expect(result.contains('Server Error'), true);
    });

    test('cleanTranscript handles successful response', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/clean');
        expect(request.method, 'POST');
        return http.Response(jsonEncode({'cleaned_text': 'Clean Text'}), 200);
      });

      final brainService = BrainService(client: mockClient);
      final result = await brainService.cleanTranscript('dirty text');
      expect(result, 'Clean Text');
    });

    test('testConnection returns true on status 200', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('ok', 200);
      });

      final brainService = BrainService(client: mockClient);
      final result = await brainService.testConnection('http://localhost:5050');
      expect(result, true);
    });
  });

  group('DomainService Tests', () {
    test('reviewTranscript triggers brain service and returns response', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response(jsonEncode({'analysis': 'Insight analysis'}), 200);
      });
      final brainService = BrainService(client: mockClient);
      final domainService = DomainService(brainService: brainService);

      final result = await domainService.reviewTranscript('text', DomainMode.legal);
      expect(result, 'Insight analysis');
    });
  });

  group('VoiceCloneService Tests', () {
    test('listVoices returns profiles list', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/voices');
        return http.Response(jsonEncode([
          {'id': '123', 'name': 'Voice A', 'status': 'ready', 'sample_count': 5}
        ]), 200);
      });

      final service = VoiceCloneService(client: mockClient);
      final list = await service.listVoices();
      expect(list.length, 1);
      expect(list[0]['name'], 'Voice A');
    });

    test('trainVoice returns status bool', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/voices/123/train');
        return http.Response('', 200);
      });

      final service = VoiceCloneService(client: mockClient);
      final success = await service.trainVoice('123');
      expect(success, true);
    });

    test('generateSpeech returns filename and download url', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/generate');
        return http.Response(jsonEncode({
          'filename': 'speech.mp3',
          'download_url': '/download/speech.mp3'
        }), 200);
      });

      final service = VoiceCloneService(client: mockClient);
      final res = await service.generateSpeech(voiceId: '123', text: 'hello');
      expect(res?['filename'], 'speech.mp3');
    });

    test('isServerRunning returns true on success', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('ok', 200);
      });

      final service = VoiceCloneService(client: mockClient);
      final running = await service.isServerRunning();
      expect(running, true);
    });
  });
}
