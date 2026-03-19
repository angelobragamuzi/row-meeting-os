import '../repositories/meeting_repository.dart';

class StartRecording {
  const StartRecording(this._repository);

  final MeetingRepository _repository;

  Future<String> call() => _repository.startRecording();
}
