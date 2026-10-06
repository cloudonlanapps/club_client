import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_validators.dart';
import '../age_eligibility/age_eligibility_form_values.dart';
import 'event_form_fields.dart';

/// Pure-UI editor for an event's eligibility — gender constraint plus the
/// age band (the shared [AgeEligibilityFields] cluster). Mirrors
/// `GroupEligibilityForm` (without the group membership-mode selector; event
/// eligibility is always optional).
///
/// Host-agnostic: a caller (`cl_club_events`) embeds it and drives it through a
/// `GlobalKey<EventEligibilityFormState>`, calling
/// [EventEligibilityFormState.validate] from the Save action.
class EventEligibilityForm extends StatefulWidget {
  const EventEligibilityForm({
    required this.initialValues,
    this.onChanged,
    super.key,
  });

  /// Form values: optional [EventGender] gender under
  /// [EventFormFields.genderId], and the age cluster's entries
  /// (`AgeEligibilityFormValues.initial`).
  final Map<String, dynamic> initialValues;

  /// Called whenever a field's value changes, a reset included, so the host
  /// can re-read [EventEligibilityFormState.hasValue].
  final VoidCallback? onChanged;

  /// Whether [values] hold any eligibility: a gender, an age or a ticked
  /// Strict age check.
  static bool holdsValue(Map<String, dynamic> values) =>
      values[EventFormFields.genderId] != null ||
      AgeEligibilityFormValues.holdsValue(values);

  @override
  State<EventEligibilityForm> createState() => EventEligibilityFormState();
}

class EventEligibilityFormState extends State<EventEligibilityForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? _formError;

  /// Validates (including the age band: every part within its limit, the
  /// minimum not above the maximum). Returns the form values when valid,
  /// else `null` (and surfaces an inline error).
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final values = form.value;
    final error = AgeEligibilityFormValidators.band(values);
    if (error != null) {
      setState(() => _formError = error);
      return null;
    }
    if (_formError != null) setState(() => _formError = null);
    return values;
  }

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
    if (_formError != null) setState(() => _formError = null);
  }

  /// Whether any field differs from the seeded initial values.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !mapEquals(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      onChanged: widget.onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadSelectFormField<EventGender>(
            id: EventFormFields.genderId,
            label: const Text('Gender'),
            placeholder: const Text('Any gender'),
            options: [
              for (final g in EventGender.values)
                ShadOption(value: g, child: Text(g.label)),
            ],
            selectedOptionBuilder: (context, value) => Text(value.label),
          ),
          const SizedBox(height: 12),
          const AgeEligibilityFields(),
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
