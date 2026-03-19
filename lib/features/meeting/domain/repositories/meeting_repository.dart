import '../entities/meeting.dart';

abstract class MeetingRepository {
  Future<List<Meeting>> getMeetings();

  Future<String> startRecording();

  Future<String> stopRecording();

  Future<String> transcribe(String audioPath);

  Future<Map<String, dynamic>> summarize(String transcription);

  Future<Meeting> saveMeeting({
    required String audioPath,
    required String transcription,
    required Map<String, dynamic> summary,
  });

  Future<void> dispose();
}
