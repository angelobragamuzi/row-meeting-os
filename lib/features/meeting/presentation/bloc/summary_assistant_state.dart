import 'package:equatable/equatable.dart';

enum SummaryAssistantStatus { initial, loading, success, failure }

class SummaryAssistantState extends Equatable {
  const SummaryAssistantState({
    this.status = SummaryAssistantStatus.initial,
    this.content = '',
    this.errorMessage,
    this.discussionTopics = '',
    this.actionTasks = '',
    this.keyObservations = '',
  });

  final SummaryAssistantStatus status;
  final String content;
  final String? errorMessage;
  final String discussionTopics;
  final String actionTasks;
  final String keyObservations;

  bool get hasFullPack =>
      discussionTopics.isNotEmpty &&
      actionTasks.isNotEmpty &&
      keyObservations.isNotEmpty;

  SummaryAssistantState copyWith({
    SummaryAssistantStatus? status,
    String? content,
    String? errorMessage,
    String? discussionTopics,
    String? actionTasks,
    String? keyObservations,
    bool clearError = false,
    bool clearSections = false,
  }) {
    return SummaryAssistantState(
      status: status ?? this.status,
      content: content ?? this.content,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      discussionTopics: clearSections
          ? ''
          : discussionTopics ?? this.discussionTopics,
      actionTasks: clearSections ? '' : actionTasks ?? this.actionTasks,
      keyObservations: clearSections
          ? ''
          : keyObservations ?? this.keyObservations,
    );
  }

  @override
  List<Object?> get props => [
    status,
    content,
    errorMessage,
    discussionTopics,
    actionTasks,
    keyObservations,
  ];
}
