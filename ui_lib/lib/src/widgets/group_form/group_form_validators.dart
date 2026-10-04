import '../common_form_validators.dart';
import 'group_form_fields.dart';

/// Static, SDK-free validators for the group forms.
class GroupFormValidators {
  const GroupFormValidators._();

  /// Group name: required, at least 2 characters (shared entity-name rule).
  static String? name(String value) =>
      CommonFormValidators.name(value, label: 'Group name');

  /// Cross-field: `dobOnOrAfter` must not be after `dobOnOrBefore` when both
  /// are set.
  static String? dobRange(DateTime? onOrAfter, DateTime? onOrBefore) {
    if (onOrAfter == null || onOrBefore == null) return null;
    if (onOrAfter.isAfter(onOrBefore)) {
      return 'DOB "on or after" must be on or before "on or before".';
    }
    return null;
  }

  /// Cross-field: an auto / semi-auto group needs at least one criterion,
  /// otherwise it is indistinguishable from a manual group.
  static String? criteriaForMode(
    GroupMode mode, {
    required bool hasAnyCriterion,
  }) {
    if (mode.usesCriteria && !hasAnyCriterion) {
      return 'Set at least one criterion (DOB or gender) for an '
          '${mode.label.toLowerCase()} group.';
    }
    return null;
  }
}
