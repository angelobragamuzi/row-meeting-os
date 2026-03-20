import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0C0E), Color(0xFF060709)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(lineColor: const Color(0x13262B36)),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final glow = 0.84 + (0.08 * _controller.value);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: glow,
                        colors: const [Color(0x14FFFFFF), Color(0x00000000)],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: BlocConsumer<MeetingBloc, MeetingState>(
                listener: (context, state) {
                  if (state is MeetingLoaded && state.selectedMeeting != null) {
                    final meeting = state.selectedMeeting!;
                    context.read<MeetingBloc>().add(
                      const MeetingSelectionCleared(),
                    );

                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 320),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ResultScreen(meeting: meeting),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                    );
                  }

                  if (state is MeetingError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));

                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                builder: (context, state) {
                  final stage = switch (state) {
                    MeetingProcessing(:final stage) => stage,
                    _ => ProcessingStage.transcribing,
                  };

                  final title = stage == ProcessingStage.transcribing
                      ? 'Transcrevendo \u00e1udio'
                      : 'Analisando reuni\u00e3o';
                  final subtitle = stage == ProcessingStage.transcribing
                      ? 'Convertendo voz em texto'
                      : 'Estruturando contexto e decis\u00f5es';

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ROW',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3.5,
                                      ),
                                ),
                                const SizedBox(height: 18),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: Text(
                                    title,
                                    key: ValueKey<String>(title),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: Text(
                                    subtitle,
                                    key: ValueKey<String>(subtitle),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFFA9AFBC),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _LoadingLine(progress: _controller.value),
                                const SizedBox(height: 12),
                                Text(
                                  'Aguarde alguns segundos',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: const Color(0xFF7D8492),
                                        letterSpacing: 0.25,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeInOut.transform(progress);
    final start = (p - 0.28).clamp(0.0, 0.72);
    final widthFactor = 0.28;

    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final left = width * start;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 3.5),
                  color: const Color(0xFF2D313A),
                ),
              ),
              Positioned(
                left: left,
                top: 2,
                child: Container(
                  width: width * widthFactor,
                  height: 3,
                  color: const Color(0xFFE6EBF5),
                ),
              ),
              Positioned(
                left: left + (width * widthFactor) - 4,
                top: 1,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF3FB),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEFF3FB).withValues(alpha: 0.32),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
