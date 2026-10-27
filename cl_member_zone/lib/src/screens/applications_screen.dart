import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationsView;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../widgets/applications_gate.dart';

/// The Applications page at `/memberzone/applications` (club_client#321):
/// open to every member who reaches the member zone while the server offers
/// applications. Members download their form; admins manage the templates.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({
    required this.onOpen,
    required this.pdfAction,
    required this.onHome,
    super.key,
  });

  /// Opens the template with this id in the editor.
  final ValueChanged<int> onOpen;

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => ApplicationsGate(
    allow: (_) => true,
    onHome: onHome,
    builder: (user) => ApplicationsView(
      currentUser: user,
      onOpen: onOpen,
      pdfAction: pdfAction,
    ),
  );
}
