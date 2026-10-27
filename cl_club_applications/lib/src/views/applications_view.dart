import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart' show applicationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_strings.dart';
import '../widgets/admin_application_list.dart';
import '../widgets/application_create_dialog.dart';
import '../widgets/application_page.dart';

/// The admin's Applications page, under Club Management (club_client#321,
/// #380): every template with its state, opened on tap, duplicated, and
/// created with **Create application**. The club's Library of texts is on
/// Club details (club_client#399). Members, admins included, download
/// their own forms from `MyApplicationsView`. Renders nothing unless the
/// server offers applications.
class ApplicationsView extends ConsumerWidget {
  const ApplicationsView({
    required this.currentUser,
    required this.onOpen,
    super.key,
  });

  /// The signed-in admin.
  final UserPrivate currentUser;

  /// Opens the template with this id in the editor.
  final ValueChanged<int> onOpen;

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
      trailing: ShadButton(
        onPressed: () => unawaited(create(context)),
        leading: const Icon(LucideIcons.plus),
        child: const Text(ApplicationViewStrings.create),
      ),
      children: [AdminApplicationList(onOpen: onOpen)],
    );
  }
}
