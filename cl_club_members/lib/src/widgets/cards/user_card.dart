import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart';

import 'actions/admin_user_actions.dart';

/// List-row card for a single user.
///
/// Caller passes only [username] and navigation callbacks; the card
/// resolves the [UserInfo] from `clUsersMasterProvider` (admin/coach
/// surfaces) and decides whether to mount [AdminUserActions] internally.
///
/// Self-view (the acting user looking at their own card) does not yet
/// surface any inline actions — profile editing is reached via the
/// user-profile screen. The hook is in place for a future "Edit my
/// profile" inline action via [onEdit].
class UserCard extends ConsumerWidget {
  const UserCard({
    required this.username,
    this.user,
    this.onTap,
    this.onReview,
    this.onEdit,
    super.key,
  });

  final String username;

  /// The user, for a caller that already holds it. Used when
  /// `clUsersMasterProvider` does not carry them: a `registered` user is
  /// never in it (#91).
  final UserInfo? user;

  /// Row tap handler. Typically navigates to the user profile screen.
  /// Suppressed automatically for non-active users so admins can't tap
  /// through to a blocked / left user's detail.
  final VoidCallback? onTap;

  /// Pending/registered users only — wires the Review action to the
  /// admin review surface. Card tap (`onTap`) still routes to the user's
  /// profile; the Review action is the dedicated path into the review
  /// page-view.
  final VoidCallback? onReview;

  /// Self-perspective only — wires the "Edit my profile" hook for a
  /// future inline action. Today this is a no-op on every surface and
  /// no production caller passes it.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(clUsersMasterProvider).valueOrNull?[username] ?? this.user;
    if (user == null) {
      return EntityCard(
        image: EntityImage.initials('?'),
        title: '@$username',
        onTap: onTap,
      );
    }

    final muted =
        user.status == UserStatus.blocked || user.status == UserStatus.left;

    final avatarUrl = ref.watch(avatarImageProvider(user.username)).value;
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    final image = avatarUrl != null
        ? EntityImage.network(avatarUrl, httpHeaders: headers)
        : EntityImage.initials(_initials(user));

    EntityCard card(List<ActionItem> actions) => EntityCard(
      image: image,
      title: user.displayName,
      caption: _captionFor(user),
      body: UserBody(user: user),
      trailingActions: actions.isEmpty ? null : actions,
      onTap: onTap,
      muted: muted,
    );

    // AdminUserActions hosts the resolved actions (and gates on admin role
    // internally — non-admins resolve to an empty list).
    return AdminUserActions(
      username: username,
      onReview: onReview,
      builder: (context, actions) => card(actions),
    );
  }

  static String _captionFor(UserInfo user) {
    return switch (user.status) {
      UserStatus.pending => 'Awaiting approval',
      UserStatus.blocked => '@${user.username} · blocked',
      UserStatus.left => '@${user.username} · has left',
      UserStatus.active => '@${user.username}',
      // Signed up, not yet submitted: listed only under the Members
      // screen's "Registered" filter (#91).
      UserStatus.registered => '@${user.username} · onboarding',
    };
  }

  static String _initials(UserInfo user) {
    final first = (user.firstName ?? '').trim();
    final last = (user.lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (user.displayName.isNotEmpty) {
      return user.displayName[0].toUpperCase();
    }
    return '?';
  }
}

class UserBody extends StatelessWidget {
  const UserBody({required this.user, super.key});

  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    if (user.roles.isAdmin) {
      badges.add(const StatusBadge(label: 'Admin'));
    }
    if (user.roles.isCoach) {
      badges.add(const StatusBadge(label: 'Coach'));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges,
    );
  }
}
