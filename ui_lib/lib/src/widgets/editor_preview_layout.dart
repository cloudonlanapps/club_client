import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A page's [editor] beside a live [preview] of what it edits
/// (club_client#1, #28): side by side on a wide screen; on a narrow one,
/// one at a time, with an Edit / Preview switch above. Switching keeps
/// both built, so an editor left open keeps what was typed.
///
/// Each side gets the height it is given and scrolls on its own.
class EditorPreviewLayout extends StatefulWidget {
  /// Lays out [editor] and [preview].
  const EditorPreviewLayout({
    required this.editor,
    required this.preview,
    super.key,
  });

  /// Narrower than this shows one side at a time.
  static const double sideBySideMinWidth = 1000;

  /// Padding around the switch.
  static const double switchPadding = 12;

  /// Size of the switch's icons.
  static const double switchIconSize = 16;

  /// The switch's label for the editor.
  static const String editLabel = 'Edit';

  /// The switch's label for the preview.
  static const String previewLabel = 'Preview';

  /// What edits.
  final Widget editor;

  /// The live preview.
  final Widget preview;

  @override
  State<EditorPreviewLayout> createState() => EditorPreviewLayoutState();
}

/// State of [EditorPreviewLayout]: which side a narrow screen shows.
class EditorPreviewLayoutState extends State<EditorPreviewLayout> {
  /// Whether a narrow screen shows the preview.
  bool showingPreview = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= EditorPreviewLayout.sideBySideMinWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: widget.editor),
              const VerticalDivider(width: 1),
              Expanded(child: widget.preview),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(EditorPreviewLayout.switchPadding),
              child: Row(
                spacing: EditorPreviewLayout.switchPadding,
                children: [
                  for (final preview in [false, true])
                    (preview == showingPreview
                        ? ShadButton.new
                        : ShadButton.outline)(
                      onPressed: () => setState(() => showingPreview = preview),
                      leading: Icon(
                        preview ? LucideIcons.eye : LucideIcons.pencil,
                        size: EditorPreviewLayout.switchIconSize,
                      ),
                      child: Text(
                        preview
                            ? EditorPreviewLayout.previewLabel
                            : EditorPreviewLayout.editLabel,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: showingPreview ? 1 : 0,
                sizing: StackFit.expand,
                children: [widget.editor, widget.preview],
              ),
            ),
          ],
        );
      },
    );
  }
}
