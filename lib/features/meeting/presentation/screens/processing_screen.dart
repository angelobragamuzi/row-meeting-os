import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: BlocConsumer<MeetingBloc, MeetingState>(
            listener: (context, state) {
              if (state is MeetingLoaded && state.selectedMeeting != null) {
                final meeting = state.selectedMeeting!;
                context.read<MeetingBloc>().add(
                  const MeetingSelectionCleared(),
                );

                Navigator.of(context).pushReplacement(
                  PageRouteBuilder<void>(
                    transitionDuration: const Duration(milliseconds: 460),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 240,
                    ),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return ResultScreen(meeting: meeting);
                    },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          final offset = Tween<Offset>(
                            begin: const Offset(0, 0.02),
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
                  ? 'Transcrevendo áudio'
                  : 'Analisando reunião';
              final subtitle = stage == ProcessingStage.transcribing
                  ? 'Convertendo fala em texto'
                  : 'Gerando resumo da reunião';

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ROW',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                              ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: Text(
                            title,
                            key: ValueKey<String>(title),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: Text(
                            subtitle,
                            key: ValueKey<String>(subtitle),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFFA8AEB8)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: Color(0xFFF2F2F2),
                            backgroundColor: Color(0xFF2A2E37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
