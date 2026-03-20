import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/summary_assistant_type.dart';
import '../bloc/summary_assistant_cubit.dart';
import '../bloc/summary_assistant_state.dart';

const String discussionTopicsCacheKey = 'topicos_discussao';
const String actionTasksCacheKey = 'tarefas_sugeridas';
const String keyObservationsCacheKey = 'observacoes_importantes';

class SummaryAssistantScreen extends StatelessWidget {
  const SummaryAssistantScreen({super.key, required this.type});

  final SummaryAssistantType type;

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(type);
    final subtitle = _subtitleFor(type);

    return PopScope<Map<String, String>?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _popWithCurrentResult(
          context,
          context.read<SummaryAssistantCubit>().state,
        );
      },
      child: Scaffold(
        appBar: AppBar(titleSpacing: 18, title: Text(title)),
        body: SafeArea(
          child: BlocConsumer<SummaryAssistantCubit, SummaryAssistantState>(
            listener: (context, state) {
              if (state.status == SummaryAssistantStatus.failure &&
                  (state.errorMessage?.isNotEmpty ?? false)) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _AssistantOutputPanel(
                    title: title,
                    subtitle: subtitle,
                    type: type,
                    state: state,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              state.status == SummaryAssistantStatus.loading
                              ? null
                              : () => context
                                    .read<SummaryAssistantCubit>()
                                    .generate(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Gerar novamente'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              state.status == SummaryAssistantStatus.loading
                              ? null
                              : () => _popWithCurrentResult(context, state),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Voltar ao resumo'),
                        ),
                      ),
                    ],
                  ),
                  if (state.status == SummaryAssistantStatus.success)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: state.content),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Conteúdo copiado para a área de transferência.',
                                  ),
                                ),
                              );
                          }
                        },
                        icon: const Icon(Icons.content_copy_rounded),
                        label: const Text('Copiar conteúdo'),
                      ),
                    ),
                  if (type == SummaryAssistantType.fullPack &&
                      state.status == SummaryAssistantStatus.success)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton.icon(
                        onPressed: state.hasFullPack
                            ? () => _exportFullPackPdf(context)
                            : null,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar PDF'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _popWithCurrentResult(
    BuildContext context,
    SummaryAssistantState state,
  ) {
    Navigator.of(context).pop(_buildCachePayload(state));
  }

  Map<String, String>? _buildCachePayload(SummaryAssistantState state) {
    if (state.status != SummaryAssistantStatus.success) {
      return null;
    }

    switch (type) {
      case SummaryAssistantType.discussionTopics:
        final content = state.content.trim();
        if (content.isEmpty) {
          return null;
        }
        return {discussionTopicsCacheKey: content};
      case SummaryAssistantType.actionTasks:
        final content = state.content.trim();
        if (content.isEmpty) {
          return null;
        }
        return {actionTasksCacheKey: content};
      case SummaryAssistantType.keyObservations:
        final content = state.content.trim();
        if (content.isEmpty) {
          return null;
        }
        return {keyObservationsCacheKey: content};
      case SummaryAssistantType.fullPack:
        if (!state.hasFullPack) {
          return null;
        }
        return {
          discussionTopicsCacheKey: state.discussionTopics.trim(),
          actionTasksCacheKey: state.actionTasks.trim(),
          keyObservationsCacheKey: state.keyObservations.trim(),
        };
    }
  }

  Future<void> _exportFullPackPdf(BuildContext context) async {
    final cubit = context.read<SummaryAssistantCubit>();

    try {
      final result = await cubit.exportFullPackPdf();

      if (!context.mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      if (result.hasLocalPath) {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              'PDF exportado com sucesso.\nSalvo em:\n${result.localPath}',
            ),
          ),
        );
        return;
      }

      if (result.usedLocalFallback) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('PDF exportado localmente com sucesso.'),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('PDF enviado para impressão.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao exportar PDF: $error')),
        );
    }
  }

  String _titleFor(SummaryAssistantType type) {
    switch (type) {
      case SummaryAssistantType.discussionTopics:
        return 'Tópicos de discussão';
      case SummaryAssistantType.actionTasks:
        return 'Tarefas sugeridas';
      case SummaryAssistantType.keyObservations:
        return 'Observações importantes';
      case SummaryAssistantType.fullPack:
        return 'Pacote completo';
    }
  }

  String _subtitleFor(SummaryAssistantType type) {
    switch (type) {
      case SummaryAssistantType.discussionTopics:
        return 'Sugestões para guiar a próxima conversa da equipe.';
      case SummaryAssistantType.actionTasks:
        return 'Ações práticas criadas a partir do resumo da reunião.';
      case SummaryAssistantType.keyObservations:
        return 'Pontos de atenção, riscos e insights relevantes.';
      case SummaryAssistantType.fullPack:
        return 'Geração completa com tópicos, tarefas e observações.';
    }
  }
}

class _AssistantOutputPanel extends StatelessWidget {
  const _AssistantOutputPanel({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.state,
  });

  final String title;
  final String subtitle;
  final SummaryAssistantType type;
  final SummaryAssistantState state;

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
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB0B0B0)),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _contentForState(context),
          ),
        ],
      ),
    );
  }

  Widget _contentForState(BuildContext context) {
    switch (state.status) {
      case SummaryAssistantStatus.initial:
        return const Text(
          'Preparando geração de conteúdo...',
          key: ValueKey<String>('initial'),
        );
      case SummaryAssistantStatus.loading:
        return const _LoadingContent(key: ValueKey<String>('loading'));
      case SummaryAssistantStatus.failure:
        return Text(
          state.errorMessage ?? 'Não foi possível gerar o conteúdo.',
          key: const ValueKey<String>('failure'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFFFB4B4)),
        );
      case SummaryAssistantStatus.success:
        if (type == SummaryAssistantType.fullPack && state.hasFullPack) {
          return _FullPackContent(
            state: state,
            key: const ValueKey('full-pack'),
          );
        }

        return SelectableText(
          state.content,
          key: const ValueKey<String>('success'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
        );
    }
  }
}

class _FullPackContent extends StatelessWidget {
  const _FullPackContent({super.key, required this.state});

  final SummaryAssistantState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBlock(
          title: 'Tópicos de discussão',
          content: state.discussionTopics,
        ),
        const SizedBox(height: 12),
        _SectionBlock(title: 'Tarefas sugeridas', content: state.actionTasks),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'Observações importantes',
          content: state.keyObservations,
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFBDBDBD),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
          const SizedBox(height: 8),
          SelectableText(content),
        ],
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('loading-content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            minHeight: 3,
            color: Color(0xFFF2F2F2),
            backgroundColor: Color(0xFF2A2E37),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Consultando IA e estruturando resposta...',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFBDBDBD)),
        ),
      ],
    );
  }
}
