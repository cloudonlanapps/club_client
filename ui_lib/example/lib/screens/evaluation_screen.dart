import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo of the evaluation widgets: the template designer (create form with
/// the host's item and section dialogs), the fill form, and the read body
/// showing what was filled in.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

const _sample = [
  EvaluationLayoutEntry.item(
    EvaluationItemValue(
      id: 1,
      kind: EvaluationItemKind.info,
      text: 'Rate what you saw **this term**.',
    ),
  ),
  EvaluationLayoutEntry.section(
    title: 'Skating',
    items: [
      EvaluationItemValue(
        id: 2,
        kind: EvaluationItemKind.rating,
        text: 'Forward stride',
        isRequired: true,
        showCommentArea: true,
        requireCommentFor: [1],
        allowEvidence: true,
        scale: EvaluationRatingScale.levels([
          'Needs work',
          'Developing',
          'Good',
          'Excellent',
        ]),
      ),
      EvaluationItemValue(
        id: 3,
        kind: EvaluationItemKind.rating,
        text: 'Effort',
        scale: EvaluationRatingScale.stars(),
      ),
      EvaluationItemValue(
        id: 4,
        kind: EvaluationItemKind.rating,
        text: 'Balance',
        scale: EvaluationRatingScale.range(min: 1, max: 10),
      ),
      EvaluationItemValue(
        id: 5,
        kind: EvaluationItemKind.yesNo,
        text: 'Stops on both sides',
      ),
    ],
  ),
  EvaluationLayoutEntry.item(
    EvaluationItemValue(
      id: 6,
      kind: EvaluationItemKind.multipleChoice,
      text: 'Strong areas',
      choices: [
        EvaluationChoice(value: 'edges', text: 'Edges'),
        EvaluationChoice(value: 'crossovers', text: 'Crossovers'),
      ],
    ),
  ),
  EvaluationLayoutEntry.item(
    EvaluationItemValue(
      id: 7,
      kind: EvaluationItemKind.qa,
      text: 'What to work on next',
      isRequired: true,
    ),
  ),
];

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _createKey = GlobalKey<EvaluationTemplateCreateFormState>();
  final _fillKey = GlobalKey<EvaluationFillBodyState>();
  final _answers = <int, EvaluationAnswerValue>{};
  String _status = '';

  Future<EvaluationOutlineEdit<EvaluationItemValue>?> _editItem(
    EvaluationItemValue item,
  ) async {
    final edited = await _editItemValue(item);
    return edited == null ? null : EvaluationOutlineEdit.update(edited);
  }

  Future<EvaluationItemValue?> _editItemValue(EvaluationItemValue item) {
    final formKey = GlobalKey<EvaluationItemFormState>();
    return showShadDialog<EvaluationItemValue>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: Text(item.kind.label),
        constraints: const BoxConstraints(
          maxWidth: EvaluationSpacing.itemDialogWidth,
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: () {
              final values = formKey.currentState?.validate();
              if (values == null) return;
              Navigator.of(dialogContext).pop(
                EvaluationItemFormValues.toItem(
                  values,
                  kind: item.kind,
                  id: item.id,
                ),
              );
            },
            child: Text(item.id == null && item.text.isEmpty ? 'Add' : 'Save'),
          ),
        ],
        child: EvaluationItemForm(
          key: formKey,
          kind: item.kind,
          initialValues: EvaluationItemFormValues.fromItem(item),
        ),
      ),
    );
  }

  Future<EvaluationOutlineEdit<String>?> _editSectionTitle(
    String? title,
  ) async {
    final edited = await _editSectionTitleValue(title);
    return edited == null ? null : EvaluationOutlineEdit.update(edited);
  }

  Future<String?> _editSectionTitleValue(String? title) {
    final formKey = GlobalKey<RenameFormState>();
    return showShadDialog<String>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Section'),
        actions: [
          ShadButton(
            onPressed: () {
              final value =
                  formKey.currentState?.validate()?[RenameFormFields.valueId]
                      as String?;
              if (value != null) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
        child: RenameForm(
          key: formKey,
          initialValue: title ?? '',
          label: 'Section title',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadTabs<String>(
      value: 'design',
      tabs: [
        ShadTab(
          value: 'design',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EvaluationTemplateCreateForm(
                key: _createKey,
                onEditItem: _editItem,
                onEditSectionTitle: _editSectionTitle,
              ),
              const SizedBox(height: 16),
              ShadButton(
                onPressed: () {
                  final value = _createKey.currentState?.validate();
                  setState(() => _status = value?.toString() ?? '');
                },
                child: const Text('Create'),
              ),
              if (_status.isNotEmpty)
                Text(_status, style: theme.textTheme.muted),
            ],
          ),
          child: const Text('Design'),
        ),
        ShadTab(
          value: 'fill',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EvaluationFillBody(
                key: _fillKey,
                layout: _sample,
                initialAnswers: _answers,
                onAnswerChanged: (id, answer) => _answers[id] = answer,
                evidenceBuilder: (id) => Text(
                  'Evidence slot for item $id',
                  style: theme.textTheme.muted,
                ),
              ),
              const SizedBox(height: 16),
              ShadButton(
                onPressed: () {
                  final blocking = _fillKey.currentState?.validateForSave();
                  setState(() => _status = 'Blocking items: $blocking');
                },
                child: const Text('Save'),
              ),
              if (_status.isNotEmpty)
                Text(_status, style: theme.textTheme.muted),
            ],
          ),
          child: const Text('Fill'),
        ),
        ShadTab(
          value: 'read',
          content: EvaluationReadBody(
            layout: _sample,
            answers: Map.of(_answers),
          ),
          child: const Text('Read'),
        ),
      ],
    );
  }
}
