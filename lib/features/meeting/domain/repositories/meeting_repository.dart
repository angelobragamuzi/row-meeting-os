import '../entities/meeting.dart';
import '../entities/image_export_result.dart';
import '../entities/pdf_export_result.dart';
import '../entities/summary_assistant_type.dart';

abstract class MeetingRepository {
  Future<List<Meeting>> getMeetings();

  Future<String> startRecording();

  Future<String> stopRecording();

  Future<String> transcribe(String audioPath);

  Future<Map<String, dynamic>> summarize(String transcription);

  Future<String> generateFromSummary({
    required String summary,
    required SummaryAssistantType type,
  });

  Future<PdfExportResult> exportSummaryAssistantPdf({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  });

  Future<ImageExportResult> exportSummaryAssistantImage({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  });

  Future<Meeting> saveMeeting({
    required String audioPath,
    required String transcription,
    required Map<String, dynamic> summary,
  });

  Future<void> updateMeetingSummary({
    required String meetingId,
    required Map<String, dynamic> summary,
  });

  Future<void> deleteMeeting(String meetingId);

  Future<void> dispose();
}
