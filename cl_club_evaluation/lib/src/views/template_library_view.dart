import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../widgets/evaluation_heading.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/evaluation_page.dart';
import '../widgets/template_library_row.dart';

/// The template library (design 4.2, `reviews/templates`; `reviews` for an
/// admin who does not coach), for coaches and admins: the live templates
/// by name, each opening on tap, with **Duplicate** and **Delete** (disabled
/// while in use); and **Add template**. A deleted template leaves the
/// library; Restore is not offered in the UI yet.
///
/// Renders nothing unless the server runs evaluations.
class TemplateLibraryView extends ConsumerWidget {
  /// The library, for [currentUser], a coach or an admin.
  const TemplateLibraryView({
    required this.currentUser,
    required this.onOpenTemplate,
    required this.onCreateTemplate,
    required this.onDuplicateTemplate,
    super.key,
  });

  /// The signed-in coach or admin.
  final UserPrivate currentUser;

  /// Opens the template with this id.
  final ValueChanged<int> onOpenTemplate;

  /// Opens the template designer.
  final VoidCallback onCreateTemplate;

  /// Opens the designer pre-filled with a copy of the template with this
  /// id.
  final ValueChanged<int> onDuplicateTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.roles.isCoach || currentUser.isAdmin,
      'TemplateLibraryView called for ${currentUser.username}, who is '
      'neither a coach nor an admin. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final templates = ref.watch(clEvaluationTemplatesMasterProvider);
    return templates.when(
      loading: () => const Center(child: ShadProgress()),
      error: (_, _) =>
          const EvaluationMessage(message: EvaluationViewStrings.loadFailed),
      data: (map) {
        final live = map.values.where((t) => t.deletedAtUtc == null).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return EvaluationPage(
          children: [
            EvaluationHeading(
              text: EvaluationViewStrings.templates,
              trailing: ShadButton(
                onPressed: onCreateTemplate,
                leading: const Icon(LucideIcons.plus),
                child: const Text(EvaluationViewStrings.addTemplate),
              ),
            ),
            if (live.isEmpty)
              Text(
                EvaluationViewStrings.noTemplates,
                style: ShadTheme.of(context).textTheme.muted,
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: EvaluationViewSizes.rowGap,
              children: [
                for (final t in live)
                  TemplateLibraryRow(
                    template: t,
                    onOpen: () => onOpenTemplate(t.id),
                    onDuplicate: () => onDuplicateTemplate(t.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
