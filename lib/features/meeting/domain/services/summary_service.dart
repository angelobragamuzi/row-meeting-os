import '../entities/summary_assistant_type.dart';

abstract class SummaryService {
  Future<Map<String, dynamic>> summarize(String transcription);

  Future<String> generateFromSummary({
    required String summary,
    required SummaryAssistantType type,
  });
}
