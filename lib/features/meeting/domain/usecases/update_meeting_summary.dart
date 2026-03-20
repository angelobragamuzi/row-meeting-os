import '../repositories/meeting_repository.dart';

class UpdateMeetingSummary {
  const UpdateMeetingSummary(this._repository);

  final MeetingRepository _repository;

  Future<void> call({
    required String meetingId,
    required Map<String, dynamic> summary,
  }) {
    return _repository.updateMeetingSummary(
      meetingId: meetingId,
      summary: summary,
    );
  }
}
