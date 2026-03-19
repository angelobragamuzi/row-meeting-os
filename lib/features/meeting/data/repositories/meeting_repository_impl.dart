import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../../domain/services/summary_service.dart';
import '../../domain/services/transcription_service.dart';
import '../datasources/audio_recorder_data_source.dart';
import '../datasources/local_meeting_data_source.dart';
import '../models/meeting_model.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  MeetingRepositoryImpl({
    required AudioRecorderDataSource audioRecorderDataSource,
    required LocalMeetingDataSource localMeetingDataSource,
    required TranscriptionService transcriptionService,
    required SummaryService summaryService,
  }) : _audioRecorderDataSource = audioRecorderDataSource,
       _localMeetingDataSource = localMeetingDataSource,
       _transcriptionService = transcriptionService,
       _summaryService = summaryService;

  final AudioRecorderDataSource _audioRecorderDataSource;
  final LocalMeetingDataSource _localMeetingDataSource;
  final TranscriptionService _transcriptionService;
  final SummaryService _summaryService;

  @override
  Future<List<Meeting>> getMeetings() => _localMeetingDataSource.getMeetings();

  @override
  Future<String> startRecording() => _audioRecorderDataSource.startRecording();

  @override
  Future<String> stopRecording() => _audioRecorderDataSource.stopRecording();

  @override
  Future<String> transcribe(String audioPath) {
    return _transcriptionService.transcribe(audioPath);
  }

  @override
  Future<Map<String, dynamic>> summarize(String transcription) {
    return _summaryService.summarize(transcription);
  }

  @override
  Future<Meeting> saveMeeting({
    required String audioPath,
    required String transcription,
    required Map<String, dynamic> summary,
  }) async {
    final meeting = MeetingModel(
      id: 'meeting_${DateTime.now().microsecondsSinceEpoch}',
      audioPath: audioPath,
      transcription: transcription,
      summary: summary,
      createdAt: DateTime.now(),
    );

    await _localMeetingDataSource.saveMeeting(meeting);
    return meeting;
  }

  @override
  Future<void> dispose() => _audioRecorderDataSource.dispose();
}
