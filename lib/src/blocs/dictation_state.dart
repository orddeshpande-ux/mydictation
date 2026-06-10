part of 'dictation_bloc.dart';

enum DictationStatus { idle, listening, processing, error }

class Insight extends Equatable {
  final String title;
  final String message;
  final String type;

  const Insight({required this.title, required this.message, required this.type});

  @override
  List<Object?> get props => [title, message, type];
}

class DictationState extends Equatable {
  final bool isDictating;
  final DictationStatus status;
  final String transcript;
  final String errorMessage;
  final List<Insight> insights;

  const DictationState({
    required this.isDictating,
    required this.status,
    required this.transcript,
    required this.errorMessage,
    required this.insights,
  });

  const DictationState.initial()
      : isDictating = false,
        status = DictationStatus.idle,
        transcript = '',
        errorMessage = '',
        insights = const [];

  DictationState copyWith({
    bool? isDictating,
    DictationStatus? status,
    String? transcript,
    String? errorMessage,
    List<Insight>? insights,
  }) {
    return DictationState(
      isDictating: isDictating ?? this.isDictating,
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      errorMessage: errorMessage ?? this.errorMessage,
      insights: insights ?? this.insights,
    );
  }

  @override
  List<Object?> get props => [isDictating, status, transcript, errorMessage, insights];
}
