import 'package:cl_remote_store/cl_remote_store.dart'
    show
        applicationLabelsProvider,
        applicationsProvider,
        emptyApplicationClauses;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/application_label_strings.dart';
import '../../constants/application_view_sizes.dart';
import '../../models/application_editor_options.dart';
import 'application_label_card.dart';

/// The **Labels** card (club_client#396): the club's application labels,
/// each with its text in every one of the club's languages and edited in
/// place, so a language added in Profile options can be filled in. Shown
/// on Club details after the Library card, passed in by its screen;
/// renders nothing unless the server offers applications.
class ApplicationLabelsSection extends ConsumerWidget {
  const ApplicationLabelsSection({super.key});

  /// The card's key, for tests and the integration suite.
  static const Key cardKey = ValueKey('application.labels');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final labels = ref.watch(applicationLabelsProvider);
    final Widget body;
    if (labels.isLoading && !labels.hasValue) {
      body = const Center(child: ShadProgress());
    } else if (!labels.hasValue) {
      body = Text(
        ApplicationLabelStrings.loadFailed,
        style: theme.textTheme.muted,
      );
    } else if (labels.requireValue.labels.isEmpty) {
      body = Text(ApplicationLabelStrings.empty, style: theme.textTheme.muted);
    } else {
      final value = labels.requireValue;
      final options = ApplicationEditorOptions.from(
        value,
        emptyApplicationClauses,
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ApplicationViewSizes.rowGap,
        children: [
          for (final label in options.labels)
            ApplicationLabelCard(
              labelKey: label.id,
              text: label.text,
              languages: options.languageOptions,
            ),
        ],
      );
    }
    return ShadCard(
      key: cardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ApplicationViewSizes.smallGap,
        children: [
          Text(ApplicationLabelStrings.title, style: theme.textTheme.h4),
          Text(ApplicationLabelStrings.intro, style: theme.textTheme.muted),
          body,
        ],
      ),
    );
  }
}
