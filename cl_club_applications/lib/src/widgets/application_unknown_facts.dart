import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_fact_strings.dart';
import '../constants/application_view_strings.dart';

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
    return Column(
      key: const ValueKey('application.state.unknownFacts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ApplicationFactStrings.unknownTitle, style: theme.textTheme.small),
        Text(
          ApplicationFactStrings.unknownIntro,
          style: theme.textTheme.muted,
        ),
        for (final gap in gaps)
          Text(
            '${ApplicationViewStrings.bullet}$gap',
            style: theme.textTheme.p,
          ),
      ],
    );
  }
}
