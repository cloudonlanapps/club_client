import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../utils/application_section_lines.dart';

/// A section's read mode: one row per line, its label beside what prints,
/// the label in the larger type; on a narrow card (a phone) the label
/// stands above what prints (club_client#408). A blank line shows nothing,
/// or Required in the error colour when its label is one of [required].
class ApplicationSectionRead extends StatelessWidget {
  const ApplicationSectionRead({
    required this.lines,
    this.required = const {},
    super.key,
  });

  /// The section's lines.
  final List<ApplicationReadLine> lines;

  /// The labels of the lines that must be written before Finalize.
  final Set<String> required;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final value = theme.textTheme.small.copyWith(
      fontSize: ApplicationViewSizes.readValueFontSize,
      fontWeight: FontWeight.normal,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < ApplicationViewSizes.readStackBelow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ApplicationViewSizes.smallGap,
          children: [
            for (final line in lines)
              _line(line, stacked: stacked, theme: theme, value: value),
          ],
        );
      },
    );
  }

  Widget _line(
    ApplicationReadLine line, {
    required bool stacked,
    required ShadThemeData theme,
    required TextStyle value,
  }) {
    final label = Text(line.label, style: theme.textTheme.small);
    final text = line.value.isEmpty
        ? Text(
            required.contains(line.label)
                ? ApplicationViewStrings.required
                : '',
            style: value.copyWith(color: theme.colorScheme.destructive),
          )
        : Text(line.value, style: value);
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ApplicationViewSizes.listGap,
        children: [label, text],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        SizedBox(width: ApplicationViewSizes.readLabelWidth, child: label),
        Expanded(child: text),
      ],
    );
  }
}
