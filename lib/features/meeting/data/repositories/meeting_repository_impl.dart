import '../../domain/entities/meeting.dart';
import '../../domain/entities/pdf_export_result.dart';
import '../../domain/entities/summary_assistant_type.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../../domain/services/pdf_export_service.dart';
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
    required PdfExportService pdfExportService,
  }) : _audioRecorderDataSource = audioRecorderDataSource,
       _localMeetingDataSource = localMeetingDataSource,
       _transcriptionService = transcriptionService,
       _summaryService = summaryService,
       _pdfExportService = pdfExportService;

  final AudioRecorderDataSource _audioRecorderDataSource;
  final LocalMeetingDataSource _localMeetingDataSource;
  final TranscriptionService _transcriptionService;
  final SummaryService _summaryService;
  final PdfExportService _pdfExportService;

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
  Future<String> generateFromSummary({
    required String summary,
    required SummaryAssistantType type,
  }) {
    return _summaryService.generateFromSummary(summary: summary, type: type);
  }

  @override
  Future<PdfExportResult> exportSummaryAssistantPdf({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  }) {
    return _pdfExportService.exportSummaryAssistantPdf(
      discussionTopics: discussionTopics,
      actionTasks: actionTasks,
      keyObservations: keyObservations,
    );
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
  Future<void> updateMeetingSummary({
    required String meetingId,
    required Map<String, dynamic> summary,
  }) {
    return _localMeetingDataSource.updateMeetingSummary(
      meetingId: meetingId,
      summary: summary,
    );
  }

  @override
  Future<void> deleteMeeting(String meetingId) {
    return _localMeetingDataSource.deleteMeeting(meetingId);
  }

  @override
  Future<void> dispose() => _audioRecorderDataSource.dispose();
}
