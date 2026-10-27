import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../utils/application_section_lines.dart';

/// A section's read mode: one row per line, its label beside what prints,
/// the label in the larger type. A blank line shows nothing, or Required in
/// the error colour when its label is one of [required].
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        for (final line in lines)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ApplicationViewSizes.smallGap,
            children: [
              SizedBox(
                width: ApplicationViewSizes.readLabelWidth,
                child: Text(line.label, style: theme.textTheme.small),
              ),
              Expanded(
                child: line.value.isEmpty
                    ? Text(
                        required.contains(line.label)
                            ? ApplicationViewStrings.required
                            : '',
                        style: value.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      )
                    : Text(line.value, style: value),
              ),
            ],
          ),
      ],
    );
  }
}
