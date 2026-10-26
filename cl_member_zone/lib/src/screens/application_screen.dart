import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/widgets.dart';

import '../widgets/applications_gate.dart';

/// One application template in the admin's editor at
/// `/memberzone/applications/:id` (club_client#321): admins only, while the
/// server offers applications.
class ApplicationScreen extends StatelessWidget {
  const ApplicationScreen({
    required this.applicationId,
    required this.onBack,
    required this.onDeleted,
    required this.onOpenPdfBytes,
    required this.onHome,
    super.key,
  });

  /// The template's id.
  final int applicationId;

  /// Leaves the editor.
  final VoidCallback onBack;

  /// Leaves the editor once the template is deleted.
  final VoidCallback onDeleted;

  /// Opens the preview.
  final ValueChanged<Uint8List> onOpenPdfBytes;

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
      onOpenPdfBytes: onOpenPdfBytes,
    ),
  );
}
