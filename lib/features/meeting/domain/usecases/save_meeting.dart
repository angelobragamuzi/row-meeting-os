import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class SaveMeeting {
  const SaveMeeting(this._repository);

  final MeetingRepository _repository;

  Future<Meeting> call({
    required String audioPath,
    required String transcription,
    required Map<String, dynamic> summary,
  }) {
    return _repository.saveMeeting(
      audioPath: audioPath,
      transcription: transcription,
      summary: summary,
    );
  }
}
