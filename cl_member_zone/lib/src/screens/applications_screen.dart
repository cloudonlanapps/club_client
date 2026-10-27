import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationsView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/widgets.dart';

import '../widgets/applications_gate.dart';

/// The admin's Applications page at `/memberzone/applications`, under Club
/// Management (club_client#321, #380): admins only, while the server offers
/// applications. Members download their forms from `MyApplicationsScreen`.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({
    required this.onOpen,
    required this.onPickJsonFile,
    required this.onHome,
    super.key,
  });

  /// Opens the template with this id in the editor.
  final ValueChanged<int> onOpen;

  /// Lets the admin pick an exported application file (Import JSON).
  final Future<Uint8List?> Function() onPickJsonFile;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => ApplicationsGate(
    allow: RoleGate.admin,
    onHome: onHome,
    builder: (user) => ApplicationsView(
      currentUser: user,
      onOpen: onOpen,
      onPickJsonFile: onPickJsonFile,
    ),
  );
}
