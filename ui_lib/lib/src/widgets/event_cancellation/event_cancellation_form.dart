import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../event_schedule/labeled_form_row.dart';
import 'event_cancellation_form_fields.dart';
import 'event_cancellation_form_validators.dart';
import 'event_cancellation_session.dart';

/// Pure-UI form for calling an event off (no SDK / no Riverpod): a reason,
/// and, when [sessions] are given, the upcoming session the cancellation
/// starts from (a camp is cancelled from a session onward; a one-off has
/// none to choose).
///
/// The form owns no buttons or dialog: the host drives it through a
/// `GlobalKey<EventCancellationFormState>` and calls
/// [EventCancellationFormState.validate] from its confirm action.
class EventCancellationForm extends StatefulWidget {
  const EventCancellationForm({
    this.sessions = const [],
    this.reasonPlaceholder = 'e.g., Venue unavailable',
    this.enabled = true,
    super.key,
  });

  /// The sessions the cancellation may start from, earliest first. The
  /// first is preselected. Empty hides the select.
  final List<EventCancellationSession> sessions;

  /// Hint shown in the empty reason field.
  final String reasonPlaceholder;

  final bool enabled;

  @override
  State<EventCancellationForm> createState() => EventCancellationFormState();
}

class EventCancellationFormState extends State<EventCancellationForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Validates the fields. Returns the flat form values
  /// (`{fromSessionId: DateTime?, reasonId: String}`, the reason trimmed),
  /// or `null` when invalid.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final reason =
        (form.value[EventCancellationFormFields.reasonId] as String?)?.trim() ??
        '';
    return {
      EventCancellationFormFields.fromSessionId:
          form.value[EventCancellationFormFields.fromSessionId] as DateTime?,
      EventCancellationFormFields.reasonId: reason,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;
    return ShadForm(
      key: formKey,
      initialValue: {
        if (sessions.isNotEmpty)
          EventCancellationFormFields.fromSessionId: sessions.first.start,
        EventCancellationFormFields.reasonId: '',
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (sessions.isNotEmpty)
            LabeledFormRow(
              label: 'Cancel from',
              required: true,
              field: ShadSelectFormField<DateTime>(
                id: EventCancellationFormFields.fromSessionId,
                initialValue: sessions.first.start,
                enabled: widget.enabled,
                placeholder: const Text('Select a session'),
                validator: EventCancellationFormValidators.fromSession,
                options: [
                  for (final session in sessions)
                    ShadOption(
                      value: session.start,
                      child: Text(session.label),
                    ),
                ],
                selectedOptionBuilder: (context, value) => Text(
                  sessions
                      .firstWhere(
                        (session) => session.start == value,
                        orElse: () => sessions.first,
                      )
                      .label,
                ),
              ),
            ),
          LabeledFormRow(
            label: 'Reason',
            required: true,
            field: ShadInputFormField(
              id: EventCancellationFormFields.reasonId,
              enabled: widget.enabled,
              placeholder: Text(widget.reasonPlaceholder),
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              validator: EventCancellationFormValidators.reason,
            ),
          ),
        ],
      ),
    );
  }
}
