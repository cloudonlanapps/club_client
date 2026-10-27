import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../widgets/applications_gate.dart';

/// One application template in the admin's editor at
/// `/memberzone/applications/:id` (club_client#321): admins only, while the
/// server offers applications.
class ApplicationScreen extends StatelessWidget {
  const ApplicationScreen({
    required this.applicationId,
    required this.onBack,
    required this.onDeleted,
    required this.pdfAction,
    required this.onHome,
    super.key,
  });

  /// The template's id.
  final int applicationId;

  /// Leaves the editor.
  final VoidCallback onBack;

  /// Leaves the editor once the template is deleted.
  final VoidCallback onDeleted;

  /// What the downloaded preview is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => ApplicationsGate(
    allow: RoleGate.admin,
    onHome: onHome,
    builder: (user) => ApplicationView(
      currentUser: user,
      applicationId: applicationId,
      onBack: onBack,
      onDeleted: onDeleted,
      pdfAction: pdfAction,
    ),
  );
}
