import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../event_eligibility_read.dart';

/// Read-only eligibility section for an event — mirrors
/// `GroupEligibilitySection`. Renders the gender constraint and the age band
/// ([EventEligibilityRead]), or "Open to all" when no criteria are
/// configured.
class ClEligibilityPreview extends StatelessWidget {
  const ClEligibilityPreview({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eligibility', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          EventEligibilityRead(event: event),
        ],
      ),
    );
  }
}
