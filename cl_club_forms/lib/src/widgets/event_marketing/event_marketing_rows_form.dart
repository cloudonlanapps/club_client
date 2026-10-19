import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/marketing_list_column.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'event_marketing_form_validators.dart';
import 'event_marketing_limits.dart';
import 'event_marketing_rows_form_fields.dart';
import 'marketing_form_draft.dart';
import 'marketing_list_field.dart';
import 'marketing_rows.dart';

/// Pure-UI form of one list of an event's extended marketing (packages,
/// offers, facilities; club_client#1): rows of [columns], each needing the
/// [required] ones.
///
/// The host drives it through a `GlobalKey<EventMarketingRowsFormState>`
/// ([FormContract]); [onChanged] tells it the values moved.
class EventMarketingRowsForm extends StatefulWidget {
  const EventMarketingRowsForm({
    required this.columns,
    required this.addLabel,
    required this.initialRows,
    this.required = const {},
    this.maxLengths = const {},
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The columns of each row.
  final List<MarketingListColumn> columns;

  /// The text of the add button.
  final String addLabel;

  /// The rows to start from.
  final List<Map<String, Object?>> initialRows;

  /// The ids of the columns a row must fill.
  final Set<String> required;

  /// The longest text each column takes, by column id.
  final Map<String, int> maxLengths;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called after every edit.
  final VoidCallback? onChanged;

  @override
  State<EventMarketingRowsForm> createState() => EventMarketingRowsFormState();
}

/// State of [EventMarketingRowsForm]. Its value is
/// `{EventMarketingRowsFormFields.rowsId: rows}`, blank rows dropped and
/// texts trimmed.
class EventMarketingRowsFormState extends State<EventMarketingRowsForm>
    with
        FormContract<EventMarketingRowsForm>,
        MarketingFormDraft<EventMarketingRowsForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventMarketingRowsFormFields.rowsId: marketingRows(
      values[EventMarketingRowsFormFields.rowsId],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      onChanged: widget.onChanged,
      initialValue: {
        EventMarketingRowsFormFields.rowsId: marketingInitialRows(
          widget.initialRows,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          MarketingListField(
            id: EventMarketingRowsFormFields.rowsId,
            enabled: widget.enabled,
            columns: widget.columns,
            addLabel: widget.addLabel,
            maxRows: EventMarketingLimits.listRows,
            validator: EventMarketingFormValidators.rows(
              columns: widget.columns,
              required: widget.required,
              maxLengths: widget.maxLengths,
            ),
          ),
        ],
      ),
    );
  }
}
