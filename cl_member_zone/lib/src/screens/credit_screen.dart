import 'package:cl_club_credits/cl_club_credits.dart' show CreditView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:cl_remote_store/cl_remote_store.dart' show creditSystemProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

/// A member's credit at `/memberzone/credit/:targetUsername` (club_core#32,
/// #101): the route a `credit.released` notification opens. Everywhere
/// else the credit view opens in a sheet from a chip.
///
/// Gates: the credit system must be on (unknown shows a spinner, off is
/// refused), and the viewer must be the member or staff.
class CreditScreen extends ConsumerWidget {
  const CreditScreen({
    required this.targetUsername,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final String targetUsername;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credit = ref.watch(creditSystemProvider);
    if (credit == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RoleGate(
      allow: (user) =>
          credit && (user.username == targetUsername || user.isCoachOrAdmin),
      onHome: onHome,
      builder: (user) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleRow(title: targetUsername, onBack: onBack),
          const Divider(height: 1),
          Expanded(
            child: CreditView(currentUser: user, username: targetUsername),
          ),
        ],
      ),
    );
  }
}
