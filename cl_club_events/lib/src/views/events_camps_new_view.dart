import 'package:cl_club_forms/cl_club_forms.dart' show EventFormType;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';

import 'event_create_view.dart';

/// Create-form view for a new camp event.
class EventsCampsNewView extends StatelessWidget {
  const EventsCampsNewView({
    required this.currentUser,
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final UserPrivate currentUser;
  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return EventCreateView(
      eventType: EventFormType.camp,
      onCreated: onCreated,
      onCancel: onCancel,
    );
  }
}
