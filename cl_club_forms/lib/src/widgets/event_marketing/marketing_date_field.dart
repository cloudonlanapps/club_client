import 'package:shadcn_ui/shadcn_ui.dart';

import 'marketing_list_date_cell.dart';

/// `ShadForm` field for a day that may be left empty: picked from a
/// calendar, and emptied with the button beside it.
class MarketingDateField extends ShadFormBuilderField<DateTime?> {
  MarketingDateField({
    String? placeholder,
    super.id,
    super.initialValue,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => MarketingListDateCell(
           value: state.value,
           enabled: state.widget.enabled,
           placeholder: placeholder,
           onChanged: state.didChange,
         ),
       );
}
