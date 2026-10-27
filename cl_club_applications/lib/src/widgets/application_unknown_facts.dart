import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_fact_strings.dart';
import '../constants/application_view_sizes.dart';

/// What the client's own check finds before Save (club_client#389): each
/// `{gap}` of a printed text that names no fact of the template, by place
/// and language.
class ApplicationUnknownFacts extends StatelessWidget {
  const ApplicationUnknownFacts({required this.gaps, super.key});

  /// The gaps, as shown.
  final List<String> gaps;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final error = theme.colorScheme.destructive;
    return Column(
      key: const ValueKey('application.state.unknownFacts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ApplicationViewSizes.listGap,
      children: [
        Text(
          ApplicationFactStrings.unknownIntro,
          style: theme.textTheme.small.copyWith(color: error),
        ),
        for (final line in gaps)
          Padding(
            padding: const EdgeInsets.only(
              left: ApplicationViewSizes.listIndent,
            ),
            child: Text(
              line,
              style: theme.textTheme.muted.copyWith(
                color: error,
                fontSize: ApplicationViewSizes.listFontSize,
              ),
            ),
          ),
      ],
    );
  }
}
