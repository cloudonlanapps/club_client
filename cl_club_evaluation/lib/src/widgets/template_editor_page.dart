import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart'
    show EditorPreviewLayout, EvaluationLayoutEntry, EvaluationTemplatePreview;

import '../constants/evaluation_view_sizes.dart';
import 'evaluation_page.dart';

/// A template screen — the detail or the designer — with its live preview
/// (club_client#28): [header] across the top, then the [editor]'s
/// children beside a preview of [layout] as the review form, or switched
/// with it on a narrow screen ([EditorPreviewLayout]). Each side scrolls
/// on its own.
class TemplateEditorPage extends StatelessWidget {
  /// Lays out [header], [editor] and the preview of [layout].
  const TemplateEditorPage({
    required this.header,
    required this.editor,
    required this.layout,
    super.key,
  });

  /// The title and the screen's actions.
  final Widget header;

  /// What edits the template, top to bottom.
  final List<Widget> editor;

  /// The template's layout as it stands, for the preview.
  final List<EvaluationLayoutEntry> layout;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          EvaluationViewSizes.pagePadding,
          EvaluationViewSizes.pagePadding,
          EvaluationViewSizes.pagePadding,
          0,
        ),
        child: header,
      ),
      Expanded(
        child: EditorPreviewLayout(
          editor: EvaluationPage(children: editor),
          preview: EvaluationPage(
            children: [EvaluationTemplatePreview(layout: layout)],
          ),
        ),
      ),
    ],
  );
}
