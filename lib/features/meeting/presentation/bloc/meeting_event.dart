import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => const [];
}

class MeetingsRequested extends MeetingEvent {
  const MeetingsRequested();
}

class RecordingStarted extends MeetingEvent {
  const RecordingStarted();
}

class RecordingStopped extends MeetingEvent {
  const RecordingStopped();
}

class RecordingTicked extends MeetingEvent {
  const RecordingTicked(this.elapsed);

  final Duration elapsed;

  @override
  List<Object?> get props => [elapsed];
}

class MeetingFinalized extends MeetingEvent {
  const MeetingFinalized();
}

class MeetingSelectionCleared extends MeetingEvent {
  const MeetingSelectionCleared();
}

class MeetingDeleted extends MeetingEvent {
  const MeetingDeleted(this.meetingId);

  final String meetingId;

  @override
  List<Object?> get props => [meetingId];
}
