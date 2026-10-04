import 'package:club_sdk_2/club_sdk_2.dart' show Event, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';

/// Read-only display of the event's visibility and featured flags as a
/// pair of disabled checkboxes inside a ShadCard, mirroring the
/// Roles-section pattern in the user profile.
///
/// Both checkboxes are permanently disabled — edits happen elsewhere.
class ClEventFlags extends StatelessWidget {
  const ClEventFlags({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final isPrivate = event.visibility == Visibility.private;
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCheckbox(
            value: isPrivate,
            enabled: false,
            label: const Text('This is a private event'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: event.isFeatured,
            enabled: false,
            label: const Text('This event is featured'),
          ),
        ],
      ),
    );
  }
}
