import 'dart:convert';

import 'package:equatable/equatable.dart';

class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.audioPath,
    required this.transcription,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String audioPath;
  final String transcription;
  final Map<String, dynamic> summary;
  final DateTime createdAt;

  String get context =>
      (summary['resumo'] ?? summary['contexto'] ?? summary['context'] ?? '')
          .toString()
          .trim();

  Meeting copyWith({
    String? id,
    String? audioPath,
    String? transcription,
    Map<String, dynamic>? summary,
    DateTime? createdAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      audioPath: audioPath ?? this.audioPath,
      transcription: transcription ?? this.transcription,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    audioPath,
    transcription,
    createdAt,
    jsonEncode(summary),
  ];
}
