import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/error/app_exception.dart';

class AudioRecorderDataSource {
  AudioRecorderDataSource({AudioRecorder? audioRecorder})
    : _audioRecorder = audioRecorder ?? AudioRecorder();

  final AudioRecorder _audioRecorder;
  String? _recordingPath;

  Future<String> startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw const AppException('Permissao de microfone negada.');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final recordsDir = Directory('${docsDir.path}/recordings');
    await recordsDir.create(recursive: true);

    _recordingPath =
        '${recordsDir.path}/meeting_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    return _recordingPath!;
  }

  Future<String> stopRecording() async {
    final path = await _audioRecorder.stop();

    if (path == null || path.trim().isEmpty) {
      throw const AppException('Nao foi possivel finalizar a gravacao.');
    }

    _recordingPath = path;
    return path;
  }

  Future<void> dispose() => _audioRecorder.dispose();
}
