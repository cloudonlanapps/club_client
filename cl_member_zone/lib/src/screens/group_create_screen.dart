import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [GroupCreateView] for
/// `/memberzone/groups/new`.
class GroupCreateScreen extends ConsumerWidget {
  const GroupCreateScreen({
    required this.onCreated,
    required this.onCancel,
    required this.onHome,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.admin,
      onHome: onHome,
      builder: (_) => GroupCreateView(onCreated: onCreated, onCancel: onCancel),
    );
  }
}
