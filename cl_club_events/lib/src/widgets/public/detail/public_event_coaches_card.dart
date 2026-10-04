import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/public/detail_labels/event_detail_coach_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_coach_row.dart';

/// Who coaches a public camp or one-off: one row per consenting coach, or a
/// "training by" card when the event names none.
class PublicEventCoachesCard extends StatelessWidget {
  const PublicEventCoachesCard({
    required this.event,
    required this.labels,
    required this.themeColor,
    super.key,
  });

  /// Heading of the card when the event names no coach.
  static const String noCoachesHeading = '~ Training By ~';

  /// Who trains when the event names no coach.
  ///
  /// Carried over from the site as it was (#53). It is one club's copy in a
  /// club-neutral package, and moves to the host's strings when this package
  /// is localised.
  static const String noCoachesText =
      'Coaches to be announced';

  final PublicEventView event;
  final EventDetailCoachLabels labels;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // The event carries its consenting coaches as public profiles; the
    // public projection names nobody who has not consented, so the profiles
    // are the only list there is.
    final coaches = event.coaches;

    if (coaches.isEmpty) {
      return ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                noCoachesHeading,
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                noCoachesText,
                textAlign: TextAlign.center,
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              event.isActive ? labels.labelActive : labels.labelPast,
              style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final profile in coaches)
              PublicEventCoachRow(profile: profile, themeColor: themeColor),
          ],
        ),
      ),
    );
  }
}
