import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_layout_callbacks.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../models/evaluation_template_create_value.dart';
import '../../../utils/evaluation_form_equality.dart';
import 'evaluation_layout_form_field.dart';
import 'evaluation_template_create_form_fields.dart';
import 'evaluation_template_form_validators.dart';

/// Pure-UI form creating a new evaluation template (no SDK, no Riverpod): its
/// name, then its items and sections in the layout editor. One full create
/// form; an existing template is edited section by section instead.
///
/// Owns no buttons: the host calls
/// [EvaluationTemplateCreateFormState.handleSubmit] from its Create action
/// and checks [EvaluationTemplateCreateFormState.isDirty] before
/// discarding. Item and section dialogs are the host's, through
/// [onEditItem] and [onEditSectionTitle] (see `EvaluationLayoutEditor`).
class EvaluationTemplateCreateForm extends StatefulWidget {
  /// A create form seeded with [initialValues] (default [emptyValues]).
  const EvaluationTemplateCreateForm({
    required this.onEditItem,
    required this.onEditSectionTitle,
    this.onPickExisting,
    this.initialValues,
    this.isSubmitting = false,
    super.key,
  });

  /// Edits an item through the host's dialog.
  final EvaluationEditItem onEditItem;

  /// Edits a section's title through the host's dialog.
  final EvaluationEditSectionTitle onEditSectionTitle;

  /// Picks an existing question to copy; `null` hides the option.
  final EvaluationPickExisting? onPickExisting;

  /// Initial values keyed by [EvaluationTemplateCreateFormFields].
  final Map<String, dynamic>? initialValues;

  /// Disables editing while the host creates the template.
  final bool isSubmitting;

  /// A blank template: no name, no items.
  static Map<String, dynamic> get emptyValues => {
    EvaluationTemplateCreateFormFields.nameId: '',
    EvaluationTemplateCreateFormFields.layoutId:
        const <EvaluationLayoutEntry>[],
  };

  @override
  State<EvaluationTemplateCreateForm> createState() =>
      EvaluationTemplateCreateFormState();
}

/// State of [EvaluationTemplateCreateForm]: the form and its form-level
/// message.
class EvaluationTemplateCreateFormState
    extends State<EvaluationTemplateCreateForm> {
  /// The form.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The form-level message (no question, an untitled section), or `null`.
  String? formError;

  /// Validates the name (error under the field) and the layout (message
  /// under the form). Returns the new template, name trimmed, or `null`.
  EvaluationTemplateCreateValue? handleSubmit() {
    final form = formKey.currentState;
    if (form == null) return null;
    // The layout field owns no focusable input, so nothing is focused.
    final fieldsValid = form.saveAndValidate(focusOnInvalid: false);
    final values = form.value;
    final layout = [
      for (final e
          in values[EvaluationTemplateCreateFormFields.layoutId] as List? ??
              const [])
        e as EvaluationLayoutEntry,
    ];
    final error = EvaluationTemplateFormValidators.layout(layout);
    setState(() => formError = error);
    if (!fieldsValid || error != null) return null;
    final name = values[EvaluationTemplateCreateFormFields.nameId] as String?;
    return EvaluationTemplateCreateValue(
      name: (name ?? '').trim(),
      layout: layout,
    );
  }

  /// Shows [message] under the name — the host's server refusal, e.g. a
  /// name already taken. The next [handleSubmit] clears it.
  void setNameError(String message) => formKey
      .currentState
      ?.fields[EvaluationTemplateCreateFormFields.nameId]
      ?.setError(message);

  /// Whether the name or the layout differs from the initial values.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !EvaluationFormEquality.mapsEqual(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final error = formError;
    return ShadForm(
      key: formKey,
      initialValue:
          widget.initialValues ?? EvaluationTemplateCreateForm.emptyValues,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EvaluationSpacing.elementGap,
        children: [
          ShadInputFormField(
            id: EvaluationTemplateCreateFormFields.nameId,
            label: const Text(EvaluationStrings.templateName),
            placeholder: const Text(EvaluationStrings.templateNamePlaceholder),
            keyboardType: TextInputType.text,
            enabled: !widget.isSubmitting,
            validator: EvaluationTemplateFormValidators.name,
          ),
          EvaluationLayoutFormField(
            id: EvaluationTemplateCreateFormFields.layoutId,
            label: EvaluationStrings.items,
            readOnly: widget.isSubmitting,
            onEditItem: widget.onEditItem,
            onEditSectionTitle: widget.onEditSectionTitle,
            onPickExisting: widget.onPickExisting,
            // A fixed layout clears the message about it.
            onChanged: (_) {
              if (formError != null) setState(() => formError = null);
            },
          ),
          if (error != null)
            Text(
              error,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }
}
