import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Result of the assign trial dialog.
class AssignTrialResult {
  const AssignTrialResult({required this.username});

  final String username;
}

/// Shows a dialog for selecting a user for trial assignment.
///
/// Trial assignment is restricted to programme events server-side
/// (rejected with `INVALID_EVENT_TYPE` for camp/one-off). The dialog
/// asserts that [eventType] is [EventType.programme] so a UI race that
/// reaches the dialog for a wrong-typed event is caught in debug builds.
///
/// On a programme with credit on, a member without usable trial credit is
/// not selectable and shows a zero credit chip (it opens their credit view)
/// beside an add-credit chip that opens Add credit alone,
/// over this dialog, with trial credit for this programme pre-filled
/// (club_core#105, club_client#41); once funded, the member becomes
/// selectable in place and shows that trial credit, on a chip that opens
/// their credit view.
Future<AssignTrialResult?> showAssignTrialDialog(
  BuildContext context, {
  required int eventId,
  required EventType eventType,
  required Map<String, EnrollmentStatus> currentEnrollments,
  Set<String> excludeUsernames = const {},
}) async {
  assert(
    eventType == EventType.programme,
    'Assign Trial is only valid for programme events; got $eventType.',
  );
  return showShadDialog<AssignTrialResult>(
    context: context,
    builder: (context) => AssignTrialDialogContent(
      eventId: eventId,
      currentEnrollments: currentEnrollments,
      excludeUsernames: excludeUsernames,
    ),
  );
}

class AssignTrialDialogContent extends ConsumerStatefulWidget {
  const AssignTrialDialogContent({
    required this.eventId,
    required this.currentEnrollments,
    this.excludeUsernames = const {},
    super.key,
  });

  final int eventId;
  final Map<String, EnrollmentStatus> currentEnrollments;
  final Set<String> excludeUsernames;

  @override
  ConsumerState<AssignTrialDialogContent> createState() =>
      AssignTrialDialogContentState();
}

class AssignTrialDialogContentState
    extends ConsumerState<AssignTrialDialogContent> {
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final userListAsync = ref.watch(clUsersMasterProvider);
    final trialCredits = usableTrialCredits();

    return ShadDialog(
      title: const Text('Assign Trial'),
      description: const Text('Select a user for trial assignment.'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ShadInput(
            placeholder: const Text('Search by name...'),
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (value) =>
                setState(() => searchTerm = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          userListAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Could not load users: $e', style: theme.textTheme.muted),
            data: (userMap) {
              final available = userMap.values
                  .where(
                    (u) =>
                        u.status == UserStatus.active &&
                        MembershipShim.isMember(u.roles) &&
                        !_isActivelyEnrolled(u.username) &&
                        !widget.excludeUsernames.contains(u.username),
                  )
                  .where((u) => matchesSearch(u, searchTerm))
                  .toList();

              if (available.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No available users.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final user in available)
                        if ((trialCredits[user.username] ?? 1) < 1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Flexible(
                                child: Opacity(
                                  opacity: 0.5,
                                  child: buildUserTile(context, user, null),
                                ),
                              ),
                              CreditChip(
                                username: user.username,
                                credits: trialCredits[user.username],
                              ),
                              CreditChip.add(
                                username: user.username,
                                grantPrefill: (
                                  programmeId: widget.eventId,
                                  trial: true,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Flexible(
                                child: buildUserTile(
                                  context,
                                  user,
                                  () => Navigator.of(context).pop(
                                    AssignTrialResult(username: user.username),
                                  ),
                                ),
                              ),
                              if (trialCredits[user.username] != null)
                                CreditChip(
                                  username: user.username,
                                  credits: trialCredits[user.username],
                                ),
                            ],
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Each member's usable trial credit for this programme, when credit is
  /// on; empty otherwise, so nothing is blocked (club_core#105, R53). A
  /// member with none cannot be given a trial.
  Map<String, int> usableTrialCredits() {
    if (ref.watch(creditSystemProvider) != true) return const {};
    final accounts = ref.watch(clUsableCreditAccountsProvider).valueOrNull;
    if (accounts == null) return const {};
    final users = ref.watch(clUsersMasterProvider).valueOrNull ?? const {};
    return {
      for (final username in users.keys)
        username: usableCreditsFor(
          accounts[username] ?? const <CreditAccount>[],
          eventId: widget.eventId,
          trial: true,
        ),
    };
  }

  Widget buildUserTile(
    BuildContext context,
    UserInfo user,
    VoidCallback? onTap,
  ) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.muted,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.username,
                      style: theme.textTheme.muted.copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Set<EnrollmentStatus> _inactiveStatuses = {
    EnrollmentStatus.withdrawn,
    EnrollmentStatus.removed,
    EnrollmentStatus.rejected,
    EnrollmentStatus.declined,
  };

  bool _isActivelyEnrolled(String username) {
    final status = widget.currentEnrollments[username];
    if (status == null) return false;
    return !_inactiveStatuses.contains(status);
  }

  bool matchesSearch(UserInfo user, String term) {
    if (term.isEmpty) return true;
    return user.displayName.toLowerCase().contains(term) ||
        (user.firstName?.toLowerCase().contains(term) ?? false) ||
        (user.lastName?.toLowerCase().contains(term) ?? false) ||
        user.username.toLowerCase().contains(term);
  }
}
