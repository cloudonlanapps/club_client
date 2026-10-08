import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'group_eligibility_fields.dart';
import 'group_form_fields.dart';
import 'group_form_validators.dart';

/// Pure-UI group creation form (no SDK / no Riverpod).
///
/// Name + description + the shared [GroupEligibilityFields] cluster + the
/// create-only "add me" switch. Speaks flat form values; the caller's adapter
/// (`cl_club_members` `group_form_helpers`) maps what `validate()` returns to
/// the SDK create call.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<GroupCreateFormState>` — `validate()` from its Create action,
/// `isDirty` for the discard prompt, `showErrors()` with what the server
/// refuses ([FormContract]).
class GroupCreateForm extends StatefulWidget {
  const GroupCreateForm({
    this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// Optional starting values; defaults to [emptyValues].
  final Map<String, dynamic>? initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Default values for a fresh group: manual mode, Gender on Any, nothing
  /// else set.
  static Map<String, dynamic> get emptyValues => {
    GroupFormFields.nameId: '',
    GroupFormFields.descriptionId: '',
    GroupFormFields.modeId: GroupMode.manual,
    GroupFormFields.genderId: GroupGender.any,
    GroupFormFields.addMeId: false,
    ...AgeEligibilityFormValues.initial(),
  };

  @override
  State<GroupCreateForm> createState() => GroupCreateFormState();
}

/// State of [GroupCreateForm]. Its values are the [GroupFormFields] entries
/// and the age cluster's, as the fields hold them.
class GroupCreateFormState extends State<GroupCreateForm>
    with FormContract<GroupCreateForm> {
  /// What the form starts with; Gender is on Any when the host gave none.
  Map<String, dynamic> get initialValues => GroupEligibilityFields.seeded(
    widget.initialValues ?? GroupCreateForm.emptyValues,
  );

  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      GroupFormValidators.eligibility(values);

  @override
  Widget build(BuildContext context) {
    final initial = initialValues;
    final initialMode =
        initial[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;

    return ShadForm(
      key: formKey,
      initialValue: initial,
      // Rebuilds the eligibility block, whose Clear shows only while it
      // holds a value.
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FormSpacing.sectionGap,
        children: [
          FormBody(
            children: [
              LabeledFormRow(
                label: 'Group Name',
                required: true,
                field: ShadInputFormField(
                  id: GroupFormFields.nameId,
                  placeholder: const Text('e.g., U12 Boys'),
                  keyboardType: TextInputType.name,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: widget.enabled,
                  validator: GroupFormValidators.name,
                ),
              ),
              LabeledFormRow(
                label: 'Description',
                field: ShadInputFormField(
                  id: GroupFormFields.descriptionId,
                  placeholder: const Text('Optional description'),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  enabled: widget.enabled,
                ),
              ),
            ],
          ),
          GroupEligibilityFields(
            initialMode: initialMode,
            showClear: true,
            enabled: widget.enabled,
          ),
          FormBody(
            error: formError,
            children: [
              ShadSwitchFormField(
                id: GroupFormFields.addMeId,
                initialValue:
                    initial[GroupFormFields.addMeId] as bool? ?? false,
                enabled: widget.enabled,
                inputLabel: const Text('Add me into the group'),
                inputSublabel: const Text(
                  'Automatically enroll yourself as a member after the group '
                  'is created.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
