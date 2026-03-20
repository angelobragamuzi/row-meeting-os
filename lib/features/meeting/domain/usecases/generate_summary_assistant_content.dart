import '../entities/summary_assistant_type.dart';
import '../repositories/meeting_repository.dart';

class GenerateSummaryAssistantContent {
  const GenerateSummaryAssistantContent(this._repository);

  final MeetingRepository _repository;

  Future<String> call({
    required String summary,
    required SummaryAssistantType type,
  }) {
    return _repository.generateFromSummary(summary: summary, type: type);
  }
}
