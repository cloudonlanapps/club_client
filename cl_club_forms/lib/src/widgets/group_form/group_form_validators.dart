import '../age_eligibility/age_eligibility_form_validators.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../common_form_validators.dart';
import 'group_form_fields.dart';

/// Static, SDK-free validators for the group forms.
class GroupFormValidators {
  const GroupFormValidators._();

  /// Group name: required, at least 2 characters (shared entity-name rule).
  static String? name(String value) =>
      CommonFormValidators.name(value, label: 'Group name');

  /// Cross-field: an auto / semi-auto group needs at least one criterion —
  /// an age limit, or Gender on Boys or Girls (Any is none) — otherwise it
  /// is indistinguishable from a manual group.
  static String? criteriaForMode(
    GroupMode mode, {
    required bool hasAnyCriterion,
  }) {
    if (mode.usesCriteria && !hasAnyCriterion) {
      // "an auto group", "a semi-auto group".
      final article = mode == GroupMode.auto ? 'an' : 'a';
      return 'Set at least one criterion (age or gender) for $article '
          '${mode.label.toLowerCase()} group.';
    }
    return null;
  }

  /// Cross-field rule of the whole eligibility block, shared by the create
  /// form and the eligibility editor: the age band is valid, and a
  /// criteria-driven mode has at least one criterion. Returns the message to
  /// show inline, or `null` when [values] are valid.
  ///
  /// A manual group has no criteria, so its hidden age inputs are not
  /// checked.
  static String? eligibility(Map<String, dynamic> values) {
    final mode =
        values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
    if (!mode.usesCriteria) return null;
    return AgeEligibilityFormValidators.band(values) ??
        criteriaForMode(
          mode,
          hasAnyCriterion:
              AgeEligibilityFormValues.hasAgeBound(values) ||
              GroupGender.of(values).isCriterion,
        );
  }
}
