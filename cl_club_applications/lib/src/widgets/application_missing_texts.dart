import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
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
    final error = theme.colorScheme.destructive;
    return Column(
      key: const ValueKey('application.state.missing'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ApplicationViewSizes.listGap,
      children: [
        Text(
          ApplicationViewStrings.missingIntro,
          style: theme.textTheme.small.copyWith(color: error),
        ),
        for (final line in missing)
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
