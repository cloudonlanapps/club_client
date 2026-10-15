import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_validators.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import '../gender_eligibility/gender_eligibility_field.dart';
import '../gender_eligibility/gender_eligibility_form_values.dart';

/// Pure-UI editor for an event's eligibility — the genders it is open to
/// (the shared [GenderEligibilityField]) plus the age band (the shared
/// [AgeEligibilityFields] cluster). Mirrors
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

  /// Form values: the gender field's entry
  /// (`GenderEligibilityFormValues.initial`, none ticked when left out) and
  /// the age cluster's entries (`AgeEligibilityFormValues.initial`).
  final Map<String, dynamic> initialValues;

  /// Called whenever a field's value changes, a clear included, so the host
  /// can re-read [EventEligibilityFormState.hasValue].
  final VoidCallback? onChanged;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether [values] hold any eligibility: a ticked gender, an age or a
  /// ticked Strict age check.
  static bool holdsValue(Map<String, dynamic> values) =>
      GenderEligibilityFormValues.holdsValue(values) ||
      AgeEligibilityFormValues.holdsValue(values);

  /// [values] with the genders entry always present (none ticked when they
  /// hold none), so a form nobody touched is not dirty.
  static Map<String, dynamic> seeded(Map<String, dynamic> values) => {
    ...values,
    ...GenderEligibilityFormValues.initial(
      GenderEligibilityFormValues.genders(values),
    ),
  };

  @override
  State<EventEligibilityForm> createState() => EventEligibilityFormState();
}

/// State of [EventEligibilityForm]. Its values are the ticked genders (none
/// is no gender criterion) and the age cluster's entries, as the form holds
/// them.
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

  /// Unticks every gender and empties both ages and the Strict age check.
  /// Nothing is stored: the form is then changed, and the host's Save sends
  /// the empty eligibility.
  void clear() {
    formKey.currentState?.setValue({
      ...GenderEligibilityFormValues.initial(),
      ...AgeEligibilityFormValues.initial(),
    });
    setFormError(null);
  }

  /// Whether the genders, an age or the Strict age check changed. The
  /// genders are a list, compared as a set
  /// ([GenderEligibilityFormValues.differ]).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    return form != null &&
        GenderEligibilityFormValues.differ(form.initialValue, form.value);
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
            field: GenderEligibilityField(enabled: widget.enabled),
          ),
          AgeEligibilityFields(enabled: widget.enabled),
        ],
      ),
    );
  }
}
