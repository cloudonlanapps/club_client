import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/event_staff_member.dart';
import 'event_staff_coach_row.dart';
import 'event_staff_form_layout.dart';
import 'event_staff_form_strings.dart';

/// The coaches of an event as rows, those staged for removal struck through,
/// above the **Add coaches** action.
class EventStaffCoachList extends StatelessWidget {
  const EventStaffCoachList({
    required this.coaches,
    required this.removed,
    required this.onRemove,
    required this.onUndo,
    required this.onAdd,
    this.enabled = true,
    super.key,
  });

  /// Every coach shown, those staged for removal included.
  final List<EventStaffMember> coaches;

  /// Usernames of the coaches staged for removal.
  final Set<String> removed;

  /// Called with a coach's username when its remove action is pressed.
  final ValueChanged<String> onRemove;

  /// Called with a coach's username when its Undo is pressed.
  final ValueChanged<String> onUndo;

  /// Called when Add coaches is pressed.
  final VoidCallback onAdd;

  /// Whether the actions respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.labelGap,
      children: [
        if (coaches.isEmpty)
          Text(EventStaffFormStrings.noCoaches, style: theme.textTheme.muted)
        else
          for (final coach in coaches)
            EventStaffCoachRow(
              coach: coach,
              removed: removed.contains(coach.username),
              enabled: enabled,
              onRemove: () => onRemove(coach.username),
              onUndo: () => onUndo(coach.username),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.outline(
            enabled: enabled,
            onPressed: onAdd,
            leading: const Icon(
              LucideIcons.plus,
              size: EventStaffFormLayout.iconSize,
            ),
            child: const Text(EventStaffFormStrings.addCoaches),
          ),
        ),
      ],
    );
  }
}
