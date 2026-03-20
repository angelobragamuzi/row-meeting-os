import '../entities/image_export_result.dart';

abstract class ImageExportService {
  Future<ImageExportResult> exportSummaryAssistantImage({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  });
}
