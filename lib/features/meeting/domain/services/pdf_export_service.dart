import '../entities/pdf_export_result.dart';

abstract class PdfExportService {
  Future<PdfExportResult> exportSummaryAssistantPdf({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  });
}
