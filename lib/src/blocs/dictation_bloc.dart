import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:omniscribe_ai/src/services/stt_service.dart';

part 'dictation_event.dart';
part 'dictation_state.dart';

class DictationBloc extends Bloc<DictationEvent, DictationState> {
  final SpeechToTextService _sttService;

  DictationBloc({SpeechToTextService? sttService})
      : _sttService = sttService ?? SpeechToTextService(),
        super(const DictationState.initial()) {
    on<StartDictation>(_onStartDictation);
    on<StopDictation>(_onStopDictation);
    on<UpdateTranscript>(_onUpdateTranscript);
    on<DictationErrorOccurred>(_onDictationErrorOccurred);
  }

  Future<void> _onStartDictation(StartDictation event, Emitter<DictationState> emit) async {
    emit(state.copyWith(isDictating: true, status: DictationStatus.listening, errorMessage: ''));
    try {
      await _sttService.startListening(
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
    emit(state.copyWith(transcript: event.transcript, status: DictationStatus.listening));
  }

  void _onDictationErrorOccurred(DictationErrorOccurred event, Emitter<DictationState> emit) {
    emit(state.copyWith(
      isDictating: false,
      status: DictationStatus.error,
      errorMessage: event.errorMessage,
    ));
  }
}
