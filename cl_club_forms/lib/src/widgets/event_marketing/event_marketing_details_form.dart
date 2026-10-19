import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_marketing_details_form_fields.dart';
import 'event_marketing_form_validators.dart';
import 'event_marketing_limits.dart';
import 'marketing_date_field.dart';
import 'marketing_form_draft.dart';

/// Pure-UI form of the details of an event's extended marketing: its
/// duration, schedule and eligibility in words, the registration deadline,
/// whether places are open, an urgency line and a contact number
/// (club_client#1).
///
/// The host drives it through a `GlobalKey<EventMarketingDetailsFormState>`
/// ([FormContract]); [onChanged] tells it the values moved.
class EventMarketingDetailsForm extends StatefulWidget {
  const EventMarketingDetailsForm({
    required this.initialValues,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The text fields of the form, in order, with their labels.
  static const Map<String, String> textLabels = {
    EventMarketingDetailsFormFields.durationTextId: 'Duration',
    EventMarketingDetailsFormFields.scheduleTextId: 'Schedule',
    EventMarketingDetailsFormFields.eligibilityTextId: 'Eligibility',
    EventMarketingDetailsFormFields.eligibilityNoteId: 'Eligibility note',
  };

  /// The open-slots choices, with their labels.
  static const Map<String, String> openSlotsLabels = {
    EventMarketingDetailsFormFields.openSlotsUnset: 'Not said',
    EventMarketingDetailsFormFields.openSlotsOpen: 'Places open',
    EventMarketingDetailsFormFields.openSlotsFull: 'Full',
  };

  /// Initial values, keyed by the ids of [EventMarketingDetailsFormFields]:
  /// the texts as `String`, the deadline as `DateTime?`, open slots as one
  /// of its values.
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called after every edit.
  final VoidCallback? onChanged;

  @override
  State<EventMarketingDetailsForm> createState() =>
      EventMarketingDetailsFormState();
}

/// State of [EventMarketingDetailsForm]. Its values are the texts, trimmed
/// (empty when blank), the deadline (`DateTime?`) and the open-slots value.
class EventMarketingDetailsFormState extends State<EventMarketingDetailsForm>
    with
        FormContract<EventMarketingDetailsForm>,
        MarketingFormDraft<EventMarketingDetailsForm> {
  /// The ids of the form's texts.
  static const List<String> textIds = [
    EventMarketingDetailsFormFields.durationTextId,
    EventMarketingDetailsFormFields.scheduleTextId,
    EventMarketingDetailsFormFields.eligibilityTextId,
    EventMarketingDetailsFormFields.eligibilityNoteId,
    EventMarketingDetailsFormFields.urgencyTextId,
    EventMarketingDetailsFormFields.contactNumberId,
  ];

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    for (final id in textIds) id: (values[id] as String?)?.trim() ?? '',
    EventMarketingDetailsFormFields.registrationDeadlineId:
        values[EventMarketingDetailsFormFields.registrationDeadlineId]
            as DateTime?,
    EventMarketingDetailsFormFields.openSlotsId:
        values[EventMarketingDetailsFormFields.openSlotsId] as String? ??
        EventMarketingDetailsFormFields.openSlotsUnset,
  };

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    return ShadForm(
      key: formKey,
      onChanged: widget.onChanged,
      initialValue: {
        for (final id in textIds) id: initial[id] as String? ?? '',
        EventMarketingDetailsFormFields.registrationDeadlineId:
            initial[EventMarketingDetailsFormFields.registrationDeadlineId]
                as DateTime?,
        EventMarketingDetailsFormFields.openSlotsId:
            initial[EventMarketingDetailsFormFields.openSlotsId] as String? ??
            EventMarketingDetailsFormFields.openSlotsUnset,
      },
      child: FormBody(
        error: formError,
        children: [
          for (final entry in EventMarketingDetailsForm.textLabels.entries)
            LabeledFormRow(
              label: entry.value,
              field: ShadInputFormField(
                id: entry.key,
                enabled: widget.enabled,
                validator: EventMarketingFormValidators.maxLength(
                  EventMarketingLimits.text,
                ),
              ),
            ),
          LabeledFormRow(
            label: 'Registration deadline',
            field: MarketingDateField(
              id: EventMarketingDetailsFormFields.registrationDeadlineId,
              enabled: widget.enabled,
              placeholder: 'No deadline',
            ),
          ),
          LabeledFormRow(
            label: 'Places',
            field: ShadSelectFormField<String>(
              id: EventMarketingDetailsFormFields.openSlotsId,
              enabled: widget.enabled,
              options: [
                for (final entry
                    in EventMarketingDetailsForm.openSlotsLabels.entries)
                  ShadOption(value: entry.key, child: Text(entry.value)),
              ],
              selectedOptionBuilder: (context, value) => Text(
                EventMarketingDetailsForm.openSlotsLabels[value] ?? value,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Urgency',
            field: ShadInputFormField(
              id: EventMarketingDetailsFormFields.urgencyTextId,
              enabled: widget.enabled,
              placeholder: const Text('Only 3 places left'),
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.name,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Contact number',
            field: ShadInputFormField(
              id: EventMarketingDetailsFormFields.contactNumberId,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.contactNumber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
