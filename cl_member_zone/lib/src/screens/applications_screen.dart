import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationsView;
import 'package:flutter/widgets.dart';

import '../widgets/applications_gate.dart';

/// The Applications page at `/memberzone/applications` (club_client#321):
/// open to every member who reaches the member zone while the server offers
/// applications. Members download their form; admins manage the templates.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({
    required this.onOpen,
    required this.onOpenPdfBytes,
    required this.onHome,
    super.key,
  });

  /// Opens the template with this id in the editor.
  final ValueChanged<int> onOpen;

  /// Opens a downloaded form.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => ApplicationsGate(
    allow: (_) => true,
    onHome: onHome,
    builder: (user) => ApplicationsView(
      currentUser: user,
      onOpen: onOpen,
      onOpenPdfBytes: onOpenPdfBytes,
    ),
  );
}
