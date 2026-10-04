import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_display_status.dart';
import '../../providers/event_display_status.dart';

/// Audit info card for an event — mirrors AccountInfoSection (user profile)
/// and GroupInfoSection (group detail).
///
/// Visible only to admins and coaches. Shows organizer, display status,
/// created/updated timestamps, and a deleted row when the event has been
/// soft-deleted. An event keeps one id across splits (club_core#16), so its
/// own timestamps cover its whole life.
class ClEventAuditInfo extends ConsumerWidget {
  const ClEventAuditInfo({
    required this.event,
    required this.currentUser,
    super.key,
  });

  final Event event;
  final UserPrivate? currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = currentUser;
    if (user == null || !user.isCoachOrAdmin) {
      return const SizedBox.shrink();
    }

    final theme = ShadTheme.of(context);
    final status = ref.watch(eventDisplayStatusProvider(event.id)).valueOrNull;
    final createdAt = event.createdAtUtc;
    final updatedAt = event.updatedAtUtc;
    final organizerName = event.organizerName;

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Info', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          if (organizerName != null && organizerName.isNotEmpty) ...[
            AuditField(label: 'Organizer', value: organizerName),
            const SizedBox(height: 8),
          ],
          if (status != null) ...[
            AuditField(label: 'Status', value: eventDisplayStatusLabel(status)),
            const SizedBox(height: 8),
          ],
          AuditField(
            label: 'Created',
            value: createdAt.toLocalDateTimeMedium(),
          ),
          const SizedBox(height: 8),
          AuditField(
            label: 'Last updated',
            value: updatedAt.toLocalDateTimeMedium(),
          ),
          if (event.deletedAtUtc != null) ...[
            const SizedBox(height: 8),
            AuditField(
              label: 'Deleted',
              value: event.deletedAtUtc!.toLocalDateTimeMedium(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label + boxed value, matching the AccountInfoSection ReadOnlyField style.
class AuditField extends StatelessWidget {
  const AuditField({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.small),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: theme.textTheme.p),
        ),
      ],
    );
  }
}
