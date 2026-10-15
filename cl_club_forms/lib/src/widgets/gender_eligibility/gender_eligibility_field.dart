import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import 'eligibility_gender.dart';
import 'gender_eligibility_form_fields.dart';
import 'gender_eligibility_form_values.dart';

/// The shared gender field of the eligibility editors: one checkbox per
/// gender a person can register with, any number ticked. Its value is the
/// ticked genders in the order the boxes show; none ticked is no gender
/// criterion, which the line beneath the boxes says.
///
/// Embedded under the host form's `ShadForm` (the event Eligibility form and
/// the group forms) with the id [GenderEligibilityFormFields.gendersId]; the
/// host seeds it with `GenderEligibilityFormValues.initial`.
class GenderEligibilityField
    extends ShadFormBuilderField<List<EligibilityGender>> {
  GenderEligibilityField({super.enabled, super.key})
    : super(
        id: GenderEligibilityFormFields.gendersId,
        // The form hands its value back deep-copied, a `List<dynamic>`.
        fromValueTransformer: (value) => GenderEligibilityFormValues.genders({
          GenderEligibilityFormFields.gendersId: value,
        }),
        builder: (field) {
          final state = field as GenderEligibilityFieldState;
          return GenderEligibilityChecks(
            ticked: state.ticked,
            enabled: state.enabled,
            focusNode: state.focusNode,
            onChanged: state.toggle,
          );
        },
      );

  /// The line shown while no box is ticked.
  static const String noneTickedHint =
      'No box ticked: open to members of every gender.';

  @override
  GenderEligibilityFieldState createState() => GenderEligibilityFieldState();
}

/// State of [GenderEligibilityField].
class GenderEligibilityFieldState
    extends
        ShadFormBuilderFieldState<
          GenderEligibilityField,
          List<EligibilityGender>
        > {
  /// The genders ticked now, in the order the boxes show.
  List<EligibilityGender> get ticked =>
      GenderEligibilityFormValues.ordered(value ?? const []);

  /// Ticks [gender] when [on], unticks it otherwise.
  void toggle(EligibilityGender gender, {required bool on}) {
    final next = {...ticked};
    if (on) {
      next.add(gender);
    } else {
      next.remove(gender);
    }
    didChange(GenderEligibilityFormValues.ordered(next));
  }
}

/// The boxes of [GenderEligibilityField], with the line saying that none
/// ticked admits every gender.
class GenderEligibilityChecks extends StatelessWidget {
  const GenderEligibilityChecks({
    required this.ticked,
    required this.enabled,
    required this.onChanged,
    this.focusNode,
    super.key,
  });

  /// The genders ticked.
  final List<EligibilityGender> ticked;

  /// Whether the boxes respond.
  final bool enabled;

  /// Called with a gender and whether its box is now ticked.
  final void Function(EligibilityGender gender, {required bool on}) onChanged;

  /// The field's focus node, given to the first box.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.labelGap,
      children: [
        Wrap(
          spacing: FormSpacing.rowGap,
          runSpacing: FormSpacing.labelGap,
          children: [
            for (final gender in EligibilityGender.values)
              ShadCheckbox(
                key: ValueKey(gender),
                value: ticked.contains(gender),
                enabled: enabled,
                focusNode: gender == EligibilityGender.values.first
                    ? focusNode
                    : null,
                label: Text(gender.label),
                onChanged: (on) => onChanged(gender, on: on),
              ),
          ],
        ),
        if (ticked.isEmpty)
          Text(
            GenderEligibilityField.noneTickedHint,
            style: theme.textTheme.muted,
          ),
      ],
    );
  }
}
