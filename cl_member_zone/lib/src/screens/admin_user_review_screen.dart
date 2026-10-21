import 'package:cl_club_members/cl_club_members.dart' show AdminUserReviewView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin pending-user review screen for a single [username].
///
/// Wraps [AdminUserReviewView]. The host (router) supplies the username
/// from the URL query string and the back navigation.
class AdminUserReviewScreen extends ConsumerWidget {
  const AdminUserReviewScreen({
    required this.username,
    required this.onBack,
    required this.onHome,
    super.key,
  });

  final String username;
  final VoidCallback onBack;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (user) => AdminUserReviewView(
        currentUser: user,
        username: username,
        onBack: onBack,
      ),
    );
  }
}
