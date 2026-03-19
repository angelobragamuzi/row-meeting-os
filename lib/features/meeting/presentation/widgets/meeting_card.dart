import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/meeting.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.meeting, required this.onTap});

  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(meeting.createdAt);
    final source = (meeting.summary['fonte'] ?? 'indefinido').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
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
                'REUNIAO  $formattedDate',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF9A9A9A),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: Color(0xFF2B2B2B)),
              const SizedBox(height: 8),
              Text(
                meeting.context.isEmpty
                    ? 'Sem descricao disponivel.'
                    : meeting.context,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'FONTE: $source',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
