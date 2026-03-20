import 'package:hive/hive.dart';

import '../models/meeting_model.dart';

class LocalMeetingDataSource {
  static const String _boxName = 'meetings_box_v1';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> get _safeBox {
    final box = _box;
    if (box == null) {
      throw StateError('LocalMeetingDataSource não foi inicializado.');
    }
    return box;
  }

  Future<List<MeetingModel>> getMeetings() async {
    final meetings = <MeetingModel>[];

    for (final raw in _safeBox.values) {
      if (raw is Map) {
        meetings.add(MeetingModel.fromMap(Map<String, dynamic>.from(raw)));
      }
    }

    meetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return meetings;
  }

  Future<void> saveMeeting(MeetingModel meeting) async {
    await _safeBox.put(meeting.id, meeting.toMap());
  }

  Future<void> updateMeetingSummary({
    required String meetingId,
    required Map<String, dynamic> summary,
  }) async {
    final current = _safeBox.get(meetingId);
    if (current is! Map) {
      return;
    }

    final data = Map<String, dynamic>.from(current);
    data['summary'] = summary;
    await _safeBox.put(meetingId, data);
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _safeBox.delete(meetingId);
  }
}
