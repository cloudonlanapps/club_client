import 'package:cl_club_forms/cl_club_forms.dart' show AgeEligibilitySummary;
import 'package:cl_remote_store/cl_remote_store.dart' show formAgeFromSdk;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Read view of an event's eligibility, shared by the editor's Eligibility
/// card and the preview: the gender line, then the age sentence with the
/// server's dates and reference day beneath; "open to all" when the event
/// sets neither.
class EventEligibilityRead extends StatelessWidget {
  const EventEligibilityRead({required this.event, super.key});

  final Event event;

  static const String openToAll = 'This event is open to all.';

  /// Gap between the gender line and the age sentence.
  static const double lineGap = 8;

  /// The gender line, or `null` when the event admits every gender.
  static String? genderSentence(Gender? gender) => switch (gender) {
    Gender.male => 'This event is only for Boys.',
    Gender.female => 'This event is only for Girls.',
    Gender.other => 'This event is only for members who identify as Other.',
    Gender.preferNotToSay || null => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final gender = genderSentence(event.gender);
    final hasAgeBand = event.minAge != null || event.maxAge != null;
    if (gender == null && !hasAgeBand) {
      return Text(openToAll, style: theme.textTheme.p);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: lineGap,
      children: [
        if (gender != null) Text(gender, style: theme.textTheme.p),
        if (hasAgeBand)
          AgeEligibilitySummary(
            minAge: formAgeFromSdk(event.minAge),
            maxAge: formAgeFromSdk(event.maxAge),
            dobOnOrAfter: event.dobOnOrAfterUtc,
            dobOnOrBefore: event.dobOnOrBeforeUtc,
            referenceDay: event.eligibilityReferenceDayUtc,
          ),
      ],
    );
  }
}
