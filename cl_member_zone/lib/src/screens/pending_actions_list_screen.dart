import 'package:cl_club_communication/cl_club_communication.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending Actions list screen at `/memberzone/pending-actions`.
class PendingActionsListScreen extends ConsumerWidget {
  const PendingActionsListScreen({
    required this.onDeepLink,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final void Function(NotificationDeepLink link) onDeepLink;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PendingActionsListView(
      currentUser: user,
      onDeepLink: onDeepLink,
      onHome: onHome,
      onBack: onBack,
    );
  }
}
