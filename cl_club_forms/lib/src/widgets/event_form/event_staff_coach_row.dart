import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import 'event_staff_form_layout.dart';
import 'event_staff_form_strings.dart';
import 'event_staff_member_line.dart';

/// A coach's row with a remove (✕) action or, when the coach is staged for
/// removal, struck through with an **Undo** action.
class EventStaffCoachRow extends StatelessWidget {
  const EventStaffCoachRow({
    required this.coach,
    required this.removed,
    required this.onRemove,
    required this.onUndo,
    this.enabled = true,
    super.key,
  });

  /// The coach shown.
  final EventStaffMember coach;

  /// Whether the coach is staged for removal.
  final bool removed;

  /// Called when the remove action is pressed.
  final VoidCallback onRemove;

  /// Called when Undo is pressed.
  final VoidCallback onUndo;

  /// Whether the actions respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: EventStaffFormLayout.inlineGap,
      children: [
        Expanded(
          child: EventStaffMemberLine(member: coach, strikethrough: removed),
        ),
        if (removed)
          ShadButton.ghost(
            enabled: enabled,
            onPressed: onUndo,
            leading: const Icon(
              LucideIcons.undo2,
              size: EventStaffFormLayout.iconSize,
            ),
            child: const Text(EventStaffFormStrings.undo),
          )
        else
          ShadButton.ghost(
            enabled: enabled,
            onPressed: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: EventStaffFormLayout.iconSize,
            ),
          ),
      ],
    );
  }
}
