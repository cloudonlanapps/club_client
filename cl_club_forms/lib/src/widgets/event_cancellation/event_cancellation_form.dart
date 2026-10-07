import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_cancellation_form_fields.dart';
import 'event_cancellation_form_validators.dart';
import 'event_cancellation_session.dart';

/// Pure-UI form for calling an event off (no SDK / no Riverpod): a reason,
/// and, when [sessions] are given, the upcoming session the cancellation
/// starts from (a camp is cancelled from a session onward; a one-off has
/// none to choose).
///
/// The form owns no buttons or dialog: the host drives it through a
/// `GlobalKey<EventCancellationFormState>` — `validate()` from its confirm
/// action, `showErrors()` with what the server refuses ([FormContract]).
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

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<EventCancellationForm> createState() => EventCancellationFormState();
}

/// State of [EventCancellationForm]. Its values are
/// `{fromSessionId: DateTime?, reasonId: String}`, the reason trimmed.
class EventCancellationFormState extends State<EventCancellationForm>
    with FormContract<EventCancellationForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventCancellationFormFields.fromSessionId:
        values[EventCancellationFormFields.fromSessionId] as DateTime?,
    EventCancellationFormFields.reasonId:
        (values[EventCancellationFormFields.reasonId] as String?)?.trim() ?? '',
  };

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
      child: FormBody(
        error: formError,
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
