import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show
        applicationLabelsProvider,
        applicationsProvider,
        clApplicationLibraryMasterProvider,
        emptyApplicationClauses,
        emptyApplicationLabels;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/application_library_strings.dart';
import '../../constants/application_view_sizes.dart';
import '../../models/application_editor_options.dart';
import 'application_library_text_card.dart';
import 'application_library_text_dialog.dart';

/// The **Library** card (club_client#389, #396): every text of the club's
/// library, the seeded built-in clauses among them, oldest first, each
/// edited in place and deleted from its card, and **Add text**. Every
/// application's sections offer the same texts.
/// Shown on Club details after Profile options, passed in by its screen;
/// renders nothing unless the server offers applications.
class ApplicationLibrarySection extends ConsumerWidget {
  const ApplicationLibrarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final texts = ref.watch(clApplicationLibraryMasterProvider);
    // The catalogue's languages; English alone when it cannot be read.
    final labels = ref.watch(applicationLabelsProvider);
    final languages = labels.isLoading && !labels.hasValue
        ? null
        : ApplicationEditorOptions.from(
            labels.valueOrNull ?? emptyApplicationLabels,
            emptyApplicationClauses,
          ).languageOptions;
    final Widget body;
    if (texts.isLoading && !texts.hasValue || languages == null) {
      body = const Center(child: ShadProgress());
    } else if (!texts.hasValue) {
      body = Text(
        ApplicationLibraryStrings.loadFailed,
        style: theme.textTheme.muted,
      );
    } else if (texts.requireValue.isEmpty) {
      body = Text(
        ApplicationLibraryStrings.empty,
        style: theme.textTheme.muted,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ApplicationViewSizes.rowGap,
        children: [
          for (final text in texts.requireValue.values)
            ApplicationLibraryTextCard(text: text, languages: languages),
        ],
      );
    }
    return ShadCard(
      key: const ValueKey('application.library'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ApplicationViewSizes.smallGap,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ApplicationLibraryStrings.title,
                  style: theme.textTheme.h4,
                ),
              ),
              ShadButton.outline(
                onPressed: languages == null
                    ? null
                    : () => unawaited(
                        showApplicationLibraryTextDialog(
                          context,
                          languages: languages,
                        ),
                      ),
                leading: const Icon(LucideIcons.plus),
                child: const Text(ApplicationLibraryStrings.add),
              ),
            ],
          ),
          Text(ApplicationLibraryStrings.intro, style: theme.textTheme.muted),
          body,
        ],
      ),
    );
  }
}
