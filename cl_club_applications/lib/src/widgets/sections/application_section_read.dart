import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/application_view_sizes.dart';
import '../../utils/application_section_lines.dart';

/// A section's read mode: one row per line, its label beside what prints.
class ApplicationSectionRead extends StatelessWidget {
  const ApplicationSectionRead({required this.lines, super.key});

  /// The section's lines.
  final List<ApplicationReadLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
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
                child: Text(line.label, style: theme.textTheme.muted),
              ),
              Expanded(child: Text(line.value, style: theme.textTheme.p)),
            ],
          ),
      ],
    );
  }
}
