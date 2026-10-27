import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_breakpoints.dart';
import '../../constants/form_spacing.dart';
import '../form/labeled_form_row.dart';
import 'profile_option_row_frame.dart';
import 'profile_options_form_fields.dart';
import 'profile_options_form_strings.dart';

/// Edits the club's languages (club_client#396): English first, always
/// offered, shown with its code and never removed; then one row per other
/// language, its name and its code, each removed by its button; and a
/// button that adds one.
///
/// It reports the languages, English first, as `{code, name}` maps through
/// [onChanged] on every edit; the list is seeded once from
/// [initialLanguages], whose first entry is English
/// (`ProfileOptionsFormValues.languages`).
class ProfileLanguagesEditor extends StatefulWidget {
  const ProfileLanguagesEditor({
    required this.initialLanguages,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The languages to start from, English first.
  final List<Map<String, String>> initialLanguages;

  /// Called with the languages after every edit.
  final ValueChanged<List<Map<String, String>>> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ProfileLanguagesEditor> createState() => ProfileLanguagesEditorState();
}

/// State of [ProfileLanguagesEditor]: English as given, the key of each
/// other row, in order, and its controllers by key.
class ProfileLanguagesEditorState extends State<ProfileLanguagesEditor> {
  /// English, as given: not edited here.
  late final Map<String, String> english;

  /// The key of each row after English's, in order.
  final List<int> rowKeys = [];

  /// The name of each row, by row key.
  final Map<int, TextEditingController> names = {};

  /// The code of each row, by row key.
  final Map<int, TextEditingController> codes = {};

  /// The key the next row takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    english = Map.unmodifiable(widget.initialLanguages.first);
    widget.initialLanguages.skip(1).forEach(addRowFrom);
  }

  @override
  void dispose() {
    for (final controller in [...names.values, ...codes.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Appends a row holding [language].
  void addRowFrom(Map<String, String> language) {
    final key = nextKey++;
    rowKeys.add(key);
    names[key] = TextEditingController(
      text: language[ProfileOptionsFormFields.nameKey] ?? '',
    );
    codes[key] = TextEditingController(
      text: language[ProfileOptionsFormFields.codeKey] ?? '',
    );
  }

  /// Reports the languages.
  void report() => widget.onChanged([
    english,
    for (final key in rowKeys)
      {
        ProfileOptionsFormFields.codeKey: codes[key]!.text,
        ProfileOptionsFormFields.nameKey: names[key]!.text,
      },
  ]);

  /// Adds an empty row.
  void addRow() {
    setState(() => addRowFrom(const {}));
    report();
  }

  /// Removes the row at [index], counted after English's.
  void removeRow(int index) {
    final key = rowKeys[index];
    setState(() => rowKeys.removeAt(index));
    report();
    // The row's inputs leave the tree in this frame; their controllers go
    // after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      names.remove(key)?.dispose();
      codes.remove(key)?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        ProfileOptionRowFrame(
          child: Row(
            spacing: FormSpacing.rowGap,
            children: [
              Expanded(
                child: Text(
                  ProfileOptionsFormStrings.fixedLanguage(
                    english[ProfileOptionsFormFields.nameKey]!,
                    english[ProfileOptionsFormFields.codeKey]!,
                  ),
                  style: theme.textTheme.small,
                ),
              ),
              Text(
                ProfileOptionsFormStrings.fixedLanguageHint,
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        for (var i = 0; i < rowKeys.length; i++)
          ProfileOptionRowFrame(
            key: ValueKey<int>(rowKeys[i]),
            child: _LanguageRow(
              name: names[rowKeys[i]]!,
              code: codes[rowKeys[i]]!,
              enabled: widget.enabled,
              onChanged: report,
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
            child: const Text(ProfileOptionsFormStrings.addLanguage),
          ),
        ),
      ],
    );
  }
}

/// One language after English: its name and code side by side on a wide
/// editor, stacked on a narrow one, and its remove button.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.name,
    required this.code,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final TextEditingController name;
  final TextEditingController code;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cells = [
      LabeledFormRow(
        label: ProfileOptionsFormStrings.languageName,
        required: true,
        field: ShadInput(
          controller: name,
          enabled: enabled,
          keyboardType: TextInputType.text,
          placeholder: const Text(
            ProfileOptionsFormStrings.languagePlaceholder,
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
      LabeledFormRow(
        label: ProfileOptionsFormStrings.languageCode,
        required: true,
        field: ShadInput(
          controller: code,
          enabled: enabled,
          keyboardType: TextInputType.text,
          placeholder: const Text(ProfileOptionsFormStrings.codePlaceholder),
          onChanged: (_) => onChanged(),
        ),
      ),
    ];
    final remove = ShadIconButton.ghost(
      enabled: enabled,
      icon: const Icon(
        LucideIcons.trash2,
        size: ProfileOptionRowFrame.iconSize,
      ),
      onPressed: onRemove,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < FormBreakpoints.singleColumnMaxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FormSpacing.rowGap,
            children: [
              ...cells,
              Align(alignment: Alignment.centerRight, child: remove),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: FormSpacing.rowGap,
          children: [
            for (final cell in cells) Expanded(child: cell),
            remove,
          ],
        );
      },
    );
  }
}
