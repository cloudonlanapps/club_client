import 'package:cl_member_auth/cl_member_auth.dart'
    show AccessDeniedView, RoleGate;
import 'package:cl_remote_store/cl_remote_store.dart' show evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The route gate every review screen shares (club_core#174, design 4.1).
///
/// A review route opens only when the server runs evaluations
/// (`evaluationsProvider` is `true`) and [allows] the signed-in user. While
/// the capability is unknown it shows a spinner, never a guess; the user
/// check is a [RoleGate], whose refusal is the shared [AccessDeniedView].
class EvaluationGate extends ConsumerWidget {
  /// Gates [builder] on the capability and [allows].
  const EvaluationGate({
    required this.allows,
    required this.builder,
    required this.onHome,
    super.key,
  });

  /// Title of the refusal.
  static const String deniedTitle = AccessDeniedView.title;

  /// Body of the refusal.
  static const String deniedSubtitle = AccessDeniedView.defaultMessage;

  /// Whether the signed-in user may open the route.
  final bool Function(UserPrivate user) allows;

  /// Builds the view for an allowed user.
  final Widget Function(UserPrivate user) builder;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(evaluationsProvider);
    if (on == null) {
      return const Center(child: ShadProgress());
    }
    return RoleGate(
      allow: (user) => on && allows(user),
      onHome: onHome,
      builder: builder,
    );
  }
}
