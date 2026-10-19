import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// How an event's Marketing page lays out its [editor] and its [preview]
/// (club_client#1): side by side on a wide screen; on a narrow one, one at
/// a time, with a switch between them above. Switching keeps both built.
class EventMarketingLayout extends StatefulWidget {
  const EventMarketingLayout({
    required this.editor,
    required this.preview,
    super.key,
  });

  /// Narrower than this shows one side at a time.
  static const double sideBySideMinWidth = 1000;

  /// Padding around the switch.
  static const double switchPadding = 12;

  /// The cards that edit.
  final Widget editor;

  /// The live preview.
  final Widget preview;

  @override
  State<EventMarketingLayout> createState() => EventMarketingLayoutState();
}

/// State of [EventMarketingLayout]: which side a narrow screen shows.
class EventMarketingLayoutState extends State<EventMarketingLayout> {
  bool showingPreview = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= EventMarketingLayout.sideBySideMinWidth) {
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
              padding: const EdgeInsets.all(EventMarketingLayout.switchPadding),
              child: Row(
                spacing: EventMarketingLayout.switchPadding,
                children: [
                  for (final preview in [false, true])
                    (preview == showingPreview
                        ? ShadButton.new
                        : ShadButton.outline)(
                      onPressed: () => setState(() => showingPreview = preview),
                      leading: Icon(
                        preview ? LucideIcons.eye : LucideIcons.pencil,
                        size: 16,
                      ),
                      child: Text(preview ? 'Preview' : 'Edit'),
                    ),
                ],
              ),
            ),
            // Both stay built, so an editor left open keeps what was typed.
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
