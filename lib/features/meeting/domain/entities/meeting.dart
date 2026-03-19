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

  List<String> get topics =>
      _asStringList(summary['topicos'] ?? summary['topics']);
  List<String> get decisions =>
      _asStringList(summary['decisoes'] ?? summary['decisions']);

  List<Map<String, String>> get tasks =>
      _asTaskList(summary['tarefas'] ?? summary['tasks']);

  String get context =>
      (summary['contexto'] ?? summary['context'] ?? '').toString().trim();

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

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<Map<String, String>> _asTaskList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.where((item) => item != null).map((item) {
      if (item is Map) {
        final normalized = Map<String, dynamic>.from(item);
        final description =
            (normalized['descricao'] ??
                    normalized['description'] ??
                    normalized['tarefa'] ??
                    normalized['task'] ??
                    '')
                .toString()
                .trim();

        final owner =
            (normalized['responsavel'] ??
                    normalized['owner'] ??
                    normalized['responsible'] ??
                    'Nao definido')
                .toString()
                .trim();

        return {
          'descricao': description.isEmpty ? 'Sem descricao' : description,
          'responsavel': owner.isEmpty ? 'Nao definido' : owner,
        };
      }

      final text = item.toString().trim();
      return {
        'descricao': text.isEmpty ? 'Sem descricao' : text,
        'responsavel': 'Nao definido',
      };
    }).toList();
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
