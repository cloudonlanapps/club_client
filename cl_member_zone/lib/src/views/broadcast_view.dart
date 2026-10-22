import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:cl_club_communication/cl_club_communication.dart'
    show showWriteFailure;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        BroadcastComposeResult,
        BroadcastComposer,
        PickerUser,
        TitleRow,
        showUserSelectionDialog;

import '../theme/layout_constants.dart';
import '../widgets/panels/shared/broadcast_layout.dart';
import '../widgets/panels/shared/broadcast_sent_sliver.dart';

/// Shown when revoking a broadcast fails.
const String revokeFailedMessage =
    'Could not revoke the broadcast. Please try again.';

/// Shown when sending a broadcast fails.
const String sendFailedMessage =
    'Could not send the broadcast. Please try again.';

/// Shown when Staff only is on and the audience has no staff.
const String noStaffMessage = 'There is no staff to send this to.';

/// The Broadcast screen's body for one audience, its [scope]
/// (club_client#252): all members, a group, an event or one member.
///
/// Composes a message ([BroadcastComposer]) to the scope's audience and
/// lists the broadcasts sent from this scope's screen, each with Revoke.
/// Except on the one-to-one screen ([BroadcastScope.canNarrow]) the audience
/// can be narrowed, either to its staff (**Staff only**) or to members
/// picked with the shared user picker (**Choose members**); both go out as a
/// `users` audience. Every send carries the scope as `payload.source`, which
/// is what the sent list is filtered on.
class BroadcastView extends ConsumerStatefulWidget {
  const BroadcastView({
    required this.currentUser,
    required this.scope,
    required this.onClose,
    super.key,
  });

  final UserPrivate currentUser;

  /// The audience this screen sends to and lists.
  final BroadcastScope scope;

  /// Leaves the screen.
  final VoidCallback onClose;

  @override
  ConsumerState<BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends ConsumerState<BroadcastView> {
  /// Narrows the audience to its staff.
  bool _staffOnly = false;

  /// The members picked with Choose members; empty sends to the audience.
  List<String> _chosen = const [];

  BroadcastScope get _scope => widget.scope;

  /// Default subject applied when the admin sends an email broadcast without
  /// customizing the subject (see issue #737). Named after the club supplying
  /// [appBrandingProvider], so the text follows whichever club is running.
  String get _defaultEmailSubject =>
      'Broadcast Message from ${ref.read(appBrandingProvider).shortName}';

  /// Who the scope addresses, by name, for the title row.
  String _audienceLabel() {
    switch (_scope.kind) {
      case BroadcastScopeKind.all:
        return 'To all members';
      case BroadcastScopeKind.group:
        final name = ref
            .watch(clGroupsMasterProvider)
            .valueOrNull?[_scope.id]
            ?.name;
        return 'To the members of ${name ?? 'group ${_scope.id}'}';
      case BroadcastScopeKind.event:
        final title = ref
            .watch(clEventDetailProvider(_scope.id!))
            .valueOrNull
            ?.title;
        return 'To the members of ${title ?? 'event ${_scope.id}'}';
      case BroadcastScopeKind.member:
        final user = ref
            .watch(clUsersMasterProvider)
            .valueOrNull?[_scope.username];
        final name = user?.displayName.trim() ?? '';
        return 'To ${name.isNotEmpty ? name : _scope.username}';
    }
  }

  /// Who the next send reaches, after Staff only and Choose members.
  String _recipientsLabel(AsyncValue<List<String>>? staff) {
    if (_chosen.isNotEmpty) {
      return 'Sends to the ${_chosen.length} chosen '
          'member${_chosen.length == 1 ? '' : 's'}.';
    }
    if (_staffOnly) {
      final count = staff?.valueOrNull?.length;
      return count == null
          ? 'Sends to the staff only.'
          : 'Sends to the staff only ($count).';
    }
    return 'Sends to every member.';
  }

  /// The audience of the next send, or null when there is nobody to send to.
  Future<AudienceSelector?> _audience() async {
    if (_chosen.isNotEmpty) return AudienceSelector.users(_chosen);
    if (!_staffOnly) return _scope.audience;
    final staff = await ref.read(clBroadcastStaffProvider(_scope).future);
    if (staff.isEmpty) return null;
    return AudienceSelector.users(staff);
  }

  Future<void> _chooseMembers() async {
    final List<UserInfo> members;
    try {
      members = await ref.read(clBroadcastMembersProvider(_scope).future);
    } on Object {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not load the members.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final picked = await showUserSelectionDialog(
      context,
      title: 'Choose members',
      description: 'The message goes to the members you pick.',
      confirmLabel: 'Choose',
      emptyText: 'No members to choose from.',
      users: [
        for (final u in members)
          PickerUser(
            username: u.username,
            displayName: u.displayName.trim().isNotEmpty
                ? u.displayName
                : u.username,
            firstName: u.firstName,
            lastName: u.lastName,
            nickname: u.nickname,
            isAdmin: u.isAdmin,
            isCoach: u.roles.isCoach,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _chosen = picked;
      if (picked.isNotEmpty) _staffOnly = false;
    });
  }

  Future<void> _revoke(int id) async {
    try {
      await ref.read(clBroadcastsMasterProvider.notifier).revoke(id);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Broadcast revoked.')),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not revoke: ${e.message}'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      showWriteFailure(context, e, revokeFailedMessage);
    }
  }

  Future<bool> _send(BroadcastComposeResult result) async {
    try {
      final audience = await _audience();
      if (!mounted) return false;
      if (audience == null) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(description: Text(noStaffMessage)),
        );
        return false;
      }
      await ref
          .read(clBroadcastsMasterProvider.notifier)
          .send(
            scope: _scope,
            audience: audience,
            text: result.text,
            email: result.sendEmail,
            emailSubject: result.emailSubject ?? _defaultEmailSubject,
          );
      if (!mounted) return true;
      setState(() {
        _staffOnly = false;
        _chosen = const [];
      });
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            result.sendEmail
                ? 'Broadcast sent (with email).'
                : 'Broadcast sent.',
          ),
        ),
      );
      return true;
    } on ServerException catch (e) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not send: ${e.message}'),
        ),
      );
      return false;
    } on Object catch (e) {
      if (!mounted) return false;
      showWriteFailure(context, e, sendFailedMessage);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.isAdmin,
      'BroadcastView called for ${widget.currentUser.username}, who is not '
      'an admin. Screen gate failed.',
    );
    final theme = ShadTheme.of(context);
    // Keep the narrowing providers alive while the screen is open, so a send
    // or the picker reads them at once.
    final staff = _scope.canNarrow
        ? ref.watch(clBroadcastStaffProvider(_scope))
        : null;
    if (_scope.canNarrow) ref.watch(clBroadcastMembersProvider(_scope));
    final sent = ref.watch(clBroadcastsForScopeProvider(_scope));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: 'Broadcast',
          subtitle: _audienceLabel(),
          onBack: widget.onClose,
        ),
        const Divider(height: 1),
        Expanded(
          child: BroadcastLayout(
            composerPadding: LayoutConstants.contentPadding.copyWith(bottom: 0),
            sentListPadding: LayoutConstants.contentPadding.copyWith(top: 0),
            composer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_scope.canNarrow) ...[
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ShadSwitch(
                        key: const ValueKey('broadcast-staff-only'),
                        value: _staffOnly,
                        label: const Text('Staff only'),
                        onChanged: (v) => setState(() {
                          _staffOnly = v;
                          if (v) _chosen = const [];
                        }),
                      ),
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.users, size: 14),
                        onPressed: _chooseMembers,
                        child: const Text('Choose members'),
                      ),
                      if (_chosen.isNotEmpty)
                        ShadButton.ghost(
                          size: ShadButtonSize.sm,
                          onPressed: () => setState(() => _chosen = const []),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recipientsLabel(staff),
                    style: theme.textTheme.muted,
                  ),
                  LayoutConstants.itemGap,
                ],
                BroadcastComposer(
                  placeholder: _scope.kind == BroadcastScopeKind.all
                      ? 'Type a message to send to everyone…'
                      : 'Type a message…',
                  onSend: _send,
                ),
                const SizedBox(height: 20),
              ],
            ),
            sentList: BroadcastSentSliver(sent: sent, onRevoke: _revoke),
          ),
        ),
      ],
    );
  }
}
