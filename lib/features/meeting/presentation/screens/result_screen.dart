import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/meeting.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final summary = meeting.summary;
    final contextText = (summary['contexto'] ?? summary['context'] ?? '')
        .toString()
        .trim();
    final topics = _asStringList(summary['topicos'] ?? summary['topics']);
    final decisions = _asStringList(
      summary['decisoes'] ?? summary['decisions'],
    );
    final taskDescriptions = _asTaskDescriptions(
      summary['tarefas'] ?? summary['tasks'],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ROW / RESULTADO')),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _HeaderCard(meeting: meeting),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'DESCRICAO',
              child: Text(
                contextText.isEmpty
                    ? 'Sem descricao identificada nesta reuniao.'
                    : contextText,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'TOPICOS',
              child: _StringListContent(
                items: topics,
                emptyText: 'Nenhum topico principal encontrado.',
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'DECISOES',
              child: _StringListContent(
                items: decisions,
                emptyText: 'Nenhuma decisao explicitada.',
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'TAREFAS',
              child: _TaskListContent(descriptions: taskDescriptions),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'TRANSCRICAO',
              child: Text(
                meeting.transcription.trim().isEmpty
                    ? 'Transcricao vazia.'
                    : meeting.transcription.trim(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _asStringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _asTaskDescriptions(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.where((item) => item != null).map((item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final description =
            (map['descricao'] ??
                    map['description'] ??
                    map['tarefa'] ??
                    map['task'] ??
                    '')
                .toString()
                .trim();
        return description.isEmpty ? 'Sem descricao' : description;
      }

      final task = item.toString().trim();
      return task.isEmpty ? 'Sem descricao' : task;
    }).toList();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(meeting.createdAt);
    final source = (meeting.summary['fonte'] ?? 'indefinido').toString();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF2B2B2B), width: 2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMO',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2B2B2B)),
          const SizedBox(height: 10),
          Text(date),
          const SizedBox(height: 4),
          Text(
            'FONTE: $source',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF2B2B2B), width: 2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2B2B2B)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StringListContent extends StatelessWidget {
  const _StringListContent({required this.items, required this.emptyText});

  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyText);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('> '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TaskListContent extends StatelessWidget {
  const _TaskListContent({required this.descriptions});

  final List<String> descriptions;

  @override
  Widget build(BuildContext context) {
    if (descriptions.isEmpty) {
      return const Text('Nenhuma tarefa identificada.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: descriptions
          .map(
            (description) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('[ ] '),
                  Expanded(child: Text(description)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
