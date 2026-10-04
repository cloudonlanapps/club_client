import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A theme-aware MarkdownWidget that uses shadcn theme colors.
class ThemedMarkdown extends StatelessWidget {
  const ThemedMarkdown({
    required this.data,
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.selectable = true,
  });
  final String data;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  /// When false the markdown is not wrapped in a `SelectionArea`, so taps
  /// pass through to an enclosing gesture handler. Defaults to true to match
  /// the standalone (bio / description) display callers; set false when the
  /// markdown sits inside a tappable surface like a notification row.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use dark or light config as base
    final baseConfig = isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;

    // Build custom text style
    final style = textStyle ?? theme.textTheme.muted;

    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: baseConfig.copy(
        configs: [
          PConfig(textStyle: style),
        ],
      ),
      generator: MarkdownGenerator(
        richTextBuilder: (span) => Text.rich(
          span,
          textAlign: textAlign,
        ),
      ),
    );
  }
}
