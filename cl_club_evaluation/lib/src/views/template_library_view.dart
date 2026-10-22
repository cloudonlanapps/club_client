import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../constants/template_restore_strings.dart';
import '../widgets/deleted_template_list.dart';
import '../widgets/evaluation_heading.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/evaluation_page.dart';
import '../widgets/template_import_button.dart';
import '../widgets/template_library_row.dart';

/// The template library (design 4.2, `reviews/templates`; `reviews` for an
/// admin who does not coach), for coaches and admins: the live templates
/// by name, each opening on tap, with **Duplicate** and **Delete** (disabled
/// while in use); **Import**, which opens the designer pre-filled from a
/// template file (club_client#27); and **Add template**. A deleted
/// template leaves the library: **Show deleted templates** switches the
/// list to the deleted ones, each with **Restore** for any staff member
/// (club_client#277).
///
/// Renders nothing unless the server runs evaluations.
class TemplateLibraryView extends ConsumerStatefulWidget {
  /// The library, for [currentUser], a coach or an admin.
  const TemplateLibraryView({
    required this.currentUser,
    required this.onOpenTemplate,
    required this.onCreateTemplate,
    required this.onDuplicateTemplate,
    required this.onPickTemplateFile,
    required this.onImportTemplate,
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

  /// Picks a template file for **Import** and resolves to its bytes;
  /// `null` when none was chosen.
  final Future<Uint8List?> Function() onPickTemplateFile;

  /// Opens the designer pre-filled with these initial values, read from an
  /// imported file.
  final ValueChanged<Map<String, dynamic>> onImportTemplate;

  @override
  ConsumerState<TemplateLibraryView> createState() =>
      TemplateLibraryViewState();
}

/// Holds whether the library shows the deleted templates.
class TemplateLibraryViewState extends ConsumerState<TemplateLibraryView> {
  /// Whether the list shows the deleted templates instead of the live ones.
  bool showDeleted = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.currentUser;
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
              text: showDeleted
                  ? TemplateRestoreStrings.deletedTemplates
                  : EvaluationViewStrings.templates,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: EvaluationViewSizes.smallGap,
                children: [
                  TemplateImportButton(
                    onPickFile: widget.onPickTemplateFile,
                    onImported: widget.onImportTemplate,
                  ),
                  ShadButton(
                    onPressed: widget.onCreateTemplate,
                    leading: const Icon(LucideIcons.plus),
                    child: const Text(EvaluationViewStrings.addTemplate),
                  ),
                ],
              ),
            ),
            ShadSwitch(
              value: showDeleted,
              onChanged: (value) => setState(() => showDeleted = value),
              label: const Text(TemplateRestoreStrings.showDeleted),
            ),
            if (showDeleted)
              const DeletedTemplateList()
            else if (live.isEmpty)
              Text(
                EvaluationViewStrings.noTemplates,
                style: ShadTheme.of(context).textTheme.muted,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: EvaluationViewSizes.rowGap,
                children: [
                  for (final t in live)
                    TemplateLibraryRow(
                      template: t,
                      onOpen: () => widget.onOpenTemplate(t.id),
                      onDuplicate: () => widget.onDuplicateTemplate(t.id),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
