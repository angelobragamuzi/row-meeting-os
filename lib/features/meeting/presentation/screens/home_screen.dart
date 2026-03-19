import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import '../widgets/meeting_card.dart';
import 'recording_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingBloc>().add(const MeetingsRequested());
    });
  }

  Future<void> _openRecording() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordingScreen()));

    if (!mounted) {
      return;
    }

    context.read<MeetingBloc>().add(const MeetingsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROW')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openRecording,
            icon: const Icon(Icons.mic),
            label: const Text('NOVA REUNIAO'),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2B2B2B), width: 2),
                  ),
                ),
                child: Text(
                  'RECORD  ORGANIZE  WORK',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ),
              Expanded(
                child: BlocConsumer<MeetingBloc, MeetingState>(
                  listener: (context, state) {
                    if (state is MeetingError) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(state.message)));
                    }
                  },
                  builder: (context, state) {
                    if (state is MeetingInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final meetings = state.meetings;

                    if (meetings.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _EmptyState(onPressed: _openRecording),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: meetings.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final meeting = meetings[index];
                        return MeetingCard(
                          meeting: meeting,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ResultScreen(meeting: meeting),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF2B2B2B), width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum, size: 48),
            const SizedBox(height: 16),
            Text(
              'Nenhuma reuniao registrada',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grave e processe uma reuniao para visualizar a descricao estruturada.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFBEBEBE)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.mic),
              label: const Text('INICIAR'),
            ),
          ],
        ),
      ),
    );
  }
}
