import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'age_eligibility_form_fields.dart';
import 'age_input_row.dart';

/// The shared age cluster of the eligibility editors: a minimum and a
/// maximum age, each as years, months and days, and the Strict age check.
///
/// Embedded under the host form's `ShadForm` (the event Eligibility form and
/// the group forms), which seeds it with `AgeEligibilityFormValues.initial`
/// and checks it with `AgeEligibilityFormValidators.band` in `validate()`.
class AgeEligibilityFields extends StatelessWidget {
  const AgeEligibilityFields({this.enabled = true, super.key});

  /// False renders the cluster read-only (a group whose criteria are locked).
  final bool enabled;

  static const String minAgeTitle = 'Minimum age';
  static const String maxAgeTitle = 'Maximum age';
  static const String emptyHint =
      'Leave an age empty to place no limit on that side.';
  static const String strictLabel = 'Strict age check';
  static const String strictHint =
      'On: only members aged within the limits on the day ages are counted. '
      'Off: also members up to a year short of the minimum or past the '
      'maximum.';

  /// Gap between the cluster's rows.
  static const double rowGap = 12;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initialStrict =
        ShadForm.maybeOf(
              context,
            )?.initialValue[AgeEligibilityFormFields.strictAgeId]
            as bool? ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: rowGap,
      children: [
        AgeInputRow(
          title: minAgeTitle,
          yearsId: AgeEligibilityFormFields.minAgeYearsId,
          monthsId: AgeEligibilityFormFields.minAgeMonthsId,
          daysId: AgeEligibilityFormFields.minAgeDaysId,
          enabled: enabled,
        ),
        AgeInputRow(
          title: maxAgeTitle,
          yearsId: AgeEligibilityFormFields.maxAgeYearsId,
          monthsId: AgeEligibilityFormFields.maxAgeMonthsId,
          daysId: AgeEligibilityFormFields.maxAgeDaysId,
          enabled: enabled,
        ),
        Text(emptyHint, style: theme.textTheme.muted),
        ShadCheckboxFormField(
          id: AgeEligibilityFormFields.strictAgeId,
          initialValue: initialStrict,
          enabled: enabled,
          inputLabel: const Text(strictLabel),
          inputSublabel: const Text(strictHint),
        ),
      ],
    );
  }
}
