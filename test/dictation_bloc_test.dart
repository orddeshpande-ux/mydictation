import 'package:flutter_test/flutter_test.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/services/domain_service.dart';
import 'package:omniscribe_ai/src/services/stt_service.dart';

class MockSpeechToTextService extends SpeechToTextService {
  bool isListeningCalled = false;
  bool stopListeningCalled = false;
  Function(String)? onResultCallback;
  Function(String)? onErrorCallback;

  @override
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String? localeId,
  }) async {
    isListeningCalled = true;
    onResultCallback = onResult;
    onErrorCallback = onError;
  }

  @override
  Future<void> stopListening() async {
    stopListeningCalled = true;
    isListeningCalled = false;
  }
}

class MockDomainService extends DomainService {
  String cleanResult = 'Cleaned Text';
  String reviewResult = '[{"title": "Test Title", "message": "Test Message", "type": "suggestion"}]';
  bool cleanCalled = false;
  bool reviewCalled = false;

  @override
  Future<String> cleanTranscript(String transcript) async {
    cleanCalled = true;
    return cleanResult;
  }

  @override
  Future<String> reviewTranscript(String transcript, DomainMode mode) async {
    reviewCalled = true;
    return reviewResult;
  }
}

void main() {
  group('DictationBloc Tests', () {
    late MockSpeechToTextService sttService;
    late MockDomainService domainService;
    late DictationBloc bloc;

    setUp(() {
      sttService = MockSpeechToTextService();
      domainService = MockDomainService();
      bloc = DictationBloc(sttService: sttService, domainService: domainService);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state, const DictationState.initial());
    });

    test('StartDictation starts listening and updates state', () async {
      bloc.add(const StartDictation());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.isDictating, true);
      expect(bloc.state.status, DictationStatus.listening);
      expect(sttService.isListeningCalled, true);
    });

    test('UpdateTranscript updates state transcript', () async {
      bloc.add(const UpdateTranscript('hello world'));
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(bloc.state.transcript, 'hello world');
      expect(bloc.state.status, DictationStatus.listening);
    });

    test('StopDictation stops listening and resets state', () async {
      bloc.add(StopDictation());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.isDictating, false);
      expect(bloc.state.status, DictationStatus.idle);
      expect(sttService.stopListeningCalled, true);
    });

    test('CleanTranscription updates transcript', () async {
      bloc.add(const UpdateTranscript('dirty text'));
      await Future.delayed(const Duration(milliseconds: 10));
      
      bloc.add(CleanTranscription());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.transcript, 'Cleaned Text');
      expect(domainService.cleanCalled, true);
      expect(bloc.state.status, DictationStatus.idle);
    });

    test('GenerateInsights parses JSON list correctly', () async {
      bloc.add(const UpdateTranscript('analysis base'));
      await Future.delayed(const Duration(milliseconds: 10));

      bloc.add(const GenerateInsights(DomainMode.legal));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(domainService.reviewCalled, true);
      expect(bloc.state.insights.length, 1);
      expect(bloc.state.insights[0].title, 'Test Title');
      expect(bloc.state.insights[0].message, 'Test Message');
      expect(bloc.state.insights[0].type, 'suggestion');
      expect(bloc.state.status, DictationStatus.idle);
    });

    test('DictationErrorOccurred sets error message and error status', () async {
      bloc.add(const DictationErrorOccurred('error code 123'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.isDictating, false);
      expect(bloc.state.status, DictationStatus.error);
      expect(bloc.state.errorMessage, 'error code 123');
    });

    test('CleanAndGenerateInsights sequentially cleans and analyzes transcript', () async {
      bloc.add(const UpdateTranscript('dirty text'));
      await Future.delayed(const Duration(milliseconds: 10));

      bloc.add(const CleanAndGenerateInsights(DomainMode.legal));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(domainService.cleanCalled, true);
      expect(domainService.reviewCalled, true);
      expect(bloc.state.transcript, 'Cleaned Text');
      expect(bloc.state.insights.length, 1);
      expect(bloc.state.insights[0].title, 'Test Title');
      expect(bloc.state.status, DictationStatus.idle);
    });
  });
}
