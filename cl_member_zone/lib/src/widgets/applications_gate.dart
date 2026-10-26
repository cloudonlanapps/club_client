import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:cl_remote_store/cl_remote_store.dart' show applicationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The route gate the Applications screens share (club_client#321).
///
/// An Applications route opens only when the server offers applications
/// (`applicationsProvider` is `true`) and [allow] admits the signed-in
/// user. While the capability is unknown it shows a spinner, never a guess;
/// the user check is a [RoleGate], whose refusal is the shared
/// `AccessDeniedView`.
class ApplicationsGate extends ConsumerWidget {
  const ApplicationsGate({
    required this.allow,
    required this.builder,
    required this.onHome,
    super.key,
  });

  /// Whether the signed-in user may open the route.
  final bool Function(UserPrivate user) allow;

  /// Builds the view for an admitted user.
  final Widget Function(UserPrivate user) builder;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(applicationsProvider);
    if (on == null) return const Center(child: ShadProgress());
    return RoleGate(
      allow: (user) => on && allow(user),
      onHome: onHome,
      builder: builder,
    );
  }
}
