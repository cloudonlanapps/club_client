import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/profile_label_language.dart';
import 'profile_option_row_frame.dart';
import 'profile_options_form_fields.dart';
import 'profile_options_form_strings.dart';
import 'profile_options_form_values.dart';
import 'profile_position_actions.dart';
import 'profile_position_row.dart';

/// Edits the club's positions: one [ProfilePositionRow] per position, each
/// moved up or down or removed by its buttons, and a button that adds one.
///
/// It reports the whole list through [onChanged] on every edit, each
/// position shaped as `ProfileOptionsFormValues.position` holds it; the
/// list is seeded once from [initialRows]. When [labelLanguages] changes
/// (a language added or removed in the same form, club_client#396), each
/// position gets an empty label in a new language, and keeps, unshown, its
/// label in a removed one.
class ProfilePositionsEditor extends StatefulWidget {
  const ProfilePositionsEditor({
    required this.labelLanguages,
    required this.initialRows,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The languages a label is typed in, in order.
  final List<ProfileLabelLanguage> labelLanguages;

  /// The positions to start from.
  final List<Map<String, Object?>> initialRows;

  /// Called with the positions after every edit.
  final ValueChanged<List<Map<String, Object?>>> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ProfilePositionsEditor> createState() => ProfilePositionsEditorState();
}

/// State of [ProfilePositionsEditor]: the key of each row, in order, and
/// the controllers of each row by key.
class ProfilePositionsEditorState extends State<ProfilePositionsEditor> {
  /// The key of each row, in order.
  final List<int> rowKeys = [];

  /// The text of each row's value, by row key.
  final Map<int, TextEditingController> values = {};

  /// The text of each row's labels, by row key and language code; labels
  /// of languages not shown are kept here too.
  final Map<int, Map<String, TextEditingController>> labels = {};

  /// The key the next row takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    widget.initialRows.forEach(addRowFrom);
  }

  @override
  void didUpdateWidget(ProfilePositionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final row in labels.values) {
      for (final language in widget.labelLanguages) {
        row.putIfAbsent(language.code, TextEditingController.new);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in values.values) {
      controller.dispose();
    }
    for (final row in labels.values) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Appends [raw], a position, with a controller for each of its texts.
  void addRowFrom(Map<String, Object?> raw) {
    final row = ProfileOptionsFormValues.position(raw, widget.labelLanguages);
    final key = nextKey++;
    rowKeys.add(key);
    values[key] = TextEditingController(
      text: row[ProfileOptionsFormFields.valueKey]! as String,
    );
    labels[key] = {
      for (final entry
          in (row[ProfileOptionsFormFields.labelKey]! as Map<String, String>)
              .entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  /// Reports the positions.
  void report() => widget.onChanged([
    for (final key in rowKeys)
      {
        ProfileOptionsFormFields.valueKey: values[key]!.text,
        ProfileOptionsFormFields.labelKey: {
          for (final entry in labels[key]!.entries) entry.key: entry.value.text,
        },
      },
  ]);

  /// Adds an empty position.
  void addRow() {
    setState(() => addRowFrom(const {}));
    report();
  }

  /// Removes the position at [index].
  void removeRow(int index) {
    final key = rowKeys[index];
    setState(() => rowKeys.removeAt(index));
    report();
    // The row's inputs leave the tree in this frame; their controllers go
    // after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      values.remove(key)?.dispose();
      for (final controller in labels.remove(key)!.values) {
        controller.dispose();
      }
    });
  }

  /// Swaps the position at [index] with the one after it.
  void swapWithNext(int index) {
    setState(() {
      final key = rowKeys[index];
      rowKeys[index] = rowKeys[index + 1];
      rowKeys[index + 1] = key;
    });
    report();
  }

  @override
  Widget build(BuildContext context) {
    final count = rowKeys.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        for (var i = 0; i < count; i++)
          ProfilePositionRow(
            key: ValueKey<int>(rowKeys[i]),
            labelLanguages: widget.labelLanguages,
            valueController: values[rowKeys[i]]!,
            labelControllers: labels[rowKeys[i]]!,
            enabled: widget.enabled,
            onChanged: report,
            actions: ProfilePositionActions(
              enabled: widget.enabled,
              onMoveUp: i == 0 ? null : () => swapWithNext(i - 1),
              onMoveDown: i == count - 1 ? null : () => swapWithNext(i),
              onRemove: () => removeRow(i),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.outline(
            enabled: widget.enabled,
            leading: const Icon(
              LucideIcons.plus,
              size: ProfileOptionRowFrame.iconSize,
            ),
            onPressed: addRow,
            child: const Text(ProfileOptionsFormStrings.addPosition),
          ),
        ),
      ],
    );
  }
}
