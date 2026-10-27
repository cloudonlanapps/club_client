import 'dart:async';
import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show applicationsProvider, clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationContent, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_template_file.dart';
import '../utils/application_save_refusal.dart';
import '../widgets/admin_application_list.dart';
import '../widgets/application_create_dialog.dart';
import '../widgets/application_page.dart';

/// The admin's Applications page, under Club Management (club_client#321,
/// #380): every template with its state, opened on tap, duplicated, and
/// created with **Create application**, or imported from an exported file
/// with **Import JSON** (club_client#400). The club's Library of texts is
/// on Club details (club_client#399). Members, admins included, download
/// their own forms from `MyApplicationsView`. Renders nothing unless the
/// server offers applications.
class ApplicationsView extends ConsumerWidget {
  const ApplicationsView({
    required this.currentUser,
    required this.onOpen,
    required this.onPickJsonFile,
    super.key,
  });

  /// The signed-in admin.
  final UserPrivate currentUser;

  /// Opens the template with this id in the editor.
  final ValueChanged<int> onOpen;

  /// Lets the admin pick a JSON file; its bytes, or null when cancelled.
  final Future<Uint8List?> Function() onPickJsonFile;

  /// Creates a draft from an exported file the admin picks, and opens it:
  /// a draft, so its dates and facts are checked before it is finalized.
  Future<void> import(BuildContext context, WidgetRef ref) async {
    final toaster = ShadToaster.of(context);
    final bytes = await onPickJsonFile();
    if (bytes == null) return;
    final ApplicationContent content;
    try {
      content = ApplicationTemplateFile.decode(bytes);
    } on FormatException {
      toaster.show(
        const ShadToast.destructive(
          description: Text(ApplicationViewStrings.importUnreadable),
        ),
      );
      return;
    }
    try {
      final created = await ref
          .read(clApplicationsMasterProvider.notifier)
          .createApplication(content);
      onOpen(created.id);
    } on Object catch (e) {
      // A print language the club does not offer is named (club_client#396);
      // any other refusal is a fixed message.
      toaster.show(
        ShadToast.destructive(
          description: Text(
            applicationLanguageRefusal(e) ??
                ApplicationViewStrings.importFailed,
          ),
        ),
      );
    }
  }

  /// Creates a draft and opens it.
  Future<void> create(BuildContext context) async {
    final id = await showApplicationCreateDialog(context);
    if (id != null) onOpen(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.isAdmin,
      'ApplicationsView called for a non-admin. Screen gate failed.',
    );
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    return ApplicationPage(
      heading: ApplicationViewStrings.applications,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: ApplicationViewSizes.smallGap,
        children: [
          ShadButton.outline(
            key: const ValueKey('application.importJson'),
            onPressed: () => unawaited(import(context, ref)),
            leading: const Icon(LucideIcons.fileJson),
            child: const Text(ApplicationViewStrings.importJson),
          ),
          ShadButton(
            onPressed: () => unawaited(create(context)),
            leading: const Icon(LucideIcons.plus),
            child: const Text(ApplicationViewStrings.create),
          ),
        ],
      ),
      children: [AdminApplicationList(onOpen: onOpen)],
    );
  }
}
