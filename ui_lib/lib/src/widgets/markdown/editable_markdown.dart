import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'markdown_editor_dialog.dart';
import 'themed_markdown.dart';

/// Displays rendered markdown text. On tap, opens a centered editor popover
/// with a preview toggle and save/cancel actions.
///
/// Use this wherever markdown content needs inline display with tap-to-edit.
///
/// ```dart
/// EditableMarkdown(
///   data: user.bio ?? '',
///   label: 'Bio',
///   onSave: (updated) => updateBio(updated),
/// )
/// ```
class EditableMarkdown extends StatelessWidget {
  const EditableMarkdown({
    required this.data,
    required this.label,
    required this.onSave,
    this.title,
    this.icon,
    this.emptyText = 'Tap to add',
    this.textAlign = TextAlign.justify,
    super.key,
  });

  /// The current markdown content to display.
  final String data;

  /// Label shown in the editor dialog header.
  final String label;

  /// Called with the updated markdown when the user taps Save.
  final ValueChanged<String> onSave;

  /// Optional inline title rendered on the left of the header row, parallel
  /// to the pencil icon. When omitted, only the pencil is shown.
  final String? title;

  /// Optional icon rendered before [title]. Has no effect when [title] is
  /// null.
  final IconData? icon;

  /// Text shown when [data] is empty.
  final String emptyText;

  /// Text alignment for the rendered markdown.
  final TextAlign textAlign;

  void openEditor(BuildContext context) {
    unawaited(
      MarkdownEditorDialog.show(
        context,
        label: label,
        initialValue: data,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasContent = data.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (title != null) ...[
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title!, style: theme.textTheme.small),
              ),
            ] else
              const Spacer(),
            IconButton(
              onPressed: () => openEditor(context),
              icon: Icon(
                LucideIcons.pencil,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              tooltip: 'Edit $label',
              iconSize: 14,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        if (hasContent)
          ThemedMarkdown(data: data, textAlign: textAlign)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: theme.textTheme.muted),
          ),
      ],
    );
  }
}
