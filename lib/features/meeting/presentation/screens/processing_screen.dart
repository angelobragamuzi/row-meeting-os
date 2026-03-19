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
                  MaterialPageRoute<void>(
                    builder: (_) => ResultScreen(meeting: meeting),
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
              final status = switch (state) {
                MeetingProcessing(:final stage) => stage,
                _ => ProcessingStage.transcribing,
              };

              final statusText = status == ProcessingStage.transcribing
                  ? 'Transcrevendo...'
                  : 'Analisando...';

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF141414),
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFF2B2B2B), width: 2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROW / PROCESSANDO',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 12),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFF2B2B2B),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(
                          minHeight: 8,
                          color: Color(0xFFF2F2F2),
                          backgroundColor: Color(0xFF2B2B2B),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aguarde enquanto o audio e transformado em descricao estruturada.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFBEBEBE)),
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
