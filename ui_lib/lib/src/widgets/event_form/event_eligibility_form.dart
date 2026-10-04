import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'event_form_fields.dart';

/// Pure-UI editor for an event's eligibility — gender constraint plus the
/// date-of-birth window. Mirrors `GroupEligibilityForm` (without the group
/// membership-mode selector; event eligibility is always optional).
///
/// Host-agnostic: a caller (`cl_club_events`) embeds it and drives it through a
/// `GlobalKey<EventEligibilityFormState>`, calling
/// [EventEligibilityFormState.validate] from the Save action.
class EventEligibilityForm extends StatefulWidget {
  const EventEligibilityForm({required this.initialValues, super.key});

  /// Form values keyed by [EventFormFields]: optional [EventGender] gender and
  /// the two DOB-window `DateTime` bounds.
  final Map<String, dynamic> initialValues;

  @override
  State<EventEligibilityForm> createState() => EventEligibilityFormState();
}

class EventEligibilityFormState extends State<EventEligibilityForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? _formError;

  /// Validates (including the DOB-window ordering check). Returns the form
  /// values when valid, else `null` (and surfaces an inline error).
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final values = form.value;
    final after = values[EventFormFields.dobOnOrAfterId] as DateTime?;
    final before = values[EventFormFields.dobOnOrBeforeId] as DateTime?;
    if (after != null && before != null && after.isAfter(before)) {
      setState(
        () => _formError =
            '"DOB on or after" must not be later than "DOB on or before".',
      );
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
          Text(
            'Leave a field blank to place no constraint on that axis.',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 12),
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
          CLDatePickerFormField(
            id: EventFormFields.dobOnOrAfterId,
            label: const Text('DOB on or after'),
            placeholder: const Text('No lower bound'),
          ),
          const SizedBox(height: 12),
          CLDatePickerFormField(
            id: EventFormFields.dobOnOrBeforeId,
            label: const Text('DOB on or before'),
            placeholder: const Text('No upper bound'),
          ),
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
