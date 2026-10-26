import 'package:flutter/material.dart';

import '../../../constants/form_spacing.dart';
import '../application_form_strings.dart';
import 'application_add_button.dart';
import 'application_item_actions.dart';
import 'application_item_builder.dart';
import 'application_item_frame.dart';

/// Edits a list of an application template: one framed item per entry,
/// each moved up or down or removed by its buttons, its editor built by
/// [itemBuilder], and a button that adds one.
///
/// It reports the whole list through [onChanged] on every edit; the list is
/// seeded once from [initialItems].
class ApplicationItemsEditor extends StatefulWidget {
  const ApplicationItemsEditor({
    required this.initialItems,
    required this.itemBuilder,
    required this.noun,
    required this.addLabel,
    required this.onChanged,
    this.newItem,
    this.enabled = true,
    super.key,
  });

  /// The items to start from.
  final List<Object?> initialItems;

  /// Builds an item's editor.
  final ApplicationItemBuilder itemBuilder;

  /// What an item is called above it (`Term`).
  final String noun;

  /// The text of the button that adds an item.
  final String addLabel;

  /// Called with the items after every edit.
  final ValueChanged<List<Object?>> onChanged;

  /// What an added item holds before it is edited; null for nothing.
  final Object? Function()? newItem;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationItemsEditor> createState() => ApplicationItemsEditorState();
}

/// State of [ApplicationItemsEditor]: the key of each item, in order, and
/// what each holds by key.
class ApplicationItemsEditorState extends State<ApplicationItemsEditor> {
  /// The key of each item, in order.
  final List<int> itemKeys = [];

  /// What each item holds, by item key.
  final Map<int, Object?> items = {};

  /// The key the next item takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    widget.initialItems.forEach(addItemFrom);
  }

  /// Appends an item holding [item].
  void addItemFrom(Object? item) {
    final key = nextKey++;
    itemKeys.add(key);
    items[key] = item;
  }

  /// Reports the items.
  void report() => widget.onChanged([for (final key in itemKeys) items[key]]);

  /// Adds an item.
  void addItem() {
    setState(() => addItemFrom(widget.newItem?.call()));
    report();
  }

  /// Removes the item at [index].
  void removeItem(int index) {
    setState(() => items.remove(itemKeys.removeAt(index)));
    report();
  }

  /// Swaps the item at [index] with the one after it.
  void swapWithNext(int index) {
    setState(() {
      final key = itemKeys[index];
      itemKeys[index] = itemKeys[index + 1];
      itemKeys[index + 1] = key;
    });
    report();
  }

  @override
  Widget build(BuildContext context) {
    final count = itemKeys.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        for (var i = 0; i < count; i++)
          ApplicationItemFrame(
            key: ValueKey<int>(itemKeys[i]),
            title: ApplicationFormStrings.itemTitle(widget.noun, i + 1),
            actions: ApplicationItemActions(
              enabled: widget.enabled,
              onMoveUp: i == 0 ? null : () => swapWithNext(i - 1),
              onMoveDown: i == count - 1 ? null : () => swapWithNext(i),
              onRemove: () => removeItem(i),
            ),
            child: widget.itemBuilder(
              initial: items[itemKeys[i]],
              enabled: widget.enabled,
              onChanged: (item) {
                items[itemKeys[i]] = item;
                report();
              },
            ),
          ),
        ApplicationAddButton(
          label: widget.addLabel,
          enabled: widget.enabled,
          onPressed: addItem,
        ),
      ],
    );
  }
}
