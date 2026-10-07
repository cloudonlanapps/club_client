import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import 'event_staff_form_layout.dart';
import 'event_staff_form_strings.dart';
import 'event_staff_member_line.dart';

/// The organizer's row: who it is, or *Unassigned*, beside the **Transfer**
/// action that picks another.
class EventStaffOrganizerRow extends StatelessWidget {
  const EventStaffOrganizerRow({
    required this.organizer,
    required this.onTransfer,
    this.enabled = true,
    super.key,
  });

  /// The organizer; null while the event has none.
  final EventStaffMember? organizer;

  /// Called when Transfer is pressed.
  final VoidCallback onTransfer;

  /// Whether Transfer responds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final member = organizer;
    return Row(
      spacing: EventStaffFormLayout.inlineGap,
      children: [
        Expanded(
          child: member == null
              ? Text(
                  EventStaffFormStrings.unassigned,
                  style: theme.textTheme.muted,
                )
              : EventStaffMemberLine(member: member),
        ),
        ShadButton.outline(
          enabled: enabled,
          onPressed: onTransfer,
          leading: const Icon(
            LucideIcons.userCog,
            size: EventStaffFormLayout.iconSize,
          ),
          child: const Text(EventStaffFormStrings.transfer),
        ),
      ],
    );
  }
}
