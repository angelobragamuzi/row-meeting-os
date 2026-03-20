import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/meeting.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
    required this.onDelete,
  });

  final Meeting meeting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(meeting.createdAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFA3A9B6),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meeting.context.isEmpty
                        ? 'Resumo indisponível para esta reunião.'
                        : meeting.context,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.26,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_MeetingMenuAction>(
              icon: const Icon(Icons.more_horiz_rounded),
              tooltip: 'Ações da reunião',
              onSelected: (value) {
                if (value == _MeetingMenuAction.delete) {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_MeetingMenuAction>(
                  value: _MeetingMenuAction.delete,
                  child: Text('Excluir reunião'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _MeetingMenuAction { delete }
