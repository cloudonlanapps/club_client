import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_choice_option.dart';
import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_fact_type.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import 'application_fact_type_select.dart';
import 'application_fact_value_inputs.dart';
import 'application_fact_values.dart';

/// Edits one fact of an application: its name, its type and its value.
/// What was given for one type is kept while another is tried.
///
/// It reports the fact as a row (`ApplicationFactValues.row`) through
/// [onChanged] on every edit; it is seeded once from [initial].
class ApplicationFactEditor extends StatefulWidget {
  const ApplicationFactEditor({
    required this.initial,
    required this.languages,
    required this.choices,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The fact to start from, as a row; null for a new one.
  final Object? initial;

  /// The print languages a name may be given in.
  final List<ApplicationLanguageOption> languages;

  /// The library's choices.
  final List<ApplicationChoiceOption> choices;

  /// Called with the fact after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationFactEditor> createState() => ApplicationFactEditorState();
}

/// State of [ApplicationFactEditor]: the name, the type, and the value of
/// each type.
class ApplicationFactEditorState extends State<ApplicationFactEditor> {
  /// The fact's name.
  late final TextEditingController name;

  /// The fact's type.
  ApplicationFactType type = ApplicationFactType.name;

  /// A name's value.
  ApplicationTextValue? nameValue;

  /// A date's day; `''` for none.
  String day = '';

  /// A range's first day; `''` for none.
  String from = '';

  /// A range's last day; `''` for none.
  String to = '';

  /// A time's hour and minute.
  late final ShadTimePickerController time;

  /// An amount's digits.
  late final TextEditingController amount;

  /// The choices ticked.
  List<String> choices = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final row = initial is Map ? initial : const <Object?, Object?>{};
    final value = row[ApplicationFormFields.valueKey];
    name = TextEditingController(
      text: ApplicationFactValues.text(row[ApplicationFormFields.nameKey]),
    );
    type =
        ApplicationFactType.fromJson(row[ApplicationFormFields.typeKey]) ??
        ApplicationFactType.name;
    final parts = value is String && type == ApplicationFactType.time
        ? value.split(':').map(int.tryParse).toList()
        : const <int?>[];
    time = ShadTimePickerController(
      hour: parts.isNotEmpty ? parts.first : null,
      minute: parts.length > 1 ? parts[1] : null,
      second: 0,
    )..addListener(report);
    amount = TextEditingController(
      text: type == ApplicationFactType.amount && value is int ? '$value' : '',
    );
    switch (type) {
      case ApplicationFactType.name:
        nameValue = ApplicationTextValue.fromJson(
          value is String ? {ApplicationFormFields.english: value} : value,
        );
      case ApplicationFactType.date:
        day = ApplicationFactValues.text(value);
      case ApplicationFactType.dateRange:
        from = ApplicationFactValues.text(row[ApplicationFormFields.fromKey]);
        to = ApplicationFactValues.text(row[ApplicationFormFields.toKey]);
      case ApplicationFactType.choices:
        choices = [if (value is List) ...value.whereType<String>()];
      case ApplicationFactType.time || ApplicationFactType.amount:
        break;
    }
  }

  @override
  void dispose() {
    name.dispose();
    time.dispose();
    amount.dispose();
    super.dispose();
  }

  /// The time typed, `HH:MM`; `''` until both parts are.
  String get timeText {
    final hour = time.hour;
    final minute = time.minute;
    if (hour == null || minute == null) return '';
    String two(int part) => part.toString().padLeft(2, '0');
    return '${two(hour)}:${two(minute)}';
  }

  /// The fact as it is now, as a row.
  Map<String, Object?> get current => ApplicationFactValues.row(
    name.text.trim(),
    {
      ApplicationFormFields.typeKey: type.jsonName,
      ApplicationFormFields.fromKey: from,
      ApplicationFormFields.toKey: to,
      ApplicationFormFields.valueKey: switch (type) {
        ApplicationFactType.name => switch (nameValue) {
          ApplicationCustomText(:final text) => text,
          _ => '',
        },
        ApplicationFactType.date => day,
        ApplicationFactType.dateRange => null,
        ApplicationFactType.time => timeText,
        ApplicationFactType.amount => int.tryParse(amount.text.trim()),
        ApplicationFactType.choices => choices,
      },
    },
  );

  /// Reports the fact.
  void report() => widget.onChanged(current);

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    setState(changed);
    report();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.rowGap,
      children: [
        LabeledFormRow(
          label: ApplicationFormStrings.factName,
          required: true,
          field: ShadInput(
            controller: name,
            enabled: widget.enabled,
            keyboardType: TextInputType.text,
            onChanged: (_) => report(),
          ),
        ),
        ApplicationFactTypeSelect(
          value: type,
          enabled: widget.enabled,
          onChanged: (option) => update(() => type = option),
        ),
        ApplicationFactValueInputs(
          editor: this,
          languages: widget.languages,
          choices: widget.choices,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}
