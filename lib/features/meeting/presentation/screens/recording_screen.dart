import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulse(bool isRecording) {
    if (isRecording) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
      return;
    }

    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    if (_pulseController.value != 0) {
      _pulseController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: BlocConsumer<MeetingBloc, MeetingState>(
            listener: (context, state) {
              if (state is MeetingRecording) {
                _syncPulse(state.isRecording);
              }

              if (state is MeetingError) {
                _syncPulse(false);
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
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gravação da reunião',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Toque no microfone para iniciar ou parar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFBEBEBE),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(recordingState.elapsed),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _MicPulseOrb(
                      isRecording: isRecording,
                      pulse: _pulseController,
                      onTap: () {
                        context.read<MeetingBloc>().add(
                          isRecording
                              ? const RecordingStopped()
                              : const RecordingStarted(),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        isRecording
                            ? 'Gravando em tempo real...'
                            : canFinalize
                            ? 'Áudio pronto para processamento.'
                            : 'Aguardando início da gravação.',
                        key: ValueKey<String>(
                          '$isRecording-${recordingState.audioPath}',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isRecording
                                  ? const Color(0xFFF2F2F2)
                                  : const Color(0xFFB3B3B3),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canFinalize
                            ? () {
                                context.read<MeetingBloc>().add(
                                  const MeetingFinalized(),
                                );
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder<void>(
                                    transitionDuration: const Duration(
                                      milliseconds: 420,
                                    ),
                                    reverseTransitionDuration: const Duration(
                                      milliseconds: 260,
                                    ),
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const ProcessingScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          final curved = CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          );
                                          final offset = Tween<Offset>(
                                            begin: const Offset(0, 0.03),
                                            end: Offset.zero,
                                          ).animate(curved);

                                          return FadeTransition(
                                            opacity: curved,
                                            child: SlideTransition(
                                              position: offset,
                                              child: child,
                                            ),
                                          );
                                        },
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

class _MicPulseOrb extends StatelessWidget {
  const _MicPulseOrb({
    required this.isRecording,
    required this.pulse,
    required this.onTap,
  });

  final bool isRecording;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRecording) _PulseWave(animation: pulse, delay: 0.0),
            if (isRecording) _PulseWave(animation: pulse, delay: 0.35),
            if (isRecording) _PulseWave(animation: pulse, delay: 0.7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isRecording ? 138 : 124,
              height: isRecording ? 138 : 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isRecording
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFA4D4D), Color(0xFFE31A1A)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF2F2F2), Color(0xFFD9D9D9)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isRecording
                        ? const Color(0x66FF3B3B)
                        : const Color(0x33F2F2F2),
                    blurRadius: isRecording ? 28 : 16,
                    spreadRadius: isRecording ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.mic : Icons.mic_none_rounded,
                size: 46,
                color: isRecording ? const Color(0xFFFDFDFD) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseWave extends StatelessWidget {
  const _PulseWave({required this.animation, required this.delay});

  final Animation<double> animation;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = _progressWithDelay(animation.value, delay);
        final opacity = (1 - progress).clamp(0.0, 1.0) * 0.35;
        final size = 138 + (progress * 88);

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5555), width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  double _progressWithDelay(double value, double delay) {
    final shifted = value + delay;
    return shifted >= 1 ? shifted - 1 : shifted;
  }
}
