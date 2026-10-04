import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/template_detail_body.dart';

/// One template, edited section by section in place (design 4.2,
/// `reviews/templates/:id`): a rename dialog from its management button,
/// and the layout — items edited in a dialog, sorted, grouped into
/// sections — each change written as the server's atomic call. A template
/// an evaluation uses (`inUse`) opens with its layout read-only and an
/// explanation; renaming stays open. Should it come into use after it was
/// read, the server's `TEMPLATE_IN_USE` refusal turns it read-only the same
/// way. **Duplicate** hands the template to [onDuplicate]; **Delete** is
/// always shown, disabled while in use, and leaves through [onBack] once
/// done. Open to coaches and admins.
///
/// Renders nothing unless the server runs evaluations.
class TemplateDetailView extends ConsumerWidget {
  /// Template [templateId], for [currentUser], a coach or an admin.
  const TemplateDetailView({
    required this.currentUser,
    required this.templateId,
    required this.onBack,
    required this.onDuplicate,
    super.key,
  });

  /// The signed-in coach or admin.
  final UserPrivate currentUser;

  /// The template.
  final int templateId;

  /// Leaves the view.
  final VoidCallback onBack;

  /// Opens the designer pre-filled with a copy of the template with this
  /// id.
  final ValueChanged<int> onDuplicate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.roles.isCoach || currentUser.isAdmin,
      'TemplateDetailView called for ${currentUser.username}, who is '
      'neither a coach nor an admin. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final templates = ref.watch(clEvaluationTemplatesMasterProvider);
    return templates.when(
      loading: () => const Center(child: ShadProgress()),
      error: (_, _) => EvaluationMessage(
        message: EvaluationViewStrings.loadFailed,
        onBack: onBack,
      ),
      data: (map) {
        final template = map[templateId];
        if (template == null || template.deletedAtUtc != null) {
          return EvaluationMessage(
            message: EvaluationViewStrings.templateMissing,
            onBack: onBack,
          );
        }
        return TemplateDetailBody(
          template: template,
          onDeleted: onBack,
          onDuplicate: () => onDuplicate(templateId),
        );
      },
    );
  }
}
