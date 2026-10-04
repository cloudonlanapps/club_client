import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'editable_markdown.dart' show HelpRow;
import 'themed_markdown.dart';

/// Inline markdown editor with a live **preview toggle** — the same look as
/// `MarkdownEditorDialog` but embedded in a form instead of a modal.
///
/// SDK-free and Riverpod-free. The caller owns the [controller]; this widget
/// only renders the edit ↔ preview surfaces and a markdown-help affordance,
/// so the host keeps full control over the text (listening for changes,
/// clearing on send, validation). When preview is on the body renders the
/// controller's current text via [ThemedMarkdown]; otherwise it shows a
/// bordered multiline `TextField`.
class MarkdownComposerField extends StatefulWidget {
  const MarkdownComposerField({
    required this.controller,
    this.placeholder = 'Type a message…',
    this.minLines = 2,
    this.maxLines = 6,
    this.enabled = true,
    super.key,
  });

  /// Caller-owned controller holding the markdown text.
  final TextEditingController controller;

  /// Placeholder shown in the editor while empty.
  final String placeholder;

  final int minLines;
  final int maxLines;

  /// When false the field is read-only (e.g. while a send is in flight).
  final bool enabled;

  @override
  State<MarkdownComposerField> createState() => MarkdownComposerFieldState();
}

class MarkdownComposerFieldState extends State<MarkdownComposerField> {
  bool _showPreview = false;

  Future<void> _showMarkdownHelp() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Markdown Guide'),
        content: SingleChildScrollView(
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
        actions: [_HelpCloseButton()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Message', style: theme.textTheme.muted),
            const Spacer(),
            IconButton(
              onPressed: _showMarkdownHelp,
              icon: const Icon(Icons.help_outline, size: 18),
              tooltip: 'Markdown help',
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(
                _showPreview ? LucideIcons.pencil : LucideIcons.eye,
                size: 18,
              ),
              tooltip: _showPreview ? 'Edit' : 'Preview',
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_showPreview)
          Container(
            constraints: BoxConstraints(
              minHeight: widget.minLines * 24.0,
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => widget.controller.text.trim().isEmpty
                  ? Text('Nothing to preview', style: theme.textTheme.muted)
                  : ThemedMarkdown(
                      data: widget.controller.text,
                      textAlign: TextAlign.left,
                      textStyle: theme.textTheme.small,
                    ),
            ),
          )
        else
          TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.border),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
      ],
    );
  }
}

/// Close button for the markdown-help dialog. Pops only the help dialog it
/// belongs to (the canonical `showDialog → Navigator.pop` idiom).
class _HelpCloseButton extends StatelessWidget {
  const _HelpCloseButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Close'),
    );
  }
}
