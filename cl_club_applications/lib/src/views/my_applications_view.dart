import 'package:cl_remote_store/cl_remote_store.dart' show applicationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_strings.dart';
import '../widgets/application_page.dart';
import '../widgets/published_applications_list.dart';

/// A member's Applications page, under Main (club_client#380): the
/// published applications the member is eligible for, each with Download,
/// for every member, admins included. Renders nothing unless the server
/// offers applications.
class MyApplicationsView extends ConsumerWidget {
  const MyApplicationsView({
    required this.currentUser,
    required this.pdfAction,
    required this.onOpenProfile,
    super.key,
  });

  /// The signed-in member.
  final UserPrivate currentUser;

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Opens the member's own profile, for a member who says their profile is
  /// not complete before a download (club_client#340).
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    return ApplicationPage(
      heading: ApplicationViewStrings.applications,
      children: [
        PublishedApplicationsList(
          currentUser: currentUser,
          pdfAction: pdfAction,
          onOpenProfile: onOpenProfile,
        ),
      ],
    );
  }
}
