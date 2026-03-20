import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/pdf_export_result.dart';
import '../../domain/entities/summary_assistant_type.dart';
import '../../domain/usecases/export_summary_assistant_pdf.dart';
import '../../domain/usecases/generate_summary_assistant_content.dart';
import 'summary_assistant_state.dart';

class SummaryAssistantCubit extends Cubit<SummaryAssistantState> {
  SummaryAssistantCubit({
    required GenerateSummaryAssistantContent generateSummaryAssistantContent,
    required ExportSummaryAssistantPdf exportSummaryAssistantPdf,
    required this.summary,
    required this.type,
    this.cachedDiscussionTopics = '',
    this.cachedActionTasks = '',
    this.cachedKeyObservations = '',
  }) : _generateSummaryAssistantContent = generateSummaryAssistantContent,
       _exportSummaryAssistantPdf = exportSummaryAssistantPdf,
       super(const SummaryAssistantState());

  final GenerateSummaryAssistantContent _generateSummaryAssistantContent;
  final ExportSummaryAssistantPdf _exportSummaryAssistantPdf;
  final String summary;
  final SummaryAssistantType type;
  final String cachedDiscussionTopics;
  final String cachedActionTasks;
  final String cachedKeyObservations;

  Future<void> generate() async {
    emit(
      state.copyWith(
        status: SummaryAssistantStatus.loading,
        clearError: true,
        clearSections: true,
      ),
    );

    try {
      if (type == SummaryAssistantType.fullPack) {
        await _generateFullPack();
        return;
      }

      final cached = _cachedFor(type).trim();
      if (cached.isNotEmpty) {
        emit(_successWithTypeContent(content: cached, type: type));
        return;
      }

      final content = await _generateSummaryAssistantContent(
        summary: summary,
        type: type,
      );

      emit(_successWithTypeContent(content: content.trim(), type: type));
    } catch (error) {
      emit(
        state.copyWith(
          status: SummaryAssistantStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<PdfExportResult> exportFullPackPdf() async {
    if (!state.hasFullPack) {
      throw const AppException('Não há conteúdo para exportar no momento.');
    }

    return _exportSummaryAssistantPdf(
      discussionTopics: state.discussionTopics.trim(),
      actionTasks: state.actionTasks.trim(),
      keyObservations: state.keyObservations.trim(),
    );
  }

  Future<void> _generateFullPack() async {
    var topics = cachedDiscussionTopics.trim();
    var tasks = cachedActionTasks.trim();
    var observations = cachedKeyObservations.trim();

    if (topics.isEmpty) {
      topics = (await _generateSummaryAssistantContent(
        summary: summary,
        type: SummaryAssistantType.discussionTopics,
      )).trim();
    }

    if (tasks.isEmpty) {
      tasks = (await _generateSummaryAssistantContent(
        summary: summary,
        type: SummaryAssistantType.actionTasks,
      )).trim();
    }

    if (observations.isEmpty) {
      observations = (await _generateSummaryAssistantContent(
        summary: summary,
        type: SummaryAssistantType.keyObservations,
      )).trim();
    }

    final content = _composeFullPack(
      topics: topics,
      tasks: tasks,
      observations: observations,
    );

    emit(
      state.copyWith(
        status: SummaryAssistantStatus.success,
        content: content,
        discussionTopics: topics,
        actionTasks: tasks,
        keyObservations: observations,
        clearError: true,
      ),
    );
  }

  SummaryAssistantState _successWithTypeContent({
    required String content,
    required SummaryAssistantType type,
  }) {
    switch (type) {
      case SummaryAssistantType.discussionTopics:
        return state.copyWith(
          status: SummaryAssistantStatus.success,
          content: content,
          discussionTopics: content,
          clearError: true,
        );
      case SummaryAssistantType.actionTasks:
        return state.copyWith(
          status: SummaryAssistantStatus.success,
          content: content,
          actionTasks: content,
          clearError: true,
        );
      case SummaryAssistantType.keyObservations:
        return state.copyWith(
          status: SummaryAssistantStatus.success,
          content: content,
          keyObservations: content,
          clearError: true,
        );
      case SummaryAssistantType.fullPack:
        return state.copyWith(
          status: SummaryAssistantStatus.success,
          content: content,
          clearError: true,
        );
    }
  }

  String _cachedFor(SummaryAssistantType type) {
    switch (type) {
      case SummaryAssistantType.discussionTopics:
        return cachedDiscussionTopics;
      case SummaryAssistantType.actionTasks:
        return cachedActionTasks;
      case SummaryAssistantType.keyObservations:
        return cachedKeyObservations;
      case SummaryAssistantType.fullPack:
        return '';
    }
  }

  String _composeFullPack({
    required String topics,
    required String tasks,
    required String observations,
  }) {
    return 'TÓPICOS DE DISCUSSÃO\n$topics\n\n'
        'TAREFAS SUGERIDAS\n$tasks\n\n'
        'OBSERVAÇÕES IMPORTANTES\n$observations';
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Erro inesperado: $error';
  }
}
