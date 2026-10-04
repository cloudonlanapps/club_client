import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'group_eligibility_fields.dart';
import 'group_form_fields.dart';
import 'group_form_validators.dart';

/// Pure-UI group creation form (no SDK / no Riverpod).
///
/// Name + description + the shared [GroupEligibilityFields] cluster + the
/// create-only "add me" switch. Speaks flat form values; the caller's adapter
/// (`cl_club_members` `group_form_helpers`) maps the returned map to the SDK
/// create call.
class GroupCreateForm extends StatefulWidget {
  const GroupCreateForm({
    required this.onSubmit,
    this.title,
    this.initialValues,
    this.isSubmitting = false,
    super.key,
  });

  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final String? title;
  final Map<String, dynamic>? initialValues;
  final bool isSubmitting;

  /// Default values for a fresh group: manual mode, nothing else set.
  static Map<String, dynamic> get emptyValues => {
    GroupFormFields.nameId: '',
    GroupFormFields.descriptionId: '',
    GroupFormFields.modeId: GroupMode.manual,
    GroupFormFields.addMeId: false,
  };

  @override
  State<GroupCreateForm> createState() => GroupCreateFormState();
}

class GroupCreateFormState extends State<GroupCreateForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? _formError;

  Map<String, dynamic> get _initial =>
      widget.initialValues ?? GroupCreateForm.emptyValues;

  bool get isDirty {
    formKey.currentState?.save();
    final current = formKey.currentState?.value ?? {};
    final initial = formKey.currentState?.initialValue ?? {};
    return !mapEquals(_normalize(initial), _normalize(current));
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String && value.trim().isEmpty) return MapEntry(key, null);
      return MapEntry(key, value);
    });
  }

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();
    final values = form.value;

    final error = groupEligibilityError(values);
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() => _formError = null);
    await widget.onSubmit(values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initialMode =
        _initial[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;

    return ShadForm(
      key: formKey,
      initialValue: _initial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null) ...[
            Text(widget.title!, style: theme.textTheme.h4),
            const SizedBox(height: 16),
          ],
          ShadInputFormField(
            id: GroupFormFields.nameId,
            label: const Text('Group Name'),
            placeholder: const Text('e.g., U12 Boys'),
            keyboardType: TextInputType.name,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !widget.isSubmitting,
            validator: GroupFormValidators.name,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: GroupFormFields.descriptionId,
            label: const Text('Description'),
            placeholder: const Text('Optional description'),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            enabled: !widget.isSubmitting,
          ),
          const SizedBox(height: 16),
          GroupEligibilityFields(initialMode: initialMode),
          const SizedBox(height: 16),
          ShadSwitchFormField(
            id: GroupFormFields.addMeId,
            initialValue: _initial[GroupFormFields.addMeId] as bool? ?? false,
            enabled: !widget.isSubmitting,
            inputLabel: const Text('Add me into the group'),
            inputSublabel: const Text(
              'Automatically enroll yourself as a member after the group '
              'is created.',
            ),
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

/// Cross-field eligibility validation shared by the create form and the
/// eligibility editor. Returns an error message, or `null` when valid.
String? groupEligibilityError(Map<String, dynamic> values) {
  final mode = values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
  final after = values[GroupFormFields.dobOnOrAfterId] as DateTime?;
  final before = values[GroupFormFields.dobOnOrBeforeId] as DateTime?;
  final gender = values[GroupFormFields.genderId] as GroupGender?;
  return GroupFormValidators.dobRange(after, before) ??
      GroupFormValidators.criteriaForMode(
        mode,
        hasAnyCriterion: after != null || before != null || gender != null,
      );
}
