import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import 'profile_option_row_frame.dart';
import 'profile_options_form_strings.dart';

/// Edits the club's languages: one name per row, each removed by its
/// button, and a button that adds one.
///
/// It reports the names through [onChanged] on every edit; the list is
/// seeded once from [initialNames].
class ProfileLanguagesEditor extends StatefulWidget {
  const ProfileLanguagesEditor({
    required this.initialNames,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The names to start from.
  final List<String> initialNames;

  /// Called with the names after every edit.
  final ValueChanged<List<String>> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ProfileLanguagesEditor> createState() => ProfileLanguagesEditorState();
}

/// State of [ProfileLanguagesEditor]: the key of each row, in order, and
/// its controller by key.
class ProfileLanguagesEditorState extends State<ProfileLanguagesEditor> {
  /// The key of each row, in order.
  final List<int> rowKeys = [];

  /// The text of each row, by row key.
  final Map<int, TextEditingController> names = {};

  /// The key the next row takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    widget.initialNames.forEach(addRowFrom);
  }

  @override
  void dispose() {
    for (final controller in names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Appends a row holding [name].
  void addRowFrom(String name) {
    final key = nextKey++;
    rowKeys.add(key);
    names[key] = TextEditingController(text: name);
  }

  /// Reports the names.
  void report() =>
      widget.onChanged([for (final key in rowKeys) names[key]!.text]);

  /// Adds an empty row.
  void addRow() {
    setState(() => addRowFrom(''));
    report();
  }

  /// Removes the row at [index].
  void removeRow(int index) {
    final key = rowKeys[index];
    setState(() => rowKeys.removeAt(index));
    report();
    // The row's input leaves the tree in this frame; its controller goes
    // after it.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => names.remove(key)?.dispose(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        for (var i = 0; i < rowKeys.length; i++)
          ProfileOptionRowFrame(
            key: ValueKey<int>(rowKeys[i]),
            child: Row(
              spacing: FormSpacing.rowGap,
              children: [
                Expanded(
                  child: ShadInput(
                    controller: names[rowKeys[i]],
                    enabled: widget.enabled,
                    keyboardType: TextInputType.text,
                    placeholder: const Text(
                      ProfileOptionsFormStrings.languagePlaceholder,
                    ),
                    onChanged: (_) => report(),
                  ),
                ),
                ShadIconButton.ghost(
                  enabled: widget.enabled,
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: ProfileOptionRowFrame.iconSize,
                  ),
                  onPressed: () => removeRow(i),
                ),
              ],
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
            child: const Text(ProfileOptionsFormStrings.addLanguage),
          ),
        ),
      ],
    );
  }
}
