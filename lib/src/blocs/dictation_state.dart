part of 'dictation_bloc.dart';

enum DictationStatus { idle, listening, processing, error }

class DictationState extends Equatable {
  final bool isDictating;
  final DictationStatus status;
  final String transcript;
  final String errorMessage;

  const DictationState({
    required this.isDictating,
    required this.status,
    required this.transcript,
    required this.errorMessage,
  });

  const DictationState.initial()
      : isDictating = false,
        status = DictationStatus.idle,
        transcript = '',
        errorMessage = '';

  DictationState copyWith({
    bool? isDictating,
    DictationStatus? status,
    String? transcript,
    String? errorMessage,
  }) {
    return DictationState(
      isDictating: isDictating ?? this.isDictating,
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isDictating, status, transcript, errorMessage];
}
