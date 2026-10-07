import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_validators.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_form_fields.dart';

/// Pure-UI editor for an event's eligibility — gender constraint plus the
/// age band (the shared [AgeEligibilityFields] cluster). Mirrors
/// `GroupEligibilityForm` (without the group membership-mode selector; event
/// eligibility is always optional).
///
/// Host-agnostic: a caller (`cl_club_events`) embeds it and drives it through
/// a `GlobalKey<EventEligibilityFormState>` ([FormContract]).
class EventEligibilityForm extends StatefulWidget {
  const EventEligibilityForm({
    required this.initialValues,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Form values: optional [EventGender] gender under
  /// [EventFormFields.genderId], and the age cluster's entries
  /// (`AgeEligibilityFormValues.initial`).
  final Map<String, dynamic> initialValues;

  /// Called whenever a field's value changes, a reset included, so the host
  /// can re-read [EventEligibilityFormState.hasValue].
  final VoidCallback? onChanged;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether [values] hold any eligibility: a gender, an age or a ticked
  /// Strict age check.
  static bool holdsValue(Map<String, dynamic> values) =>
      values[EventFormFields.genderId] != null ||
      AgeEligibilityFormValues.holdsValue(values);

  @override
  State<EventEligibilityForm> createState() => EventEligibilityFormState();
}

/// State of [EventEligibilityForm]. Its values are the gender and the age
/// cluster's entries, as the form holds them.
class EventEligibilityFormState extends State<EventEligibilityForm>
    with FormContract<EventEligibilityForm> {
  /// The age band: every part within its limit, the minimum not above the
  /// maximum.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      AgeEligibilityFormValidators.band(values);

  /// Whether the form holds any eligibility a [reset] would empty.
  bool get hasValue {
    final form = formKey.currentState;
    return form != null && EventEligibilityForm.holdsValue(form.value);
  }

  /// Empties gender, both ages and the Strict age check. Nothing is stored:
  /// the form is then changed, and the host's Save sends the empty
  /// eligibility.
  void reset() {
    formKey.currentState?.setValue({
      EventFormFields.genderId: null,
      ...AgeEligibilityFormValues.initial(),
    });
    setFormError(null);
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      onChanged: widget.onChanged,
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Gender',
            field: ShadSelectFormField<EventGender>(
              id: EventFormFields.genderId,
              enabled: widget.enabled,
              placeholder: const Text('Any gender'),
              options: [
                for (final g in EventGender.values)
                  ShadOption(value: g, child: Text(g.label)),
              ],
              selectedOptionBuilder: (context, value) => Text(value.label),
            ),
          ),
          AgeEligibilityFields(enabled: widget.enabled),
        ],
      ),
    );
  }
}
