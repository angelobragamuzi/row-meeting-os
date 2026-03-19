import '../repositories/meeting_repository.dart';

class TranscribeMeeting {
  const TranscribeMeeting(this._repository);

  final MeetingRepository _repository;

  Future<String> call(String audioPath) => _repository.transcribe(audioPath);
}
