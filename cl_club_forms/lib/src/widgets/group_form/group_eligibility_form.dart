import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'group_create_form.dart' show groupEligibilityError;
import 'group_eligibility_fields.dart';
import 'group_form_fields.dart';

/// Pure-UI editor for a group's membership mode + eligibility criteria.
///
/// Wraps the shared [GroupEligibilityFields] in its own `ShadForm`. Host-
/// agnostic: a caller (e.g. `cl_club_members`) embeds it in a dialog and drives
/// it through a `GlobalKey<GroupEligibilityFormState>`, calling
/// [GroupEligibilityFormState.validate] from the Save action.
class GroupEligibilityForm extends StatefulWidget {
  const GroupEligibilityForm({
    required this.initialValues,
    this.criteriaLocked = false,
    this.onChanged,
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

  /// Whether [values] hold any criterion of a criteria-driven mode.
  static bool holdsValue(Map<String, dynamic> values) =>
      GroupEligibilityFields.holdsValue(values);

  @override
  State<GroupEligibilityForm> createState() => GroupEligibilityFormState();
}

class GroupEligibilityFormState extends State<GroupEligibilityForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? _formError;

  /// Validates (including cross-field checks). Returns the form values when
  /// valid, else `null` (and surfaces an inline error).
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final values = form.value;
    final error = groupEligibilityError(values);
    if (error != null) {
      setState(() => _formError = error);
      return null;
    }
    return values;
  }

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
    if (_formError != null) setState(() => _formError = null);
  }

  /// Whether any field differs from the initial values the form was seeded
  /// with. Mirrors `UserForm`/`GroupCreateForm`'s framework-driven check.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !mapEquals(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initialMode =
        widget.initialValues[GroupFormFields.modeId] as GroupMode? ??
        GroupMode.manual;

    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      onChanged: widget.onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GroupEligibilityFields(
            initialMode: initialMode,
            criteriaLocked: widget.criteriaLocked,
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(
              _formError!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
