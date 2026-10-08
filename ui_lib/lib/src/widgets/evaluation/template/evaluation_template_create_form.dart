import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_layout_callbacks.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../labeled_form_row.dart';
import '../common/evaluation_form_body.dart';
import '../common/evaluation_form_contract.dart';
import '../common/evaluation_form_focus.dart';
import 'evaluation_layout_form_field.dart';
import 'evaluation_template_create_form_fields.dart';
import 'evaluation_template_form_validators.dart';

/// Pure-UI form creating a new evaluation template (no SDK, no Riverpod): its
/// name, then its items and sections in the layout editor. One full create
/// form; an existing template is edited section by section instead.
///
/// Owns no buttons: the host calls
/// [EvaluationTemplateCreateFormState.validate] from its Create action,
/// checks [EvaluationTemplateCreateFormState.isDirty] before discarding and
/// shows a server refusal — a name already taken — with
/// [EvaluationTemplateCreateFormState.showErrors]. Item and section dialogs
/// are the host's, through [onEditItem] and [onEditSectionTitle] (see
/// `EvaluationLayoutEditor`).
class EvaluationTemplateCreateForm extends StatefulWidget {
  /// A create form seeded with [initialValues] (default [emptyValues]).
  const EvaluationTemplateCreateForm({
    required this.onEditItem,
    required this.onEditSectionTitle,
    this.onPickExisting,
    this.initialValues,
    this.enabled = true,
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

  /// Whether the fields can change (off while the host creates the
  /// template): the name and the layout editor grey, and stay on screen.
  final bool enabled;

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
    extends State<EvaluationTemplateCreateForm>
    with
        EvaluationFormContract<EvaluationTemplateCreateForm>,
        EvaluationFormFocus<EvaluationTemplateCreateForm> {
  // The layout field owns no focusable input.
  @override
  bool get focusFirstInvalid => false;

  /// The layout in [values], typed: ShadForm holds lists untyped.
  List<EvaluationLayoutEntry> layoutOf(Map<String, dynamic> values) => [
    for (final e
        in values[EvaluationTemplateCreateFormFields.layoutId] as List? ??
            const [])
      e as EvaluationLayoutEntry,
  ];

  /// The layout message: no question, or an untitled section.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      EvaluationTemplateFormValidators.layout(layoutOf(values));

  /// The new template: [EvaluationTemplateCreateFormFields.nameId] trimmed
  /// and [EvaluationTemplateCreateFormFields.layoutId] as a
  /// `List<EvaluationLayoutEntry>`.
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final name = values[EvaluationTemplateCreateFormFields.nameId] as String?;
    return {
      EvaluationTemplateCreateFormFields.nameId: (name ?? '').trim(),
      EvaluationTemplateCreateFormFields.layoutId: layoutOf(values),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue:
          widget.initialValues ?? EvaluationTemplateCreateForm.emptyValues,
      child: EvaluationFormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: EvaluationStrings.templateName,
            required: true,
            field: ShadInputFormField(
              id: EvaluationTemplateCreateFormFields.nameId,
              placeholder: const Text(
                EvaluationStrings.templateNamePlaceholder,
              ),
              keyboardType: TextInputType.text,
              enabled: widget.enabled,
              validator: EvaluationTemplateFormValidators.name,
            ),
          ),
          LabeledFormRow(
            label: EvaluationStrings.items,
            required: true,
            field: EvaluationLayoutFormField(
              id: EvaluationTemplateCreateFormFields.layoutId,
              enabled: widget.enabled,
              onEditItem: widget.onEditItem,
              onEditSectionTitle: widget.onEditSectionTitle,
              onPickExisting: widget.onPickExisting,
            ),
          ),
        ],
      ),
    );
  }
}
