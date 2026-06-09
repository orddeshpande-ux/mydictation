import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'dictation_event.dart';
part 'dictation_state.dart';

class DictationBloc extends Bloc<DictationEvent, DictationState> {
  DictationBloc() : super(const DictationState.initial()) {
    on<StartDictation>(_onStartDictation);
    on<StopDictation>(_onStopDictation);
    on<UpdateTranscript>(_onUpdateTranscript);
  }

  void _onStartDictation(StartDictation event, Emitter<DictationState> emit) {
    emit(state.copyWith(isDictating: true, status: DictationStatus.listening));
  }

  void _onStopDictation(StopDictation event, Emitter<DictationState> emit) {
    emit(state.copyWith(isDictating: false, status: DictationStatus.idle));
  }

  void _onUpdateTranscript(UpdateTranscript event, Emitter<DictationState> emit) {
    emit(state.copyWith(transcript: event.transcript, status: DictationStatus.processing));
  }
}
