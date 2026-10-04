import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Human-readable eligibility section for an event — mirrors
/// `GroupEligibilitySection`. Renders prose lines explaining the gender
/// constraint and the date-of-birth window, or "Open to all" when no
/// criteria are configured.
class ClEligibilityPreview extends StatelessWidget {
  const ClEligibilityPreview({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final lines = _buildSentences(event);

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eligibility', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(lines[i], style: theme.textTheme.p),
          ],
        ],
      ),
    );
  }

  static List<String> _buildSentences(Event event) {
    final lines = <String>[];
    final genderLine = _genderSentence(event.gender);
    if (genderLine != null) lines.add(genderLine);
    final dobLine = _dobSentence(event.dobOnOrAfterUtc, event.dobOnOrBeforeUtc);
    if (dobLine != null) lines.add(dobLine);
    if (lines.isEmpty) lines.add('This event is open to all.');
    return lines;
  }

  static String? _genderSentence(Gender? gender) {
    if (gender == null) return null;
    switch (gender) {
      case Gender.male:
        return 'This event is only for Boys.';
      case Gender.female:
        return 'This event is only for Girls.';
      case Gender.other:
        return 'This event is only for members who identify as Other.';
      case Gender.preferNotToSay:
        return null;
    }
  }

  static String? _dobSentence(DateTime? onOrAfter, DateTime? onOrBefore) {
    if (onOrAfter == null && onOrBefore == null) return null;
    if (onOrAfter != null && onOrBefore != null) {
      return 'This event uses age-based eligibility, and permits only those '
          'who were born between ${onOrAfter.toLocalDateMedium()} and '
          '${onOrBefore.toLocalDateMedium()} (both dates inclusive).';
    }
    if (onOrAfter != null) {
      return 'This event uses age-based eligibility, and permits only those '
          'who were born on or after ${onOrAfter.toLocalDateMedium()}.';
    }
    return 'This event uses age-based eligibility, and permits only those '
        'who were born on or before ${onOrBefore!.toLocalDateMedium()}.';
  }
}
