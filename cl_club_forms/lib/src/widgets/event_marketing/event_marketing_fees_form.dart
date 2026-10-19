import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_marketing_columns.dart';
import 'event_marketing_fees_form_fields.dart';
import 'event_marketing_form_validators.dart';
import 'event_marketing_limits.dart';
import 'marketing_form_draft.dart';
import 'marketing_list_field.dart';
import 'marketing_rows.dart';

/// Pure-UI form of an event's fees: a single fee and a fee structure, side
/// by side, with the note that the structure is what the page shows when
/// both are set (club_client#1).
///
/// The host drives it through a `GlobalKey<EventMarketingFeesFormState>`
/// ([FormContract]); [onChanged] tells it the values moved.
class EventMarketingFeesForm extends StatefulWidget {
  const EventMarketingFeesForm({
    required this.initialValues,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The note on which of the two the page shows.
  static const String precedenceNote =
      'When both are set, the page shows the fee structure.';

  /// Initial values, keyed by the ids of [EventMarketingFeesFormFields]:
  /// the fee as digits (`String`), the structure as rows of
  /// [EventMarketingColumns.feeItems].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called after every edit.
  final VoidCallback? onChanged;

  @override
  State<EventMarketingFeesForm> createState() => EventMarketingFeesFormState();
}

/// State of [EventMarketingFeesForm]. Its values are the fee as digits
/// (empty when blank) and the structure's rows, blank ones dropped.
class EventMarketingFeesFormState extends State<EventMarketingFeesForm>
    with
        FormContract<EventMarketingFeesForm>,
        MarketingFormDraft<EventMarketingFeesForm> {
  static final String? Function(List<Object?>?) feeItemRows =
      EventMarketingFormValidators.rows(
        columns: EventMarketingColumns.feeItems,
        required: const {
          EventMarketingColumns.nameId,
          EventMarketingColumns.amountId,
        },
        maxLengths: const {
          EventMarketingColumns.nameId: EventMarketingLimits.name,
          EventMarketingColumns.periodId: EventMarketingLimits.period,
        },
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventMarketingFeesFormFields.feeId:
        (values[EventMarketingFeesFormFields.feeId] as String?)?.trim() ?? '',
    EventMarketingFeesFormFields.feeStructureId: marketingRows(
      values[EventMarketingFeesFormFields.feeStructureId],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initial = widget.initialValues;
    return ShadForm(
      key: formKey,
      onChanged: widget.onChanged,
      initialValue: {
        EventMarketingFeesFormFields.feeId:
            initial[EventMarketingFeesFormFields.feeId] as String? ?? '',
        EventMarketingFeesFormFields.feeStructureId: marketingInitialRows(
          initial[EventMarketingFeesFormFields.feeStructureId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Fee (₹)',
            field: ShadInputFormField(
              id: EventMarketingFeesFormFields.feeId,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: EventMarketingFormValidators.wholeAmount,
            ),
          ),
          LabeledFormRow(
            label: 'Fee structure',
            field: MarketingListField(
              id: EventMarketingFeesFormFields.feeStructureId,
              enabled: widget.enabled,
              columns: EventMarketingColumns.feeItems,
              addLabel: 'Add fee',
              maxRows: EventMarketingLimits.listRows,
              validator: feeItemRows,
            ),
          ),
          Text(
            EventMarketingFeesForm.precedenceNote,
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
