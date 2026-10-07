import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../constants/form_strings.dart';
import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../form/labeled_form_row.dart';
import 'group_form_fields.dart';
import 'group_membership_heading.dart';

/// Shared eligibility field cluster — a [GroupMode] selector plus the age
/// band ([AgeEligibilityFields]) and gender criteria. **Internal to
/// cl_club_forms** (not exported): it is the reusable body embedded by both
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
    this.enabled = true,
    super.key,
  });

  /// The mode the selector starts on.
  final GroupMode initialMode;

  /// Whether the mode and the criteria are read-only because the group
  /// already has members.
  final bool criteriaLocked;

  /// Whether the cluster shows its own Reset action.
  final bool showReset;

  /// Whether the fields respond; false while the host saves.
  final bool enabled;

  /// Heading of the criteria group.
  static const String criteriaTitle = 'Eligibility criteria';

  /// Whether [values] hold any criterion of a criteria-driven mode: Boys or
  /// Girls, an age or a ticked Strict age check. Gender on Any is none, and
  /// a Manual group holds none.
  static bool holdsValue(Map<String, dynamic> values) {
    final mode =
        values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
    return mode.usesCriteria &&
        (GroupGender.of(values).isCriterion ||
            AgeEligibilityFormValues.holdsValue(values));
  }

  /// [values] with Gender on Any when they hold no gender, so the field
  /// always shows an entry and a form nobody touched is not dirty. The
  /// embedding form seeds its `ShadForm` with this.
  static Map<String, dynamic> seeded(Map<String, dynamic> values) => {
    ...values,
    GroupFormFields.genderId: GroupGender.of(values),
  };

  /// Puts Gender back to Any, empties both ages and the Strict age check of
  /// [form] and sets its mode to Manual: a group with no criteria is a
  /// Manual group.
  static void reset(ShadFormState form) {
    form.setValue({
      GroupFormFields.genderId: GroupGender.any,
      ...AgeEligibilityFormValues.initial(),
      GroupFormFields.modeId: GroupMode.manual,
    });
  }

  @override
  State<GroupEligibilityFields> createState() => GroupEligibilityFieldsState();
}

/// State of [GroupEligibilityFields]: the mode the selector shows, which
/// decides whether the criteria group is mounted.
class GroupEligibilityFieldsState extends State<GroupEligibilityFields> {
  /// The mode currently selected.
  late GroupMode mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final editable = widget.enabled && !widget.criteriaLocked;
    final form = ShadForm.of(context);
    final resettable =
        widget.showReset &&
        !widget.criteriaLocked &&
        GroupEligibilityFields.holdsValue(form.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.sectionGap,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FormSpacing.rowGap,
          children: [
            GroupMembershipHeading(criteriaLocked: widget.criteriaLocked),
            LabeledFormRow(
              label: 'Mode',
              field: ShadSelectFormField<GroupMode>(
                id: GroupFormFields.modeId,
                initialValue: widget.initialMode,
                enabled: editable,
                options: [
                  for (final m in GroupMode.values)
                    ShadOption(value: m, child: Text(m.label)),
                ],
                selectedOptionBuilder: (context, value) => Text(value.label),
                onChanged: (value) {
                  if (value != null && value != mode) {
                    setState(() => mode = value);
                  }
                },
              ),
            ),
          ],
        ),
        if (mode.usesCriteria)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: FormSpacing.rowGap,
            children: [
              Text(
                GroupEligibilityFields.criteriaTitle,
                style: theme.textTheme.small,
              ),
              AgeEligibilityFields(enabled: editable),
              LabeledFormRow(
                label: 'Gender',
                field: ShadSelectFormField<GroupGender>(
                  id: GroupFormFields.genderId,
                  enabled: editable,
                  options: [
                    for (final g in GroupGender.values)
                      ShadOption(value: g, child: Text(g.label)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(value.label),
                ),
              ),
            ],
          ),
        if (resettable)
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.outline(
              onPressed: widget.enabled
                  ? () => GroupEligibilityFields.reset(form)
                  : null,
              child: const Text(FormStrings.reset),
            ),
          ),
      ],
    );
  }
}
