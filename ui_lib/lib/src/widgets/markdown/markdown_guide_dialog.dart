import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Opens the [MarkdownGuideDialog] over [context]. Both markdown editors
/// (`MarkdownEditorDialog` and `MarkdownComposerField`) use it for their
/// help button.
Future<void> showMarkdownGuide(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const MarkdownGuideDialog(),
);

/// The markdown syntax the editors accept, one row per construct, with a
/// Close button that dismisses this dialog only (the `showDialog →
/// Navigator.pop` idiom).
class MarkdownGuideDialog extends StatelessWidget {
  const MarkdownGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// One row of the [MarkdownGuideDialog]: the syntax and what it makes.
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
