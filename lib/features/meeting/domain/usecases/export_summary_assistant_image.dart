import '../entities/image_export_result.dart';
import '../repositories/meeting_repository.dart';

class ExportSummaryAssistantImage {
  const ExportSummaryAssistantImage(this._repository);

  final MeetingRepository _repository;

  Future<ImageExportResult> call({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  }) {
    return _repository.exportSummaryAssistantImage(
      discussionTopics: discussionTopics,
      actionTasks: actionTasks,
      keyObservations: keyObservations,
    );
  }
}
