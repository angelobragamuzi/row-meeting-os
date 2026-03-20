import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../features/meeting/data/datasources/audio_recorder_data_source.dart';
import '../../features/meeting/data/datasources/local_meeting_data_source.dart';
import '../../features/meeting/data/repositories/meeting_repository_impl.dart';
import '../../features/meeting/data/services/gemini_service.dart';
import '../../features/meeting/data/services/gemini_transcription_service.dart';
import '../../features/meeting/data/services/pdf_export_service_impl.dart';
import '../../features/meeting/domain/repositories/meeting_repository.dart';
import '../../features/meeting/domain/usecases/delete_meeting.dart';
import '../../features/meeting/domain/usecases/export_summary_assistant_pdf.dart';
import '../../features/meeting/domain/usecases/generate_summary_assistant_content.dart';
import '../../features/meeting/domain/usecases/get_meetings.dart';
import '../../features/meeting/domain/usecases/save_meeting.dart';
import '../../features/meeting/domain/usecases/start_recording.dart';
import '../../features/meeting/domain/usecases/stop_recording.dart';
import '../../features/meeting/domain/usecases/summarize_meeting.dart';
import '../../features/meeting/domain/usecases/transcribe_meeting.dart';
import '../../features/meeting/domain/usecases/update_meeting_summary.dart';
import '../../features/meeting/presentation/bloc/meeting_bloc.dart';

class AppDependencies {
  AppDependencies._({
    required this.meetingRepository,
    required this.meetingBloc,
    required this.generateSummaryAssistantContent,
    required this.exportSummaryAssistantPdf,
    required this.updateMeetingSummary,
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  final MeetingRepository meetingRepository;
  final MeetingBloc meetingBloc;
  final GenerateSummaryAssistantContent generateSummaryAssistantContent;
  final ExportSummaryAssistantPdf exportSummaryAssistantPdf;
  final UpdateMeetingSummary updateMeetingSummary;
  final http.Client _httpClient;

  static Future<AppDependencies> create({
    required String geminiApiKey,
    required String geminiModel,
  }) async {
    if (kIsWeb) {
      // No browser o Hive usa IndexedDB e nao precisa de diretorio local.
      Hive.init(null);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init('${appDir.path}/row_hive');
    }

    final localMeetingDataSource = LocalMeetingDataSource();
    await localMeetingDataSource.init();

    final httpClient = http.Client();

    final meetingRepository = MeetingRepositoryImpl(
      audioRecorderDataSource: AudioRecorderDataSource(),
      localMeetingDataSource: localMeetingDataSource,
      transcriptionService: GeminiTranscriptionService(
        client: httpClient,
        apiKey: geminiApiKey,
        model: geminiModel,
      ),
      summaryService: GeminiService(
        client: httpClient,
        apiKey: geminiApiKey,
        model: geminiModel,
      ),
      pdfExportService: const PdfExportServiceImpl(),
    );

    final meetingBloc = MeetingBloc(
      getMeetings: GetMeetings(meetingRepository),
      startRecording: StartRecording(meetingRepository),
      stopRecording: StopRecording(meetingRepository),
      transcribeMeeting: TranscribeMeeting(meetingRepository),
      summarizeMeeting: SummarizeMeeting(meetingRepository),
      saveMeeting: SaveMeeting(meetingRepository),
      deleteMeeting: DeleteMeeting(meetingRepository),
    );

    final generateSummaryAssistantContent = GenerateSummaryAssistantContent(
      meetingRepository,
    );

    final exportSummaryAssistantPdf = ExportSummaryAssistantPdf(
      meetingRepository,
    );

    final updateMeetingSummary = UpdateMeetingSummary(meetingRepository);

    return AppDependencies._(
      meetingRepository: meetingRepository,
      meetingBloc: meetingBloc,
      generateSummaryAssistantContent: generateSummaryAssistantContent,
      exportSummaryAssistantPdf: exportSummaryAssistantPdf,
      updateMeetingSummary: updateMeetingSummary,
      httpClient: httpClient,
    );
  }

  Future<void> dispose() async {
    await meetingBloc.close();
    await meetingRepository.dispose();
    _httpClient.close();
    await Hive.close();
  }
}
