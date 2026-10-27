import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_joined_text.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import '../items/application_add_button.dart';
import '../items/application_item_frame.dart';
import '../text_value/application_text_value_editor.dart';

/// Edits one header item of an application: a text (a header clause, a
/// fact, or written here), or several joined on one line, each removed by
/// its button while there are more than one.
///
/// It reports the item as the template's JSON holds it, a joined line as a
/// list, through [onChanged] on every edit; it is seeded once from
/// [initial].
class ApplicationHeaderItemEditor extends StatefulWidget {
  const ApplicationHeaderItemEditor({
    required this.initial,
    required this.languages,
    required this.sources,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The modes a header text may take; a new one takes the first.
  // A printed text is a language map only (club_sdk#76): a clause or fact
  // reference is refused by the server. Inserting a library clause's filled
  // text is club_client#336.
  static const List<ApplicationTextMode> modes = [ApplicationTextMode.custom];

  /// The item to start from, as the template's JSON holds it.
  final Object? initial;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The facts and clauses a text may name.
  final ApplicationTextSources sources;

  /// Called with the item after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationHeaderItemEditor> createState() =>
      ApplicationHeaderItemEditorState();
}

/// State of [ApplicationHeaderItemEditor]: the key of each part, in order,
/// and what each holds by key.
class ApplicationHeaderItemEditorState
    extends State<ApplicationHeaderItemEditor> {
  /// The key of each part, in order.
  final List<int> partKeys = [];

  /// What each part holds, by part key.
  final Map<int, ApplicationTextValue?> parts = {};

  /// The key the next part takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    final value = ApplicationTextValue.fromJson(widget.initial);
    if (value case ApplicationJoinedText(parts: final joined)) {
      joined.forEach(addPart);
    } else {
      addPart(value);
    }
  }

  /// Appends a part holding [value].
  void addPart(ApplicationTextValue? value) {
    final key = nextKey++;
    partKeys.add(key);
    parts[key] = value;
  }

  /// The item as the template's JSON holds it.
  Object? get current {
    if (partKeys.length == 1) return parts[partKeys.first]?.toJson();
    return [
      for (final key in partKeys) ?parts[key]?.toJson(),
    ];
  }

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    setState(changed);
    widget.onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final joined = partKeys.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        for (final key in partKeys)
          Row(
            key: ValueKey<int>(key),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ApplicationTextValueEditor(
                  modes: ApplicationHeaderItemEditor.modes,
                  languages: widget.languages,
                  sources: widget.sources,
                  clauseKind: ApplicationClauseKind.header,
                  initialValue: parts[key],
                  enabled: widget.enabled,
                  onChanged: (value) => update(() => parts[key] = value),
                ),
              ),
              if (joined)
                ShadIconButton.ghost(
                  enabled: widget.enabled,
                  icon: const Icon(
                    LucideIcons.x,
                    size: ApplicationItemFrame.iconSize,
                  ),
                  onPressed: () => update(() {
                    partKeys.remove(key);
                    parts.remove(key);
                  }),
                ),
            ],
          ),
        ApplicationAddButton(
          label: ApplicationFormStrings.addToLine,
          enabled: widget.enabled,
          onPressed: () => update(() => addPart(ApplicationCustomText.none)),
        ),
      ],
    );
  }
}
