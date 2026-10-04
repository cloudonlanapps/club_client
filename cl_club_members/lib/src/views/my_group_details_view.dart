import 'package:cl_club_members/src/views/group_profile_view.dart'
    show GroupHeroImage;
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart'
    show GroupEligibilitySection;
import 'package:cl_club_members/src/widgets/group_info_section.dart'
    show GroupInfoSection;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clMyEligibleGroupsProvider,
        clMyGroupsMasterProvider,
        clMyJoinRequestsMasterProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ConfirmDialog, LoadingView, ThemedMarkdown, TitleRow;

/// Member-facing read-only group details view.
///
/// Trimmed analogue of the admin `GroupProfileView`. The viewer can see the
/// group's own spec and their own join-request state for this group, and
/// nothing about other members. No roster, no count, no edit affordances.
class MyGroupDetailsView extends ConsumerWidget {
  const MyGroupDetailsView({
    required this.username,
    required this.groupId,
    this.onBack,
    super.key,
  });

  /// The member whose perspective this view represents. May be the viewer
  /// (self) or — for admin/coach drilling in from a member's MyGroups — a
  /// different user. Permission gating happens in the wrapping screen.
  final String username;
  final int groupId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final mineAsync = ref.watch(clMyGroupsMasterProvider(username));
    final eligibleAsync = ref.watch(clMyEligibleGroupsProvider(username));
    final requestsAsync = ref.watch(clMyJoinRequestsMasterProvider(username));

    if (mineAsync.isLoading ||
        eligibleAsync.isLoading ||
        requestsAsync.isLoading) {
      return const LoadingView();
    }

    final error = mineAsync.error ?? eligibleAsync.error ?? requestsAsync.error;
    if (error != null) {
      return Center(child: Text('Could not load group: $error'));
    }

    final group = _resolveGroup(
      mine: mineAsync.valueOrNull ?? const <Group>[],
      eligible: eligibleAsync.valueOrNull ?? const <Group>[],
    );
    if (group == null) {
      return Center(
        child: Text(
          'This group is no longer available.',
          style: theme.textTheme.muted,
        ),
      );
    }

    final requests = requestsAsync.valueOrNull ?? const <int, JoinRequest>{};
    final pendingRequest = requests.values
        .where(
          (r) => r.groupId == groupId && r.status == JoinRequestStatus.pending,
        )
        .firstOrNull;

    final description = group.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(title: group.name, onBack: onBack),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display-only — editing the image lives on the admin
                // GroupProfileView, so the member view never gets the pencil.
                GroupHeroImage(groupId: group.id, canEdit: false),
                const SizedBox(height: 20),
                ShadCard(
                  padding: const EdgeInsets.all(20),
                  child: hasDescription
                      ? ThemedMarkdown(
                          data: description,
                          textAlign: TextAlign.justify,
                        )
                      : Text(
                          'No description.',
                          style: theme.textTheme.muted,
                        ),
                ),
                const SizedBox(height: 20),
                GroupEligibilitySection(group: group),
                if (pendingRequest != null) ...[
                  const SizedBox(height: 20),
                  PendingJoinRequestCard(
                    username: username,
                    request: pendingRequest,
                  ),
                ],
                const SizedBox(height: 20),
                GroupInfoSection(group: group),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Group? _resolveGroup({
    required List<Group> mine,
    required List<Group> eligible,
  }) {
    final inMine = mine.where((g) => g.id == groupId).firstOrNull;
    if (inMine != null) return inMine;
    return eligible.where((g) => g.id == groupId).firstOrNull;
  }
}

/// Card shown when the viewer has a pending join request for this group.
/// Displays the requested date and offers a "Cancel request" action.
class PendingJoinRequestCard extends ConsumerStatefulWidget {
  const PendingJoinRequestCard({
    required this.username,
    required this.request,
    super.key,
  });

  final String username;
  final JoinRequest request;

  @override
  ConsumerState<PendingJoinRequestCard> createState() =>
      PendingJoinRequestCardState();
}

class PendingJoinRequestCardState
    extends ConsumerState<PendingJoinRequestCard> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final requestedAt = DateTime.fromMillisecondsSinceEpoch(
      widget.request.requestedAt * 1000,
      isUtc: true,
    );

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your request', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          Text(
            'You requested to join this group on '
            '${requestedAt.toLocalDateMedium()}. It is awaiting review.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.outline(
              onPressed: _cancelling ? null : handleCancel,
              child: Text(_cancelling ? 'Cancelling…' : 'Cancel request'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleCancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel request?',
      message: 'Withdraw your request to join "${widget.request.groupName}"?',
      confirmLabel: 'Cancel request',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref
          .read(clMyJoinRequestsMasterProvider(widget.username).notifier)
          .cancel(widget.request.id);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Request cancelled.')),
      );
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not cancel request.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }
}
