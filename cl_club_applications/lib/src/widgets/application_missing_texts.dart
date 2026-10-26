import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_strings.dart';

/// What the client's own check finds a draft still lacks before Save: each
/// text that is missing or not written in every print language.
class ApplicationMissingTexts extends StatelessWidget {
  const ApplicationMissingTexts({required this.missing, super.key});

  /// The texts, as shown.
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      key: const ValueKey('application.state.missing'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ApplicationViewStrings.missingTitle, style: theme.textTheme.small),
        Text(ApplicationViewStrings.missingIntro, style: theme.textTheme.muted),
        for (final place in missing)
          Text(
            '${ApplicationViewStrings.bullet}$place',
            style: theme.textTheme.p,
          ),
      ],
    );
  }
}
