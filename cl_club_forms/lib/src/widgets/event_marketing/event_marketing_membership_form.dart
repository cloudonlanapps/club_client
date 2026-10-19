import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_marketing_columns.dart';
import 'event_marketing_form_validators.dart';
import 'event_marketing_limits.dart';
import 'event_marketing_membership_form_fields.dart';
import 'marketing_form_draft.dart';
import 'marketing_list_field.dart';
import 'marketing_rows.dart';

/// Pure-UI form of the club membership an event's page offers: a title, a
/// description and its benefits (club_client#1). Emptied, the page offers
/// none; anything else needs the title.
///
/// The host drives it through a `GlobalKey<EventMarketingMembershipFormState>`
/// ([FormContract]); [onChanged] tells it the values moved.
class EventMarketingMembershipForm extends StatefulWidget {
  const EventMarketingMembershipForm({
    required this.initialValues,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// Lines the description shows.
  static const int descriptionLines = 3;

  /// The message when a membership has details but no title.
  static const String titleNeeded =
      'Give the membership a title, or empty the form.';

  /// Initial values, keyed by the ids of
  /// [EventMarketingMembershipFormFields]: title and description as
  /// `String`, the benefits as rows of [EventMarketingColumns.bullets].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called after every edit.
  final VoidCallback? onChanged;

  @override
  State<EventMarketingMembershipForm> createState() =>
      EventMarketingMembershipFormState();
}

/// State of [EventMarketingMembershipForm]. Its values are the title and
/// description, trimmed, and the benefits as `List<String>`.
class EventMarketingMembershipFormState
    extends State<EventMarketingMembershipForm>
    with
        FormContract<EventMarketingMembershipForm>,
        MarketingFormDraft<EventMarketingMembershipForm> {
  static final String? Function(List<Object?>?) benefitRows =
      EventMarketingFormValidators.rows(
        columns: EventMarketingColumns.bullets,
        maxLengths: const {
          EventMarketingColumns.textId: EventMarketingLimits.bullet,
        },
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventMarketingMembershipFormFields.titleId:
        (values[EventMarketingMembershipFormFields.titleId] as String?)
            ?.trim() ??
        '',
    EventMarketingMembershipFormFields.descriptionId:
        (values[EventMarketingMembershipFormFields.descriptionId] as String?)
            ?.trim() ??
        '',
    EventMarketingMembershipFormFields.benefitsId: [
      for (final row in marketingRows(
        values[EventMarketingMembershipFormFields.benefitsId],
      ))
        row[EventMarketingColumns.textId]! as String,
    ],
  };

  @override
  String? crossFieldError(Map<String, dynamic> values) {
    final membership = assemble(values);
    final title = membership[EventMarketingMembershipFormFields.titleId];
    final description =
        membership[EventMarketingMembershipFormFields.descriptionId];
    final benefits =
        membership[EventMarketingMembershipFormFields.benefitsId] as List;
    final hasDetails = description != '' || benefits.isNotEmpty;
    return title == '' && hasDetails
        ? EventMarketingMembershipForm.titleNeeded
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    return ShadForm(
      key: formKey,
      onChanged: widget.onChanged,
      initialValue: {
        EventMarketingMembershipFormFields.titleId:
            initial[EventMarketingMembershipFormFields.titleId] as String? ??
            '',
        EventMarketingMembershipFormFields.descriptionId:
            initial[EventMarketingMembershipFormFields.descriptionId]
                as String? ??
            '',
        EventMarketingMembershipFormFields.benefitsId: marketingInitialRows(
          initial[EventMarketingMembershipFormFields.benefitsId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Title',
            field: ShadInputFormField(
              id: EventMarketingMembershipFormFields.titleId,
              enabled: widget.enabled,
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.name,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Description',
            field: ShadInputFormField(
              id: EventMarketingMembershipFormFields.descriptionId,
              enabled: widget.enabled,
              keyboardType: TextInputType.multiline,
              minLines: EventMarketingMembershipForm.descriptionLines,
              maxLines: EventMarketingMembershipForm.descriptionLines,
              validator: EventMarketingFormValidators.maxLength(
                EventMarketingLimits.text,
              ),
            ),
          ),
          LabeledFormRow(
            label: 'Benefits',
            field: MarketingListField(
              id: EventMarketingMembershipFormFields.benefitsId,
              enabled: widget.enabled,
              columns: EventMarketingColumns.bullets,
              addLabel: 'Add benefit',
              maxRows: EventMarketingLimits.listRows,
              validator: benefitRows,
            ),
          ),
        ],
      ),
    );
  }
}
