import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../age_eligibility/age_eligibility_fields.dart';
import '../age_eligibility/age_eligibility_form_validators.dart';
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
  const EventEligibilityForm({required this.initialValues, super.key});

  /// Form values: optional [EventGender] gender under
  /// [EventFormFields.genderId], and the age cluster's entries
  /// (`AgeEligibilityFormValues.initial`).
  final Map<String, dynamic> initialValues;

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
