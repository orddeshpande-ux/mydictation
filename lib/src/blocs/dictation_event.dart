part of 'dictation_bloc.dart';

abstract class DictationEvent extends Equatable {
  const DictationEvent();

  @override
  List<Object?> get props => [];
}

class StartDictation extends DictationEvent {
  final String? localeId;

  const StartDictation({this.localeId});

  @override
  List<Object?> get props => [localeId];
}

class StopDictation extends DictationEvent {}

class CleanTranscription extends DictationEvent {}

class GenerateInsights extends DictationEvent {
  final DomainMode mode;

  const GenerateInsights(this.mode);

  @override
  List<Object?> get props => [mode];
}

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

class CleanAndGenerateInsights extends DictationEvent {
  final DomainMode mode;

  const CleanAndGenerateInsights(this.mode);

  @override
  List<Object?> get props => [mode];
}

