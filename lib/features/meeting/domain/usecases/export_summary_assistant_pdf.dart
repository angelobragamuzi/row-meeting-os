import '../entities/pdf_export_result.dart';
import '../repositories/meeting_repository.dart';

class ExportSummaryAssistantPdf {
  const ExportSummaryAssistantPdf(this._repository);

  final MeetingRepository _repository;

  Future<PdfExportResult> call({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  }) {
    return _repository.exportSummaryAssistantPdf(
      discussionTopics: discussionTopics,
      actionTasks: actionTasks,
      keyObservations: keyObservations,
    );
  }
}
