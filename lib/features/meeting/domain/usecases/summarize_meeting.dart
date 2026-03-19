import '../repositories/meeting_repository.dart';

class SummarizeMeeting {
  const SummarizeMeeting(this._repository);

  final MeetingRepository _repository;

  Future<Map<String, dynamic>> call(String transcription) {
    return _repository.summarize(transcription);
  }
}
