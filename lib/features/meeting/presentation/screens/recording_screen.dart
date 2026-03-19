import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROW / GRAVAR')),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: BlocConsumer<MeetingBloc, MeetingState>(
            listener: (context, state) {
              if (state is MeetingError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              final recordingState = state is MeetingRecording
                  ? state
                  : const MeetingRecording(
                      isRecording: false,
                      elapsed: Duration.zero,
                    );

              final isRecording = recordingState.isRecording;
              final canFinalize =
                  !isRecording &&
                  (recordingState.audioPath?.isNotEmpty ?? false);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF141414),
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xFF2B2B2B), width: 2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRecording ? 'REC ON' : 'REC OFF',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  color: isRecording
                                      ? const Color(0xFFF2F2F2)
                                      : const Color(0xFF9A9A9A),
                                ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFF2B2B2B),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatDuration(recordingState.elapsed),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRecording
                          ? 'Gravando em tempo real'
                          : 'Pronto para gravar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RECORD  ORGANIZE  WORK',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF9A9A9A),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<MeetingBloc>().add(
                            isRecording
                                ? const RecordingStopped()
                                : const RecordingStarted(),
                          );
                        },
                        icon: Icon(isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          isRecording ? 'PARAR GRAVACAO' : 'INICIAR GRAVACAO',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canFinalize
                            ? () {
                                context.read<MeetingBloc>().add(
                                  const MeetingFinalized(),
                                );
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ProcessingScreen(),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.arrow_right_alt),
                        label: const Text('FINALIZAR E PROCESSAR'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
