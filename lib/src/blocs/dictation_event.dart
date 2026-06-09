part of 'dictation_bloc.dart';

abstract class DictationEvent extends Equatable {
  const DictationEvent();

  @override
  List<Object?> get props => [];
}

class StartDictation extends DictationEvent {}

class StopDictation extends DictationEvent {}

class UpdateTranscript extends DictationEvent {
  final String transcript;

  const UpdateTranscript(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

class DictationErrorOccurred extends DictationEvent {
  final String errorMessage;

  const DictationErrorOccurred(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

