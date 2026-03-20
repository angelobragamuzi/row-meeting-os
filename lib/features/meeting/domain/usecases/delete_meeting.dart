import '../repositories/meeting_repository.dart';

class DeleteMeeting {
  const DeleteMeeting(this._repository);

  final MeetingRepository _repository;

  Future<void> call(String meetingId) {
    return _repository.deleteMeeting(meetingId);
  }
}
