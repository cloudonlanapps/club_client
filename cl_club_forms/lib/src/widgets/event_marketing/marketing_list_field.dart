import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/marketing_list_column.dart';
import 'marketing_list_editor.dart';
import 'marketing_rows.dart';

/// `ShadForm` field holding a list of marketing rows, edited by a
/// [MarketingListEditor]. Its value is the rows, each a
/// `Map<String, Object?>` keyed by column id; a validator's message shows
/// under the list.
///
/// The value is typed as a plain list because a form hands its fields
/// their initial values as plain lists; [asMarketingRows] reads it.
class MarketingListField extends ShadFormBuilderField<List<Object?>> {
  MarketingListField({
    required List<MarketingListColumn> columns,
    required String addLabel,
    required int maxRows,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => MarketingListEditor(
           columns: columns,
           initialRows: asMarketingRows(state.value),
           addLabel: addLabel,
           maxRows: maxRows,
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
