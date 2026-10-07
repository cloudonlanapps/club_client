import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'group_eligibility_fields.dart';
import 'group_form_fields.dart';
import 'group_form_validators.dart';

/// Pure-UI editor for a group's membership mode + eligibility criteria.
///
/// Wraps the shared [GroupEligibilityFields] in its own `ShadForm`. The form
/// owns no buttons: a caller (e.g. `cl_club_members`) embeds it in a section
/// card and drives it through a `GlobalKey<GroupEligibilityFormState>` —
/// `validate()` from its Save action, `showErrors()` with what the server
/// refuses ([FormContract]).
class GroupEligibilityForm extends StatefulWidget {
  const GroupEligibilityForm({
    required this.initialValues,
    this.criteriaLocked = false,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Form values keyed by [GroupFormFields]; must carry the
  /// [GroupFormFields.modeId] entry.
  final Map<String, dynamic> initialValues;

  /// When true (group already has members), mode + criteria are read-only.
  final bool criteriaLocked;

  /// Called whenever a field's value changes, a reset included, so the host
  /// can re-read [GroupEligibilityFormState.hasValue].
  final VoidCallback? onChanged;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether [values] hold any criterion of a criteria-driven mode.
  static bool holdsValue(Map<String, dynamic> values) =>
      GroupEligibilityFields.holdsValue(values);

  @override
  State<GroupEligibilityForm> createState() => GroupEligibilityFormState();
}

/// State of [GroupEligibilityForm]. Its values are the mode, the gender and
/// the age cluster's entries, as the fields hold them.
class GroupEligibilityFormState extends State<GroupEligibilityForm>
    with FormContract<GroupEligibilityForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      GroupFormValidators.eligibility(values);

  /// Whether the form holds criteria a [reset] would empty. Never while the
  /// criteria are locked.
  bool get hasValue {
    final form = formKey.currentState;
    return form != null &&
        !widget.criteriaLocked &&
        GroupEligibilityFields.holdsValue(form.value);
  }

  /// Empties the criteria and sets the mode to Manual. Nothing is stored:
  /// the form is then changed, and the host's Save sends a Manual group.
  /// Does nothing while the criteria are locked.
  void reset() {
    final form = formKey.currentState;
    if (form == null || widget.criteriaLocked) return;
    GroupEligibilityFields.reset(form);
    setFormError(null);
  }

  @override
  Widget build(BuildContext context) {
    final initialMode =
        widget.initialValues[GroupFormFields.modeId] as GroupMode? ??
        GroupMode.manual;

    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      onChanged: widget.onChanged,
      child: FormBody(
        error: formError,
        children: [
          GroupEligibilityFields(
            initialMode: initialMode,
            criteriaLocked: widget.criteriaLocked,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
