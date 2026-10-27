import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart' show applicationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_strings.dart';
import '../widgets/admin_application_list.dart';
import '../widgets/application_create_dialog.dart';
import '../widgets/application_page.dart';
import '../widgets/published_applications_list.dart';

/// The Applications page at `/memberzone/applications` (club_client#321).
///
/// A member sees the published applications, each with Download, and what
/// to do with the form. An admin sees every template with its state, opens
/// one on tap, duplicates one, and creates one with **Create application**.
/// Renders nothing unless the server offers applications.
class ApplicationsView extends ConsumerWidget {
  const ApplicationsView({
    required this.currentUser,
    required this.onOpen,
    required this.pdfAction,
    super.key,
  });

  /// The signed-in member.
  final UserPrivate currentUser;

  /// Opens the template with this id in the editor (admins).
  final ValueChanged<int> onOpen;

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Creates a draft and opens it.
  Future<void> create(BuildContext context) async {
    final id = await showApplicationCreateDialog(context);
    if (id != null) onOpen(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final admin = currentUser.isAdmin;
    return ApplicationPage(
      heading: ApplicationViewStrings.applications,
      trailing: admin
          ? ShadButton(
              onPressed: () => unawaited(create(context)),
              leading: const Icon(LucideIcons.plus),
              child: const Text(ApplicationViewStrings.create),
            )
          : null,
      children: [
        if (admin)
          AdminApplicationList(onOpen: onOpen)
        else
          PublishedApplicationsList(
            currentUser: currentUser,
            pdfAction: pdfAction,
          ),
      ],
    );
  }
}
