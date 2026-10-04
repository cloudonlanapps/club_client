import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../markdown/themed_markdown.dart';

/// Markdown in reading direction, in the body style unless [style] is
/// given: a question, an info text, a written answer.
class EvaluationMarkdownText extends StatelessWidget {
  /// Renders [data].
  const EvaluationMarkdownText({required this.data, this.style, super.key});

  /// The markdown.
  final String data;

  /// The text style; the theme's paragraph style by default.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ThemedMarkdown(
    data: data,
    textAlign: TextAlign.start,
    selectable: false,
    textStyle: style ?? ShadTheme.of(context).textTheme.p,
  );
}
