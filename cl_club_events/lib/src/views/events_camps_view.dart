import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventType, UserPrivate;
import 'package:flutter/widgets.dart';

import 'event_list_view.dart';

/// Camps list view (events of type [EventType.camp]).
class EventsCampsView extends StatelessWidget {
  const EventsCampsView({
    required this.currentUser,
    required this.onEventTap,
    this.onEnrollments,
    this.onCreateNew,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final void Function(Event event) onEventTap;
  final void Function(Event event)? onEnrollments;
  final VoidCallback? onCreateNew;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return EventListView(
      eventType: EventType.camp,
      onEventTap: onEventTap,
      onEnrollments: onEnrollments,
      onCreateNew: onCreateNew,
      onBack: onBack,
    );
  }
}
