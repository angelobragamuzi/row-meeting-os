import '../../domain/entities/meeting.dart';

class MeetingModel extends Meeting {
  const MeetingModel({
    required super.id,
    required super.audioPath,
    required super.transcription,
    required super.summary,
    required super.createdAt,
  });

  factory MeetingModel.fromEntity(Meeting meeting) {
    return MeetingModel(
      id: meeting.id,
      audioPath: meeting.audioPath,
      transcription: meeting.transcription,
      summary: meeting.summary,
      createdAt: meeting.createdAt,
    );
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    final summaryRaw = map['summary'];

    DateTime createdAt;
    if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt =
          DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now();
    }

    return MeetingModel(
      id: map['id']?.toString() ?? '',
      audioPath: map['audioPath']?.toString() ?? '',
      transcription: map['transcription']?.toString() ?? '',
      summary: summaryRaw is Map
          ? Map<String, dynamic>.from(summaryRaw)
          : <String, dynamic>{},
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audioPath': audioPath,
      'transcription': transcription,
      'summary': summary,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
