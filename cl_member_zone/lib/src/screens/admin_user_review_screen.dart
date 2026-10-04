import 'package:cl_club_members/cl_club_members.dart' show AdminUserReviewView;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

/// Admin pending-user review screen for a single [username].
///
/// Wraps [AdminUserReviewView]. The host (router) supplies the username
/// from the URL query string and the back navigation.
class AdminUserReviewScreen extends ConsumerWidget {
  const AdminUserReviewScreen({
    required this.username,
    required this.onBack,
    super.key,
  });

  final String username;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const LoadingView();
    return AdminUserReviewView(
      currentUser: user,
      username: username,
      onBack: onBack,
    );
  }
}
