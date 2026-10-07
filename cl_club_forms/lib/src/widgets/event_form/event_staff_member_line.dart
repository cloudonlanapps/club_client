import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import 'event_staff_form_layout.dart';
import 'event_staff_form_strings.dart';

/// An avatar + name + @username line for an organizer or a coach.
class EventStaffMemberLine extends StatelessWidget {
  const EventStaffMemberLine({
    required this.member,
    this.strikethrough = false,
    super.key,
  });

  /// The member shown.
  final EventStaffMember member;

  /// Whether the line is struck through: a coach staged for removal.
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final decoration = strikethrough ? TextDecoration.lineThrough : null;
    final color = strikethrough ? theme.colorScheme.mutedForeground : null;
    return Row(
      spacing: EventStaffFormLayout.inlineGap,
      children: [
        CircleAvatar(
          radius: EventStaffFormLayout.avatarRadius,
          backgroundColor: theme.colorScheme.muted,
          child: Text(
            member.initials,
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
              fontSize: EventStaffFormLayout.avatarFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.displayName,
                style: theme.textTheme.p.copyWith(
                  decoration: decoration,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${EventStaffFormStrings.usernamePrefix}${member.username}',
                style: theme.textTheme.muted.copyWith(
                  fontSize: EventStaffFormLayout.usernameFontSize,
                  decoration: decoration,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
