import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import '../../utils/markdown_lead_paragraph.dart';

/// A short markdown preview of a venue description for the list card.
///
/// Renders only the description's lead paragraph through [ThemedMarkdown], so
/// markdown syntax is rendered rather than shown, and bounds it to
/// [previewLines] lines of the muted text style. `ThemedMarkdown` has no
/// `maxLines` and its internal column asserts when squeezed, so the preview
/// lays the markdown out at its natural height inside an unbounded
/// [OverflowBox] and clips it with a [ClipRect].
class VenueCardDescription extends StatelessWidget {
  const VenueCardDescription({required this.description, super.key});

  /// The venue's description, as markdown.
  final String description;

  /// Number of text lines the preview shows.
  static const int previewLines = 2;

  @override
  Widget build(BuildContext context) {
    final lead = markdownLeadParagraph(description);
    if (lead.isEmpty) return const SizedBox.shrink();

    final style = ShadTheme.of(context).textTheme.muted;
    final painter = TextPainter(
      text: TextSpan(
        text: List.filled(previewLines, ' ').join('\n'),
        style: style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.height;
    painter.dispose();

    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minHeight: 0,
          maxHeight: double.infinity,
          child: ThemedMarkdown(
            data: lead,
            textStyle: style,
            textAlign: TextAlign.start,
            // Inside a tappable card: let taps reach the card.
            selectable: false,
          ),
        ),
      ),
    );
  }
}
