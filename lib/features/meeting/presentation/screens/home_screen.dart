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

  Future<void> _deleteMeetingWithConfirm(String meetingId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir reuni\u00E3o?'),
          content: const Text(
            'Esta a\u00E7\u00E3o remove a reuni\u00E3o salva localmente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<MeetingBloc>().add(MeetingDeleted(meetingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(titleSpacing: 18, title: const Text('ROW')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecording,
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Nova reuni\u00E3o'),
      ),
      body: BlocConsumer<MeetingBloc, MeetingState>(
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
            return _EmptyState(onPressed: _openRecording);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Reuni\u00F5es',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${meetings.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFADB2BF),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF24262B)),
              Expanded(
                child: ListView.separated(
                  itemCount: meetings.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF1F2127),
                  ),
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
                      onDelete: () => _deleteMeetingWithConfirm(meeting.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nenhuma reuni\u00E3o registrada',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Nova reuni\u00E3o" para come\u00E7ar.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFA1A6B2)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Nova reuni\u00E3o'),
            ),
          ],
        ),
      ),
    );
  }
}
