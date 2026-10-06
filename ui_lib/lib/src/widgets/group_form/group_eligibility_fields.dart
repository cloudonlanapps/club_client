import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../section_editor/section_editor_actions.dart';
import 'group_form_fields.dart';

/// Shared eligibility field cluster — a [GroupMode] selector plus the age
/// band ([AgeEligibilityFields]) and gender criteria. **Internal to ui_lib**
/// (not exported): it is the reusable body embedded by both
/// `GroupCreateForm` and `GroupEligibilityForm`, each under its own
/// `ShadForm`.
///
/// The criteria fields appear only when the selected mode uses criteria
/// (auto / semi-auto). When [criteriaLocked] is true — the group already has
/// members, so the server forbids changing what computes membership — the
/// mode selector and criteria are disabled.
///
/// With [showReset] the cluster carries its own Reset action, shown while it
/// holds a value and is not locked (group create, which has no section card
/// to carry it). The embedding form rebuilds the cluster when a value
/// changes.
class GroupEligibilityFields extends StatefulWidget {
  const GroupEligibilityFields({
    required this.initialMode,
    this.criteriaLocked = false,
    this.showReset = false,
    super.key,
  });

  final GroupMode initialMode;
  final bool criteriaLocked;

  /// Whether the cluster shows its own Reset action.
  final bool showReset;

  /// Whether [values] hold any criterion of a criteria-driven mode: a
  /// gender, an age or a ticked Strict age check. A Manual group holds none.
  static bool holdsValue(Map<String, dynamic> values) {
    final mode =
        values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
    return mode.usesCriteria &&
        (values[GroupFormFields.genderId] != null ||
            AgeEligibilityFormValues.holdsValue(values));
  }

  /// Empties gender, both ages and the Strict age check of [form] and sets
  /// its mode to Manual: a group with no criteria is a Manual group.
  static void reset(ShadFormState form) {
    form.setValue({
      GroupFormFields.genderId: null,
      ...AgeEligibilityFormValues.initial(),
      GroupFormFields.modeId: GroupMode.manual,
    });
  }

  @override
  State<GroupEligibilityFields> createState() => GroupEligibilityFieldsState();
}

class GroupEligibilityFieldsState extends State<GroupEligibilityFields> {
  late GroupMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final criteriaEnabled = _mode.usesCriteria && !widget.criteriaLocked;
    final form = ShadForm.of(context);
    final resettable =
        widget.showReset &&
        !widget.criteriaLocked &&
        GroupEligibilityFields.holdsValue(form.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Membership', style: theme.textTheme.h4),
        const SizedBox(height: 4),
        Text(
          widget.criteriaLocked
              ? 'Mode cannot be changed — the group already has members.'
              : 'Manual: add members by hand. Semi-auto / Auto: members are '
                    'matched from the criteria below.',
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: 12),
        ShadSelectFormField<GroupMode>(
          id: GroupFormFields.modeId,
          initialValue: widget.initialMode,
          enabled: !widget.criteriaLocked,
          label: const Text('Mode'),
          options: [
            for (final m in GroupMode.values)
              ShadOption(value: m, child: Text(m.label)),
          ],
          selectedOptionBuilder: (context, value) => Text(value.label),
          onChanged: (value) {
            if (value != null && value != _mode) {
              setState(() => _mode = value);
            }
          },
        ),
        if (_mode.usesCriteria) ...[
          const SizedBox(height: 16),
          Text('Eligibility criteria', style: theme.textTheme.small),
          const SizedBox(height: 8),
          AgeEligibilityFields(enabled: criteriaEnabled),
          const SizedBox(height: 12),
          ShadSelectFormField<GroupGender>(
            id: GroupFormFields.genderId,
            label: const Text('Gender'),
            placeholder: const Text('Any gender'),
            enabled: criteriaEnabled,
            options: [
              for (final g in GroupGender.values)
                ShadOption(value: g, child: Text(g.label)),
            ],
            selectedOptionBuilder: (context, value) => Text(value.label),
          ),
        ],
        if (resettable) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.outline(
              onPressed: () => GroupEligibilityFields.reset(form),
              child: const Text(SectionEditorActions.resetLabel),
            ),
          ),
        ],
      ],
    );
  }
}
