import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../features/meeting/data/datasources/audio_recorder_data_source.dart';
import '../../features/meeting/data/datasources/local_meeting_data_source.dart';
import '../../features/meeting/data/repositories/meeting_repository_impl.dart';
import '../../features/meeting/data/services/gemini_service.dart';
import '../../features/meeting/data/services/gemini_transcription_service.dart';
import '../../features/meeting/domain/repositories/meeting_repository.dart';
import '../../features/meeting/domain/usecases/get_meetings.dart';
import '../../features/meeting/domain/usecases/save_meeting.dart';
import '../../features/meeting/domain/usecases/start_recording.dart';
import '../../features/meeting/domain/usecases/stop_recording.dart';
import '../../features/meeting/domain/usecases/summarize_meeting.dart';
import '../../features/meeting/domain/usecases/transcribe_meeting.dart';
import '../../features/meeting/presentation/bloc/meeting_bloc.dart';

class AppDependencies {
  AppDependencies._({
    required this.meetingRepository,
    required this.meetingBloc,
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  final MeetingRepository meetingRepository;
  final MeetingBloc meetingBloc;
  final http.Client _httpClient;

  static Future<AppDependencies> create({
    required String geminiApiKey,
    required String geminiModel,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init('${appDir.path}/row_hive');

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
    );

    final meetingBloc = MeetingBloc(
      getMeetings: GetMeetings(meetingRepository),
      startRecording: StartRecording(meetingRepository),
      stopRecording: StopRecording(meetingRepository),
      transcribeMeeting: TranscribeMeeting(meetingRepository),
      summarizeMeeting: SummarizeMeeting(meetingRepository),
      saveMeeting: SaveMeeting(meetingRepository),
    );

    return AppDependencies._(
      meetingRepository: meetingRepository,
      meetingBloc: meetingBloc,
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
