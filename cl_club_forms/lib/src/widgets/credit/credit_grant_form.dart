import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';
import 'credit_date_field.dart';
import 'credit_form_body.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';
import 'credit_number_field.dart';
import 'credit_programme_option.dart';
import 'credit_reason_field.dart';

/// Add credit: a new account for a member (club_core#101). Pure UI, driven
/// through a `GlobalKey<CreditGrantFormState>`: [CreditGrantFormState.validate]
/// returns the flat values, or null when invalid.
///
/// Values: credits (int), validFrom / validUntil (local dates), programme
/// (an option id, or [CreditFormFields.generalProgramme]), trial (bool),
/// reason (trimmed).
class CreditGrantForm extends StatefulWidget {
  const CreditGrantForm({
    required this.programmes,
    required this.initialValues,
    super.key,
  });

  /// Programmes the credit may be bound to.
  final List<CreditProgrammeOption> programmes;

  /// Seed from [defaultValues].
  final Map<String, dynamic> initialValues;

  /// How long a new account is valid by default.
  static const Duration defaultValidity = Duration(days: 90);

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

class CreditGrantFormState extends State<CreditGrantForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? error;

  /// Validates; returns the flat values, or null (with an inline message for
  /// a cross-field rule).
  Map<String, dynamic>? validate({DateTime? today}) {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final v = form.value;
    final from = v[CreditFormFields.validFromId] as DateTime;
    final until = v[CreditFormFields.validUntilId] as DateTime;
    final windowError = CreditFormValidators.window(
      from: from,
      until: until,
      today: today ?? DateTime.now(),
    );
    setState(() => error = windowError);
    if (windowError != null) return null;
    return {
      CreditFormFields.creditsId: int.parse(
        (v[CreditFormFields.creditsId] as String).trim(),
      ),
      CreditFormFields.validFromId: from,
      CreditFormFields.validUntilId: until,
      CreditFormFields.programmeId: v[CreditFormFields.programmeId] as int,
      CreditFormFields.trialId: v[CreditFormFields.trialId] as bool? ?? false,
      CreditFormFields.reasonId: (v[CreditFormFields.reasonId] as String)
          .trim(),
    };
  }

  String programmeTitle(int id) => id == CreditFormFields.generalProgramme
      ? 'General'
      : widget.programmes
            .firstWhere(
              (p) => p.id == id,
              orElse: () => CreditProgrammeOption(id: id, title: '#$id'),
            )
            .title;

  @override
  Widget build(BuildContext context) {
    return CreditFormBody(
      formKey: formKey,
      initialValue: widget.initialValues,
      error: error,
      fields: [
        const CreditNumberField(
          id: CreditFormFields.creditsId,
          label: 'Credits',
        ),
        const CreditDateField(
          id: CreditFormFields.validFromId,
          label: 'Valid from',
        ),
        const CreditDateField(
          id: CreditFormFields.validUntilId,
          label: 'Valid until',
        ),
        LabeledFormRow(
          label: 'Programme',
          field: ShadSelectFormField<int>(
            id: CreditFormFields.programmeId,
            options: [
              const ShadOption(
                value: CreditFormFields.generalProgramme,
                child: Text('General'),
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
              widget.initialValues[CreditFormFields.trialId] as bool? ?? false,
          inputLabel: const Text('Trial'),
        ),
        const CreditReasonField(),
      ],
    );
  }
}
