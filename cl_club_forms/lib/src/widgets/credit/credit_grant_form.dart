import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'credit_date_field.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';
import 'credit_number_field.dart';
import 'credit_programme_option.dart';
import 'credit_reason_field.dart';

/// Add credit: a new account for a member (club_core#101). Pure UI, driven
/// through a `GlobalKey<CreditGrantFormState>` ([FormContract]).
class CreditGrantForm extends StatefulWidget {
  const CreditGrantForm({
    required this.programmes,
    required this.initialValues,
    this.today,
    this.enabled = true,
    super.key,
  });

  /// Programmes the credit may be bound to.
  final List<CreditProgrammeOption> programmes;

  /// Seed from [defaultValues].
  final Map<String, dynamic> initialValues;

  /// The day the validity window is checked against; now when null.
  final DateTime? today;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// How long a new account is valid by default.
  static const Duration defaultValidity = Duration(days: 90);

  /// What the programme select shows for a general (unbound) account.
  static const String generalLabel = 'General';

  /// A fresh grant from [today]: general unless [programmeId] is given, trial
  /// when [trial].
  static Map<String, dynamic> defaultValues({
    required DateTime today,
    int? programmeId,
    bool trial = false,
  }) {
    final from = DateTime(today.year, today.month, today.day);
    return {
      CreditFormFields.creditsId: '',
      CreditFormFields.validFromId: from,
      CreditFormFields.validUntilId: from.add(defaultValidity),
      CreditFormFields.programmeId:
          programmeId ?? CreditFormFields.generalProgramme,
      CreditFormFields.trialId: trial,
      CreditFormFields.reasonId: '',
    };
  }

  @override
  State<CreditGrantForm> createState() => CreditGrantFormState();
}

/// State of [CreditGrantForm]. Its values are credits (int), validFrom /
/// validUntil (local dates), programme (an option id, or
/// [CreditFormFields.generalProgramme]), trial (bool) and reason (trimmed).
class CreditGrantFormState extends State<CreditGrantForm>
    with FormContract<CreditGrantForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      CreditFormValidators.window(
        from: values[CreditFormFields.validFromId] as DateTime,
        until: values[CreditFormFields.validUntilId] as DateTime,
        today: widget.today ?? DateTime.now(),
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    CreditFormFields.creditsId: int.parse(
      (values[CreditFormFields.creditsId] as String).trim(),
    ),
    CreditFormFields.validFromId:
        values[CreditFormFields.validFromId] as DateTime,
    CreditFormFields.validUntilId:
        values[CreditFormFields.validUntilId] as DateTime,
    CreditFormFields.programmeId: values[CreditFormFields.programmeId] as int,
    CreditFormFields.trialId:
        values[CreditFormFields.trialId] as bool? ?? false,
    CreditFormFields.reasonId: (values[CreditFormFields.reasonId] as String)
        .trim(),
  };

  /// What the select shows for programme [id].
  String programmeTitle(int id) => id == CreditFormFields.generalProgramme
      ? CreditGrantForm.generalLabel
      : widget.programmes
            .firstWhere(
              (p) => p.id == id,
              orElse: () => CreditProgrammeOption(id: id, title: '#$id'),
            )
            .title;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      child: FormBody(
        error: formError,
        children: [
          CreditNumberField(
            id: CreditFormFields.creditsId,
            label: 'Credits',
            enabled: enabled,
          ),
          CreditDateField(
            id: CreditFormFields.validFromId,
            label: 'Valid from',
            enabled: enabled,
          ),
          CreditDateField(
            id: CreditFormFields.validUntilId,
            label: 'Valid until',
            enabled: enabled,
          ),
          LabeledFormRow(
            label: 'Programme',
            field: ShadSelectFormField<int>(
              id: CreditFormFields.programmeId,
              enabled: enabled,
              options: [
                const ShadOption(
                  value: CreditFormFields.generalProgramme,
                  child: Text(CreditGrantForm.generalLabel),
                ),
                for (final p in widget.programmes)
                  ShadOption(value: p.id, child: Text(p.title)),
              ],
              selectedOptionBuilder: (context, id) => Text(programmeTitle(id)),
            ),
          ),
          ShadSwitchFormField(
            id: CreditFormFields.trialId,
            initialValue:
                widget.initialValues[CreditFormFields.trialId] as bool? ??
                false,
            enabled: enabled,
            inputLabel: const Text('Trial'),
          ),
          CreditReasonField(enabled: enabled),
        ],
      ),
    );
  }
}
