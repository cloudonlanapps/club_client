import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_basic_marketing_form_fields.dart';
import 'event_marketing_columns.dart';
import 'event_marketing_form_validators.dart';
import 'event_marketing_limits.dart';
import 'marketing_form_draft.dart';
import 'marketing_list_field.dart';
import 'marketing_rows.dart';

/// Pure-UI form of an event's basic marketing: the short description, the
/// stamp, and the highlights and included items (club_client#1).
///
/// The host drives it through a `GlobalKey<EventBasicMarketingFormState>`
/// ([FormContract]); [onChanged] tells it the values moved, which it reads
/// back unchecked from `draft` for its preview.
class EventBasicMarketingForm extends StatefulWidget {
  const EventBasicMarketingForm({
    required this.initialValues,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// Lines a short description shows.
  static const int shortDescriptionLines = 3;

  /// Initial values, keyed by the ids of [EventBasicMarketingFormFields]:
  /// the two texts as `String`, the two lists as rows of
  /// `{EventMarketingColumns.textId: String}`.
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called after every edit.
  final VoidCallback? onChanged;

  @override
  State<EventBasicMarketingForm> createState() =>
      EventBasicMarketingFormState();
}

/// State of [EventBasicMarketingForm]. Its values are the two texts,
/// trimmed (empty when blank), and the two lists as `List<String>`, blank
/// rows dropped.
class EventBasicMarketingFormState extends State<EventBasicMarketingForm>
    with
        FormContract<EventBasicMarketingForm>,
        MarketingFormDraft<EventBasicMarketingForm> {
  static final String? Function(List<Object?>?) bulletRows =
      EventMarketingFormValidators.rows(
        columns: EventMarketingColumns.bullets,
        maxLengths: const {
          EventMarketingColumns.textId: EventMarketingLimits.bullet,
        },
      );

  /// The texts of a list's rows.
  static List<String> bullets(Object? rows) => [
    for (final row in marketingRows(rows))
      row[EventMarketingColumns.textId]! as String,
  ];

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventBasicMarketingFormFields.shortDescriptionId:
        (values[EventBasicMarketingFormFields.shortDescriptionId] as String?)
            ?.trim() ??
        '',
    EventBasicMarketingFormFields.stampId:
        (values[EventBasicMarketingFormFields.stampId] as String?)?.trim() ??
        '',
    EventBasicMarketingFormFields.highlightsId: bullets(
      values[EventBasicMarketingFormFields.highlightsId],
    ),
    EventBasicMarketingFormFields.includesId: bullets(
      values[EventBasicMarketingFormFields.includesId],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    return ShadForm(
      key: formKey,
      onChanged: widget.onChanged,
      initialValue: {
        EventBasicMarketingFormFields.shortDescriptionId:
            initial[EventBasicMarketingFormFields.shortDescriptionId]
                as String? ??
            '',
        EventBasicMarketingFormFields.stampId:
            initial[EventBasicMarketingFormFields.stampId] as String? ?? '',
        EventBasicMarketingFormFields.highlightsId: marketingInitialRows(
          initial[EventBasicMarketingFormFields.highlightsId],
        ),
        EventBasicMarketingFormFields.includesId: marketingInitialRows(
          initial[EventBasicMarketingFormFields.includesId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Short description',
            field: ShadInputFormField(
              id: EventBasicMarketingFormFields.shortDescriptionId,
              enabled: widget.enabled,
              placeholder: const Text('The line under the title on its card'),
              keyboardType: TextInputType.multiline,
              minLines: EventBasicMarketingForm.shortDescriptionLines,
              maxLines: EventBasicMarketingForm.shortDescriptionLines,
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.shortDescription,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Stamp',
            field: ShadInputFormField(
              id: EventBasicMarketingFormFields.stampId,
              enabled: widget.enabled,
              placeholder: const Text('New, Sold out'),
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.stamp,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Highlights',
            field: MarketingListField(
              id: EventBasicMarketingFormFields.highlightsId,
              enabled: widget.enabled,
              columns: EventMarketingColumns.bullets,
              addLabel: 'Add highlight',
              maxRows: EventMarketingLimits.listRows,
              validator: bulletRows,
            ),
          ),
          LabeledFormRow(
            label: 'Includes',
            field: MarketingListField(
              id: EventBasicMarketingFormFields.includesId,
              enabled: widget.enabled,
              columns: EventMarketingColumns.bullets,
              addLabel: 'Add item',
              maxRows: EventMarketingLimits.listRows,
              validator: bulletRows,
            ),
          ),
        ],
      ),
    );
  }
}
