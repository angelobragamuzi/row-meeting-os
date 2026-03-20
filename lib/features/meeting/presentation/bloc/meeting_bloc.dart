import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/usecases/get_meetings.dart';
import '../../domain/usecases/delete_meeting.dart';
import '../../domain/usecases/save_meeting.dart';
import '../../domain/usecases/start_recording.dart';
import '../../domain/usecases/stop_recording.dart';
import '../../domain/usecases/summarize_meeting.dart';
import '../../domain/usecases/transcribe_meeting.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  MeetingBloc({
    required GetMeetings getMeetings,
    required StartRecording startRecording,
    required StopRecording stopRecording,
    required TranscribeMeeting transcribeMeeting,
    required SummarizeMeeting summarizeMeeting,
    required SaveMeeting saveMeeting,
    required DeleteMeeting deleteMeeting,
  }) : _getMeetings = getMeetings,
       _startRecording = startRecording,
       _stopRecording = stopRecording,
       _transcribeMeeting = transcribeMeeting,
       _summarizeMeeting = summarizeMeeting,
       _saveMeeting = saveMeeting,
       _deleteMeeting = deleteMeeting,
       super(const MeetingInitial()) {
    on<MeetingsRequested>(_onMeetingsRequested);
    on<RecordingStarted>(_onRecordingStarted);
    on<RecordingStopped>(_onRecordingStopped);
    on<RecordingTicked>(_onRecordingTicked);
    on<MeetingFinalized>(_onMeetingFinalized);
    on<MeetingSelectionCleared>(_onMeetingSelectionCleared);
    on<MeetingDeleted>(_onMeetingDeleted);
  }

  final GetMeetings _getMeetings;
  final StartRecording _startRecording;
  final StopRecording _stopRecording;
  final TranscribeMeeting _transcribeMeeting;
  final SummarizeMeeting _summarizeMeeting;
  final SaveMeeting _saveMeeting;
  final DeleteMeeting _deleteMeeting;

  Timer? _timer;
  String? _recordingPath;
  List<Meeting> _cachedMeetings = const [];

  Future<void> _onMeetingsRequested(
    MeetingsRequested event,
    Emitter<MeetingState> emit,
  ) async {
    try {
      _cachedMeetings = await _getMeetings();
      emit(MeetingLoaded(meetings: _cachedMeetings));
    } catch (error) {
      emit(MeetingError(message: _mapError(error), meetings: _cachedMeetings));
    }
  }

  Future<void> _onRecordingStarted(
    RecordingStarted event,
    Emitter<MeetingState> emit,
  ) async {
    if (state is MeetingRecording && (state as MeetingRecording).isRecording) {
      return;
    }

    try {
      final path = await _startRecording();
      _recordingPath = path;

      _startTimer();
      emit(
        MeetingRecording(
          isRecording: true,
          elapsed: Duration.zero,
          audioPath: path,
          meetings: _cachedMeetings,
        ),
      );
    } catch (error) {
      emit(MeetingError(message: _mapError(error), meetings: _cachedMeetings));
    }
  }

  Future<void> _onRecordingStopped(
    RecordingStopped event,
    Emitter<MeetingState> emit,
  ) async {
    final current = state;
    if (current is! MeetingRecording || !current.isRecording) {
      return;
    }

    try {
      final path = await _stopRecording();
      _recordingPath = path;

      _stopTimer();
      emit(current.copyWith(isRecording: false, audioPath: path));
    } catch (error) {
      emit(MeetingError(message: _mapError(error), meetings: _cachedMeetings));
    }
  }

  void _onRecordingTicked(RecordingTicked event, Emitter<MeetingState> emit) {
    final current = state;
    if (current is! MeetingRecording || !current.isRecording) {
      return;
    }

    emit(current.copyWith(elapsed: event.elapsed));
  }

  Future<void> _onMeetingFinalized(
    MeetingFinalized event,
    Emitter<MeetingState> emit,
  ) async {
    final current = state;
    if (current is! MeetingRecording) {
      emit(
        MeetingError(
          message: 'Inicie e finalize uma gravação antes de processar.',
          meetings: _cachedMeetings,
        ),
      );
      return;
    }

    try {
      var audioPath = current.audioPath ?? _recordingPath;

      if (current.isRecording) {
        audioPath = await _stopRecording();
      }

      if (audioPath == null || audioPath.trim().isEmpty) {
        throw const AppException(
          'Arquivo de áudio inválido para processamento.',
        );
      }

      _stopTimer();

      emit(
        MeetingProcessing(
          audioPath: audioPath,
          stage: ProcessingStage.transcribing,
          meetings: _cachedMeetings,
        ),
      );

      final transcription = await _transcribeMeeting(audioPath);

      emit(
        MeetingProcessing(
          audioPath: audioPath,
          stage: ProcessingStage.analyzing,
          meetings: _cachedMeetings,
        ),
      );

      final summary = await _summarizeMeeting(transcription);

      final savedMeeting = await _saveMeeting(
        audioPath: audioPath,
        transcription: transcription,
        summary: summary,
      );

      _cachedMeetings = [savedMeeting, ..._cachedMeetings];
      _recordingPath = null;

      emit(
        MeetingLoaded(meetings: _cachedMeetings, selectedMeeting: savedMeeting),
      );
    } catch (error) {
      emit(MeetingError(message: _mapError(error), meetings: _cachedMeetings));
    }
  }

  void _onMeetingSelectionCleared(
    MeetingSelectionCleared event,
    Emitter<MeetingState> emit,
  ) {
    emit(MeetingLoaded(meetings: _cachedMeetings));
  }

  Future<void> _onMeetingDeleted(
    MeetingDeleted event,
    Emitter<MeetingState> emit,
  ) async {
    try {
      await _deleteMeeting(event.meetingId);
      _cachedMeetings = _cachedMeetings
          .where((meeting) => meeting.id != event.meetingId)
          .toList();
      emit(MeetingLoaded(meetings: _cachedMeetings));
    } catch (error) {
      emit(MeetingError(message: _mapError(error), meetings: _cachedMeetings));
    }
  }

  void _startTimer() {
    _stopTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(RecordingTicked(Duration(seconds: timer.tick)));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return 'Erro inesperado: $error';
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
