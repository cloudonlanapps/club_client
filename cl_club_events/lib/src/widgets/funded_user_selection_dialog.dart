import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventsMasterProvider,
        clUsableCreditAccountsProvider,
        creditSystemProvider,
        usableCreditsFor;
import 'package:club_sdk_2/club_sdk_2.dart' show CreditAccount, EventType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser, UserSelectionDialogContent;

/// The Assign picker on a programme with credit on (club_core#105): a
/// member who cannot be funded — no usable general or programme credit
/// for an ordinary enrollment, or no trial credit for a trial (R35, R53) —
/// is dimmed and not selectable, with an add-credit chip beside them. The
/// chip opens their credit view with Add credit already open for this
/// programme; once funded, the member turns selectable in place.
///
/// Elsewhere (credit off or unknown, not a programme) it is the plain
/// picker.
class FundedUserSelectionDialog extends ConsumerWidget {
  const FundedUserSelectionDialog({
    required this.title,
    required this.users,
    required this.eventId,
    this.trial = false,
    this.singleSelect = false,
    super.key,
  });

  final String title;
  final List<PickerUser> users;
  final int eventId;

  /// Whether the enrollment made is a trial, funded by trial credit only.
  final bool trial;
  final bool singleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(
      clEventsMasterProvider.select((s) => s.valueOrNull?[eventId]?.type),
    );
    final gated =
        type == EventType.programme && ref.watch(creditSystemProvider) == true;
    final accounts = gated
        ? ref.watch(clUsableCreditAccountsProvider).valueOrNull
        : null;
    final blocked = accounts == null
        ? const <String>{}
        : {
            for (final u in users)
              if (usableCreditsFor(
                    accounts[u.username] ?? const <CreditAccount>[],
                    eventId: eventId,
                    trial: trial,
                  ) <
                  1)
                u.username,
          };
    return UserSelectionDialogContent(
      title: title,
      users: users,
      showRoleFilter: false,
      singleSelect: singleSelect,
      blockedUsernames: blocked,
      trailingBuilder: (username) => blocked.contains(username)
          ? CreditChip.add(
              username: username,
              grantPrefill: (programmeId: eventId, trial: trial),
            )
          : null,
    );
  }
}
