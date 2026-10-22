import 'package:cl_remote_store/cl_remote_store.dart'
    show clDeletedEvaluationTemplatesProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../constants/template_restore_strings.dart';
import 'deleted_template_row.dart';
import 'evaluation_message.dart';

/// The deleted templates by name, each with **Restore** (club_client#277).
/// A restore takes its row away: the list refetches after every template
/// write. The spinner shows only before the first list, never on a reload.
class DeletedTemplateList extends ConsumerWidget {
  /// The deleted templates.
  const DeletedTemplateList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(clDeletedEvaluationTemplatesProvider);
    return deleted.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: ShadProgress()),
      error: (_, _) =>
          const EvaluationMessage(message: EvaluationViewStrings.loadFailed),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            TemplateRestoreStrings.noDeletedTemplates,
            style: ShadTheme.of(context).textTheme.muted,
          );
        }
        final byName = [...list]..sort((a, b) => a.name.compareTo(b.name));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EvaluationViewSizes.rowGap,
          children: [
            for (final t in byName)
              DeletedTemplateRow(key: ValueKey(t.id), template: t),
          ],
        );
      },
    );
  }
}
