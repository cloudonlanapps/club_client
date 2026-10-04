import 'package:cl_remote_store/cl_remote_store.dart'
    show clEligibleUsersForEventProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show showShadDialog;
import 'package:ui_lib/ui_lib.dart'
    as ui_lib
    show PickerUser, showUserSelectionDialog;

import 'funded_user_selection_dialog.dart';

/// Event-specific wrapper around [ui_lib.showUserSelectionDialog].
///
/// Reads the server-filtered eligible-users list for the event
/// (`clEligibleUsersForEventProvider`) — the server already applies the
/// event's gender / DOB / enrollment filters — and lets the caller
/// drop additional usernames (typically the organizer + coaches) before
/// passing the result to the shared multi-select picker.
///
/// Cross-references each eligible user with `clUsersMasterProvider` so the
/// picker can render role labels (Coach / Admin) on the tile.
///
/// The picker's role filter is **disabled** here (`showRoleFilter: false`):
/// the server's `listEligible` is already authoritative — it applies the
/// event's gender / DOB criteria uniformly to every user (see
/// `services/event_eligibility.py` — "no staff exemption applies"). A
/// client-side role filter on top of that would only hide eligible
/// coaches / admins behind a popover.
///
/// With [creditGated], a programme's members who cannot be funded are
/// blocked, with an add-credit chip ([FundedUserSelectionDialog],
/// club_core#105). Assign is gated; Invite is not (club_server#446).
Future<List<String>?> showUserSelectionDialog(
  BuildContext context, {
  required WidgetRef ref,
  required int eventId,
  required String title,
  Set<String> excludeUsernames = const {},
  bool creditGated = false,
}) async {
  final eligible = await ref.read(
    clEligibleUsersForEventProvider(eventId).future,
  );
  final userMaster = await ref.read(clUsersMasterProvider.future);
  if (!context.mounted) return null;
  final users = <ui_lib.PickerUser>[
    for (final user in eligible)
      if (!excludeUsernames.contains(user.username))
        _toPickerUser(user, userMaster[user.username]),
  ];
  if (creditGated) {
    return showShadDialog<List<String>>(
      context: context,
      builder: (_) => FundedUserSelectionDialog(
        title: title,
        users: users,
        eventId: eventId,
      ),
    );
  }
  return ui_lib.showUserSelectionDialog(
    context,
    title: title,
    users: users,
    showRoleFilter: false,
  );
}

ui_lib.PickerUser _toPickerUser(EligibleUser eligible, UserInfo? info) {
  final roles = info?.roles;
  return ui_lib.PickerUser(
    username: eligible.username,
    displayName: displayName(eligible),
    firstName: eligible.firstName,
    lastName: eligible.lastName,
    nickname: eligible.nickname,
    isAdmin: roles?.isAdmin ?? false,
    isCoach: roles?.isCoach ?? false,
  );
}

String displayName(EligibleUser u) {
  final first = u.firstName?.trim() ?? '';
  final last = u.lastName?.trim() ?? '';
  final full = [first, last].where((s) => s.isNotEmpty).join(' ');
  if (full.isNotEmpty) return full;
  if ((u.nickname ?? '').trim().isNotEmpty) return u.nickname!.trim();
  return u.username;
}
