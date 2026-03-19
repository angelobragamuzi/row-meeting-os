import '../repositories/meeting_repository.dart';

class StopRecording {
  const StopRecording(this._repository);

  final MeetingRepository _repository;

  Future<String> call() => _repository.stopRecording();
}
