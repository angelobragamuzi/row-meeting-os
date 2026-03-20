import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/summary_assistant_type.dart';
import '../../domain/usecases/export_summary_assistant_pdf.dart';
import '../../domain/usecases/generate_summary_assistant_content.dart';
import '../../domain/usecases/update_meeting_summary.dart';
import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/summary_assistant_cubit.dart';
import 'summary_assistant_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Map<String, dynamic> _summary;
  late Map<String, String> _actionsCache;

  @override
  void initState() {
    super.initState();
    _summary = Map<String, dynamic>.from(widget.meeting.summary);
    _actionsCache = _extractActionsCache(_summary['acoes']);
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(widget.meeting.createdAt);
    final summaryText = _resolveSummaryText();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: Text(
          createdAt,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFDBDBDB),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir reunião',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _SummaryPanel(summaryText: summaryText),
            const SizedBox(height: 16),
            _AssistantActionsPanel(
              onDiscussionTopics: () => _openAssistant(
                context,
                type: SummaryAssistantType.discussionTopics,
                summary: summaryText,
              ),
              onActionTasks: () => _openAssistant(
                context,
                type: SummaryAssistantType.actionTasks,
                summary: summaryText,
              ),
              onKeyObservations: () => _openAssistant(
                context,
                type: SummaryAssistantType.keyObservations,
                summary: summaryText,
              ),
              onFullPack: () => _openAssistant(
                context,
                type: SummaryAssistantType.fullPack,
                summary: summaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveSummaryText() {
    final summary =
        (_summary['resumo'] ??
                _summary['summary'] ??
                _summary['contexto'] ??
                _summary['context'])
            .toString()
            .trim();

    if (summary.isNotEmpty) {
      return summary;
    }

    return 'Resumo indisponível para esta reunião.';
  }

  Future<void> _openAssistant(
    BuildContext context, {
    required SummaryAssistantType type,
    required String summary,
  }) async {
    final generateUseCase = context.read<GenerateSummaryAssistantContent>();
    final exportPdfUseCase = context.read<ExportSummaryAssistantPdf>();

    final generatedCache = await Navigator.of(context)
        .push<Map<String, String>>(
          PageRouteBuilder<Map<String, String>>(
            transitionDuration: const Duration(milliseconds: 420),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (context, animation, secondaryAnimation) {
              return BlocProvider<SummaryAssistantCubit>(
                create: (_) => SummaryAssistantCubit(
                  generateSummaryAssistantContent: generateUseCase,
                  exportSummaryAssistantPdf: exportPdfUseCase,
                  summary: summary,
                  type: type,
                  cachedDiscussionTopics:
                      _actionsCache[discussionTopicsCacheKey] ?? '',
                  cachedActionTasks: _actionsCache[actionTasksCacheKey] ?? '',
                  cachedKeyObservations:
                      _actionsCache[keyObservationsCacheKey] ?? '',
                )..generate(),
                child: SummaryAssistantScreen(type: type),
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );

                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.025),
                    end: Offset.zero,
                  ).animate(curved);

                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
          ),
        );

    if (!mounted || generatedCache == null || generatedCache.isEmpty) {
      return;
    }

    setState(() {
      _actionsCache.addAll(generatedCache);
      _summary['acoes'] = Map<String, dynamic>.from(_actionsCache);
    });

    await _persistActionsCache();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Ação gerada e salva localmente.')),
      );
  }

  Future<void> _persistActionsCache() async {
    final updateMeetingSummary = context.read<UpdateMeetingSummary>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await updateMeetingSummary(
        meetingId: widget.meeting.id,
        summary: _summary,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao salvar ação localmente: $error')),
        );
    }
  }

  Map<String, String> _extractActionsCache(dynamic raw) {
    if (raw is! Map) {
      return <String, String>{};
    }

    final map = Map<String, dynamic>.from(raw);
    return {
      if ((map[discussionTopicsCacheKey] ?? '').toString().trim().isNotEmpty)
        discussionTopicsCacheKey: (map[discussionTopicsCacheKey] ?? '')
            .toString()
            .trim(),
      if ((map[actionTasksCacheKey] ?? '').toString().trim().isNotEmpty)
        actionTasksCacheKey: (map[actionTasksCacheKey] ?? '').toString().trim(),
      if ((map[keyObservationsCacheKey] ?? '').toString().trim().isNotEmpty)
        keyObservationsCacheKey: (map[keyObservationsCacheKey] ?? '')
            .toString()
            .trim(),
    };
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) {
        return const _DeleteMeetingDialog();
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<MeetingBloc>().add(MeetingDeleted(widget.meeting.id));
      Navigator.of(context).pop();
    }
  }
}

class _DeleteMeetingDialog extends StatelessWidget {
  const _DeleteMeetingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    border: Border.all(
                      color: const Color(0xFF3A3A3A),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFF2F2F2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'EXCLUIR REUNIÃO',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
            const SizedBox(height: 12),
            Text(
              'Você está prestes a remover esta reunião do dispositivo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Esta ação é permanente e não pode ser desfeita.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB8B8B8)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF3A3A3A),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: const Color(0xFF111111),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.summaryText});

  final String summaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMO DA REUNIÃO',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
          const SizedBox(height: 12),
          SelectableText(
            summaryText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AssistantActionsPanel extends StatelessWidget {
  const _AssistantActionsPanel({
    required this.onDiscussionTopics,
    required this.onActionTasks,
    required this.onKeyObservations,
    required this.onFullPack,
  });

  final VoidCallback onDiscussionTopics;
  final VoidCallback onActionTasks;
  final VoidCallback onKeyObservations;
  final VoidCallback onFullPack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AÇÕES',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
          const SizedBox(height: 12),
          _ActionButton(
            onTap: onDiscussionTopics,
            icon: Icons.forum_outlined,
            title: 'Gerar tópicos de discussão',
            subtitle: 'Cria pontos para conduzir a próxima reunião.',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onTap: onActionTasks,
            icon: Icons.task_alt,
            title: 'Criar tarefas a partir do resumo',
            subtitle: 'Transforma o conteúdo em ações objetivas.',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onTap: onKeyObservations,
            icon: Icons.visibility_outlined,
            title: 'Extrair observações importantes',
            subtitle: 'Destaca riscos, atenção e insights da reunião.',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onTap: onFullPack,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Gerar tudo + exportar PDF',
            subtitle: 'Produz tópicos, tarefas e observações em um fluxo só.',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFFEDEDED)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB6B6B6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFEDEDED),
            ),
          ],
        ),
      ),
    );
  }
}
