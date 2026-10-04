import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

/// Centered modal dialog for editing markdown with a live preview toggle.
///
/// Renders as a constrained popover (max 720 px wide) with comfortable
/// margins on wide layouts, and collapses to a near-full-bleed sheet on
/// narrow mobile widths so the editor never feels like a full-screen route.
class MarkdownEditorDialog extends StatefulWidget {
  const MarkdownEditorDialog({
    required this.label,
    required this.initialValue,
    required this.onSave,
    super.key,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onSave;

  static const double maxDialogWidth = 720;
  static const double wideInsetPadding = 48;
  static const double narrowInsetPadding = 16;
  static const double narrowBreakpoint = 600;

  static Future<void> show(
    BuildContext context, {
    required String label,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MarkdownEditorDialog(
        label: label,
        initialValue: initialValue,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MarkdownEditorDialog> createState() => MarkdownEditorDialogState();
}

class MarkdownEditorDialogState extends State<MarkdownEditorDialog> {
  late TextEditingController controller;
  bool showPreview = false;

  Future<void> showMarkdownHelp() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => PointerInterceptor(
        child: AlertDialog(
          title: const Text('Markdown Guide'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                HelpRow(syntax: '**bold**', description: 'Bold text'),
                HelpRow(syntax: '*italic*', description: 'Italic text'),
                HelpRow(syntax: '# Heading', description: 'Heading'),
                HelpRow(syntax: '- item', description: 'Bullet list'),
                HelpRow(syntax: '1. item', description: 'Numbered list'),
                HelpRow(syntax: '[text](url)', description: 'Link'),
                HelpRow(syntax: '> quote', description: 'Block quote'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isDirty => controller.text != widget.initialValue;

  Future<void> handleCancel() async {
    if (!isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PointerInterceptor(
        child: AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void handleSave() {
    widget.onSave(controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final media = MediaQuery.of(context);
    final isNarrow = media.size.width < MarkdownEditorDialog.narrowBreakpoint;
    final inset = isNarrow
        ? MarkdownEditorDialog.narrowInsetPadding
        : MarkdownEditorDialog.wideInsetPadding;
    final targetWidth = (media.size.width - inset * 2).clamp(
      0.0,
      MarkdownEditorDialog.maxDialogWidth,
    );

    return PointerInterceptor(
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: inset,
          vertical: inset,
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          key: const Key('markdownEditorDialogFrame'),
          width: targetWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: media.size.height - inset * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          style: theme.textTheme.large,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: showMarkdownHelp,
                        icon: const Icon(Icons.help_outline, size: 20),
                        tooltip: 'Markdown help',
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => showPreview = !showPreview),
                        icon: Icon(
                          showPreview ? LucideIcons.pencil : LucideIcons.eye,
                          size: 20,
                        ),
                        tooltip: showPreview ? 'Edit' : 'Preview',
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.border),
                Flexible(
                  child: showPreview
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: controller.text.isEmpty
                              ? Text(
                                  'Nothing to preview',
                                  style: theme.textTheme.muted,
                                )
                              : ListenableBuilder(
                                  listenable: controller,
                                  builder: (context, _) => ThemedMarkdown(
                                    data: controller.text,
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: TextField(
                            controller: controller,
                            maxLines: isNarrow ? 8 : 12,
                            minLines: isNarrow ? 6 : 8,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Write markdown here…',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.border,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.border),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadButton.outline(
                        onPressed: handleCancel,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ShadButton(
                        onPressed: handleSave,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HelpRow extends StatelessWidget {
  const HelpRow({
    required this.syntax,
    required this.description,
    super.key,
  });

  final String syntax;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              syntax,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          Text(description),
        ],
      ),
    );
  }
}
