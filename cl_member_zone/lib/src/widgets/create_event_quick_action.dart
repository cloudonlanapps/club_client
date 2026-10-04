import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'quick_action_tile.dart';

/// The Create Event quick action for the event types the club runs
/// (club_core#115).
///
/// With one type the tile opens its create flow directly; with several it
/// opens a popover that names each type.
class CreateEventQuickAction extends StatefulWidget {
  const CreateEventQuickAction({
    required this.eventTypes,
    required this.onCreateEvent,
    super.key,
  });

  /// The club's event types, in [EventType] order when listed.
  final Set<EventType> eventTypes;

  /// Opens the create flow for the chosen type.
  final ValueChanged<EventType> onCreateEvent;

  @override
  State<CreateEventQuickAction> createState() => CreateEventQuickActionState();
}

class CreateEventQuickActionState extends State<CreateEventQuickAction> {
  final popoverController = ShadPopoverController();

  List<EventType> get types => [
    for (final type in EventType.values)
      if (widget.eventTypes.contains(type)) type,
  ];

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  void choose(EventType type) {
    popoverController.hide();
    widget.onCreateEvent(type);
  }

  @override
  Widget build(BuildContext context) {
    final types = this.types;
    if (types.length == 1) {
      return QuickActionTile(
        icon: LucideIcons.calendarPlus,
        label: 'Create Event',
        onTap: () => widget.onCreateEvent(types.single),
      );
    }
    return ShadPopover(
      controller: popoverController,
      popover: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in types)
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () => choose(type),
              child: Text(createEventLabel(type)),
            ),
        ],
      ),
      child: QuickActionTile(
        icon: LucideIcons.calendarPlus,
        label: 'Create Event',
        onTap: popoverController.toggle,
      ),
    );
  }
}

/// The popover entry naming what [type]'s create flow makes.
String createEventLabel(EventType type) => switch (type) {
  EventType.camp => 'New Camp',
  EventType.programme => 'New Program',
  EventType.oneOff => 'New Event',
};
