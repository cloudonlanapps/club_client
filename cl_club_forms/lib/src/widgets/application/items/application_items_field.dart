import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'application_item_builder.dart';
import 'application_items_editor.dart';

/// `ShadForm` field holding a list of an application template, edited by
/// an [ApplicationItemsEditor]; a validator's message shows under the list.
///
/// The value is the list as the template's JSON holds it, typed as a plain
/// list because a form hands its fields their initial values as plain
/// lists.
class ApplicationItemsField extends ShadFormBuilderField<List<Object?>> {
  ApplicationItemsField({
    required ApplicationItemBuilder itemBuilder,
    required String noun,
    required String addLabel,
    Object? Function()? newItem,
    Widget Function(ValueChanged<Object?> insert)? insertBuilder,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => ApplicationItemsEditor(
           initialItems: state.value ?? const [],
           itemBuilder: itemBuilder,
           noun: noun,
           addLabel: addLabel,
           newItem: newItem,
           insertBuilder: insertBuilder,
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
