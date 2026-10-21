import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../providers/auth.dart';

/// The page a screen shows a member its gate refuses: a neutral shield,
/// "Access Denied", and [message].
///
/// [RoleGate] shows it for a role check; a screen whose check is not a
/// role (its own data, a relationship) shows it directly, so every refusal
/// reads the same.
class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({
    required this.onHome,
    this.onBack,
    this.message = defaultMessage,
    super.key,
  });

  /// The page's heading.
  static const title = 'Access Denied';

  /// The copy shown when the screen gives none of its own.
  static const defaultMessage = 'You do not have permission to view this page.';

  /// Goes to the dashboard. Supplied by the router.
  final VoidCallback onHome;

  /// Leaves the page, when the screen has a way back.
  final VoidCallback? onBack;

  /// What the member may not do.
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      tone: ErrorTone.neutral,
      icon: LucideIcons.shieldAlert,
      title: title,
      subtitle: message,
      onHome: onHome,
      onBack: onBack,
    );
  }
}

/// Route-level role gate for a screen.
///
/// Watches [authStateProvider]: shows a loader until the member is known,
/// [AccessDeniedView] when [allow] refuses them, and otherwise builds the
/// screen's view with the member as `currentUser`.
///
/// ```dart
/// RoleGate(
///   allow: (user) => user.isCoachOrAdmin,
///   onHome: onHome,
///   builder: (currentUser) => GroupListView(currentUser: currentUser, …),
/// )
/// ```
class RoleGate extends ConsumerWidget {
  const RoleGate({
    required this.allow,
    required this.onHome,
    required this.builder,
    this.onBack,
    this.deniedMessage = AccessDeniedView.defaultMessage,
    super.key,
  });

  /// Admins (super-admins included).
  static bool admin(UserPrivate user) => user.isAdmin;

  /// Coaches and admins: the club's staff.
  static bool coachOrAdmin(UserPrivate user) => user.isCoachOrAdmin;

  /// Super-admins only.
  static bool superAdmin(UserPrivate user) => user.isSuperAdmin;

  /// Whether the member may reach the screen.
  final bool Function(UserPrivate user) allow;

  /// Goes to the dashboard from the refusal. Supplied by the router.
  final VoidCallback onHome;

  /// Leaves the page from the refusal, when the screen has a way back.
  final VoidCallback? onBack;

  /// The refusal's copy.
  final String deniedMessage;

  /// Builds the screen's view for a member [allow] lets through.
  final Widget Function(UserPrivate currentUser) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading…');
    }
    if (!allow(currentUser)) {
      return AccessDeniedView(
        onHome: onHome,
        onBack: onBack,
        message: deniedMessage,
      );
    }
    return builder(currentUser);
  }
}
