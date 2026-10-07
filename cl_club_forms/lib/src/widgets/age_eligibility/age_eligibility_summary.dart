import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'age_eligibility_text.dart';
import 'form_age.dart';

/// Read view of an age band: the age sentence, and beneath it in muted text
/// the dates of birth the server reports and the day they are counted on.
///
/// Renders nothing when the band has no bound. The dates are the server's
/// own; nothing here works a window out.
class AgeEligibilitySummary extends StatelessWidget {
  const AgeEligibilitySummary({
    this.minAge,
    this.maxAge,
    this.dobOnOrAfter,
    this.dobOnOrBefore,
    this.referenceDay,
    super.key,
  });

  final FormAge? minAge;
  final FormAge? maxAge;

  /// The window the server reports, both ends inclusive.
  final DateTime? dobOnOrAfter;
  final DateTime? dobOnOrBefore;

  /// The calendar day the server counted the ages on.
  final DateTime? referenceDay;

  /// Gap between the sentence and the muted line.
  static const double lineGap = 4;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final sentence = AgeEligibilityText.sentence(
      minAge: minAge,
      maxAge: maxAge,
    );
    if (sentence == null) return const SizedBox.shrink();
    final window = AgeEligibilityText.window(
      dobOnOrAfter: dobOnOrAfter,
      dobOnOrBefore: dobOnOrBefore,
      referenceDay: referenceDay,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: lineGap,
      children: [
        Text('$sentence.', style: theme.textTheme.p),
        if (window != null) Text(window, style: theme.textTheme.muted),
      ],
    );
  }
}
