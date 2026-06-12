import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/services/domain_service.dart';
import 'package:omniscribe_ai/src/services/stt_service.dart';
import 'package:omniscribe_ai/src/utils/punctuation_formatter.dart';

part 'dictation_event.dart';
part 'dictation_state.dart';

class DictationBloc extends Bloc<DictationEvent, DictationState> {
  final SpeechToTextService _sttService;
  final DomainService _domainService;

  DictationBloc({SpeechToTextService? sttService, DomainService? domainService})
      : _sttService = sttService ?? SpeechToTextService(),
        _domainService = domainService ?? DomainService(),
        super(const DictationState.initial()) {
    on<StartDictation>(_onStartDictation);
    on<StopDictation>(_onStopDictation);
    on<CleanTranscription>(_onCleanTranscription);
    on<GenerateInsights>(_onGenerateInsights);
    on<UpdateTranscript>(_onUpdateTranscript);
    on<DictationErrorOccurred>(_onDictationErrorOccurred);
    on<CleanAndGenerateInsights>(_onCleanAndGenerateInsights);
  }

  Future<void> _onStartDictation(StartDictation event, Emitter<DictationState> emit) async {
    emit(state.copyWith(isDictating: true, status: DictationStatus.listening, errorMessage: ''));
    try {
      await _sttService.startListening(
        localeId: event.localeId,
        onResult: (text) {
          add(UpdateTranscript(text));
        },
        onError: (errorMsg) {
          add(DictationErrorOccurred(errorMsg));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isDictating: false,
        status: DictationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onStopDictation(StopDictation event, Emitter<DictationState> emit) async {
    await _sttService.stopListening();
    emit(state.copyWith(isDictating: false, status: DictationStatus.idle));
  }

  void _onUpdateTranscript(UpdateTranscript event, Emitter<DictationState> emit) {
    final formatted = PunctuationFormatter.format(event.transcript);
    emit(state.copyWith(transcript: formatted, status: DictationStatus.listening));
  }

  void _onDictationErrorOccurred(DictationErrorOccurred event, Emitter<DictationState> emit) {
    emit(state.copyWith(
      isDictating: false,
      status: DictationStatus.error,
      errorMessage: event.errorMessage,
    ));
  }

  Future<void> _onCleanTranscription(CleanTranscription event, Emitter<DictationState> emit) async {
    if (state.transcript.trim().isEmpty) return;
    
    emit(state.copyWith(status: DictationStatus.processing));
    try {
      final cleanedText = await _domainService.cleanTranscript(state.transcript);
      emit(state.copyWith(transcript: cleanedText, status: DictationStatus.idle));
    } catch (e) {
      emit(state.copyWith(status: DictationStatus.idle, errorMessage: e.toString()));
    }
  }

  Future<void> _onGenerateInsights(GenerateInsights event, Emitter<DictationState> emit) async {
    if (state.transcript.trim().isEmpty) return;
    
    emit(state.copyWith(status: DictationStatus.processing));
    try {
      final responseStr = await _domainService.reviewTranscript(state.transcript, event.mode);
      
      // Parse JSON
      List<Insight> newInsights = [];
      try {
        final parsed = jsonDecode(responseStr) as List;
        for (var item in parsed) {
          if (item is Map) {
            newInsights.add(Insight(
              title: item['title'] ?? 'Insight',
              message: item['message'] ?? '',
              type: item['type'] ?? 'info',
            ));
          }
        }
      } catch (e) {
        // Fallback if model fails to output valid JSON
        newInsights.add(Insight(
          title: 'Analysis Result',
          message: responseStr,
          type: 'info',
        ));
      }
      
      emit(state.copyWith(insights: newInsights, status: DictationStatus.idle));
    } catch (e) {
      emit(state.copyWith(status: DictationStatus.idle, errorMessage: e.toString()));
    }
  }

  Future<void> _onCleanAndGenerateInsights(CleanAndGenerateInsights event, Emitter<DictationState> emit) async {
    if (state.transcript.trim().isEmpty) return;

    emit(state.copyWith(status: DictationStatus.processing, errorMessage: ''));

    String currentText = state.transcript;
    
    // Step 1: Clean transcript
    try {
      currentText = await _domainService.cleanTranscript(currentText);
      emit(state.copyWith(transcript: currentText, status: DictationStatus.processing));
    } catch (e) {
      print('Clean error: $e');
      // Fallback: continue with original text if cleaning fails
    }

    // Step 2: Generate insights
    try {
      final responseStr = await _domainService.reviewTranscript(currentText, event.mode);
      
      // Parse JSON
      List<Insight> newInsights = [];
      try {
        final parsed = jsonDecode(responseStr) as List;
        for (var item in parsed) {
          if (item is Map) {
            newInsights.add(Insight(
              title: item['title'] ?? 'Insight',
              message: item['message'] ?? '',
              type: item['type'] ?? 'info',
            ));
          }
        }
      } catch (e) {
        // Fallback if model fails to output valid JSON
        newInsights.add(Insight(
          title: 'Analysis Result',
          message: responseStr,
          type: 'info',
        ));
      }
      
      emit(state.copyWith(insights: newInsights, status: DictationStatus.idle));
    } catch (e) {
      emit(state.copyWith(status: DictationStatus.idle, errorMessage: e.toString()));
    }
  }
}
