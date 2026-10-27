import 'package:cl_club_applications/cl_club_applications.dart'
    show MyApplicationsView;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../widgets/applications_gate.dart';

/// A member's Applications page at `/memberzone/applications/mine`, under
/// Main (club_client#380): open to every member who reaches the member zone
/// while the server offers applications, admins included. It lists the
/// published applications the member is eligible for, to download.
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({
    required this.pdfAction,
    required this.onOpenProfile,
    required this.onHome,
    super.key,
  });

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Opens the member's own profile, for a member who says their profile is
  /// not complete before a download (club_client#340).
  final VoidCallback onOpenProfile;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => ApplicationsGate(
    allow: (_) => true,
    onHome: onHome,
    builder: (user) => MyApplicationsView(
      currentUser: user,
      pdfAction: pdfAction,
      onOpenProfile: onOpenProfile,
    ),
  );
}
