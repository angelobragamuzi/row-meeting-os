import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class GetMeetings {
  const GetMeetings(this._repository);

  final MeetingRepository _repository;

  Future<List<Meeting>> call() => _repository.getMeetings();
}
