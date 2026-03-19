import 'package:equatable/equatable.dart';

import '../../domain/entities/meeting.dart';

enum ProcessingStage { transcribing, analyzing }

abstract class MeetingState extends Equatable {
  const MeetingState({this.meetings = const []});

  final List<Meeting> meetings;

  @override
  List<Object?> get props => [meetings];
}

class MeetingInitial extends MeetingState {
  const MeetingInitial();
}

class MeetingRecording extends MeetingState {
  const MeetingRecording({
    required this.isRecording,
    required this.elapsed,
    this.audioPath,
    super.meetings,
  });

  final bool isRecording;
  final Duration elapsed;
  final String? audioPath;

  MeetingRecording copyWith({
    bool? isRecording,
    Duration? elapsed,
    String? audioPath,
    List<Meeting>? meetings,
  }) {
    return MeetingRecording(
      isRecording: isRecording ?? this.isRecording,
      elapsed: elapsed ?? this.elapsed,
      audioPath: audioPath ?? this.audioPath,
      meetings: meetings ?? this.meetings,
    );
  }

  @override
  List<Object?> get props => [meetings, isRecording, elapsed, audioPath];
}

class MeetingProcessing extends MeetingState {
  const MeetingProcessing({
    required this.audioPath,
    required this.stage,
    super.meetings,
  });

  final String audioPath;
  final ProcessingStage stage;

  @override
  List<Object?> get props => [meetings, audioPath, stage];
}

class MeetingLoaded extends MeetingState {
  const MeetingLoaded({required super.meetings, this.selectedMeeting});

  final Meeting? selectedMeeting;

  @override
  List<Object?> get props => [meetings, selectedMeeting];
}

class MeetingError extends MeetingState {
  const MeetingError({required this.message, super.meetings});

  final String message;

  @override
  List<Object?> get props => [meetings, message];
}
