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

  /// Form values: the [EventGender] under [EventFormFields.genderId]
  /// ([EventGender.any] when left out), and the age cluster's entries
  /// (`AgeEligibilityFormValues.initial`).
  final Map<String, dynamic> initialValues;

  /// Called whenever a field's value changes, a clear included, so the host
  /// can re-read [EventEligibilityFormState.hasValue].
  final VoidCallback? onChanged;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether [values] hold any eligibility: Boys or Girls, an age or a
  /// ticked Strict age check. Gender on Any is none.
  static bool holdsValue(Map<String, dynamic> values) =>
      EventGender.of(values).isCriterion ||
      AgeEligibilityFormValues.holdsValue(values);

  /// [values] with Gender on Any when they hold no gender, so the field
  /// always shows an entry and a form nobody touched is not dirty.
  static Map<String, dynamic> seeded(Map<String, dynamic> values) => {
    ...values,
    EventFormFields.genderId: EventGender.of(values),
  };

  @override
  State<EventEligibilityForm> createState() => EventEligibilityFormState();
}

/// State of [EventEligibilityForm]. Its values are the gender (never null:
/// [EventGender.any] is no gender criterion) and the age cluster's entries,
/// as the form holds them.
class EventEligibilityFormState extends State<EventEligibilityForm>
    with FormContract<EventEligibilityForm> {
  /// The age band: every part within its limit, the minimum not above the
  /// maximum.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      AgeEligibilityFormValidators.band(values);

  /// Whether the form holds any eligibility a [clear] would empty.
  bool get hasValue {
    final form = formKey.currentState;
    return form != null && EventEligibilityForm.holdsValue(form.value);
  }

  /// Puts Gender back to Any and empties both ages and the Strict age check.
  /// Nothing is stored: the form is then changed, and the host's Save sends
  /// the empty eligibility.
  void clear() {
    formKey.currentState?.setValue({
      EventFormFields.genderId: EventGender.any,
      ...AgeEligibilityFormValues.initial(),
    });
    setFormError(null);
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: EventEligibilityForm.seeded(widget.initialValues),
      onChanged: widget.onChanged,
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Gender',
            field: ShadSelectFormField<EventGender>(
              id: EventFormFields.genderId,
              enabled: widget.enabled,
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
