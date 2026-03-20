import 'package:flutter/foundation.dart';
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

    if (kIsWeb) {
      _recordingPath = 'meeting_${DateTime.now().millisecondsSinceEpoch}.webm';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      _recordingPath =
          '${docsDir.path}/meeting_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _audioRecorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        bitRate: kIsWeb ? 64000 : 128000,
        sampleRate: kIsWeb ? 48000 : 44100,
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
