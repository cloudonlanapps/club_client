import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'group_form_fields.dart';

/// Shared eligibility field cluster — a [GroupMode] selector plus the DOB /
/// gender criteria. **Internal to ui_lib** (not exported): it is the reusable
/// body embedded by both `GroupCreateForm` and `GroupEligibilityForm`, each
/// under its own `ShadForm`.
///
/// The criteria fields appear only when the selected mode uses criteria
/// (auto / semi-auto). When [criteriaLocked] is true — the group already has
/// members, so the server forbids changing what computes membership — the
/// mode selector and criteria are disabled.
class GroupEligibilityFields extends StatefulWidget {
  const GroupEligibilityFields({
    required this.initialMode,
    this.criteriaLocked = false,
    super.key,
  });

  final GroupMode initialMode;
  final bool criteriaLocked;

  @override
  State<GroupEligibilityFields> createState() => GroupEligibilityFieldsState();
}

class GroupEligibilityFieldsState extends State<GroupEligibilityFields> {
  late GroupMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final criteriaEnabled = _mode.usesCriteria && !widget.criteriaLocked;

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
          CLDatePickerFormField(
            id: GroupFormFields.dobOnOrAfterId,
            label: const Text('DOB on or after'),
            placeholder: const Text('No lower bound'),
            enabled: criteriaEnabled,
          ),
          const SizedBox(height: 12),
          CLDatePickerFormField(
            id: GroupFormFields.dobOnOrBeforeId,
            label: const Text('DOB on or before'),
            placeholder: const Text('No upper bound'),
            enabled: criteriaEnabled,
          ),
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
      ],
    );
  }
}
