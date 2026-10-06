import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clMemberCreditTotalProvider, creditSystemProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show CreditCountChip;

import '../models/credit_grant_prefill.dart';
import 'credit_grant_dialog.dart';
import 'credit_sheet.dart';

/// A member's credit, 🪙 N, used wherever credit matters (club_core#102);
/// tapping it opens that member's credit view in a sheet.
///
/// Renders nothing unless [creditSystemProvider] is `true` — no guess while
/// the capabilities are unknown, and no credit call where the module is
/// off. Beside an action greyed out for lack of credit it is the reason,
/// and for an admin the way to fix it.
class CreditChip extends ConsumerWidget {
  const CreditChip({
    required this.username,
    this.credits,
    super.key,
  }) : grantPrefill = null;

  /// The "add credit" form of the chip, for a member who cannot be funded
  /// in a picker (club_core#105): it opens Add credit alone in a dialog,
  /// pre-filled with [grantPrefill], with no credit view behind it
  /// (club_client#41). Once saved, the picker refreshes through
  /// `creditsVersion`.
  const CreditChip.add({
    required this.username,
    required CreditGrantPrefill this.grantPrefill,
    super.key,
  }) : credits = null;

  final String username;

  /// A number to show in place of the member's usable total, e.g. the
  /// credit usable on one programme.
  final int? credits;

  /// What Add credit opens with; non-null makes this the "add" chip.
  final CreditGrantPrefill? grantPrefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(creditSystemProvider) != true) return const SizedBox.shrink();
    final prefill = grantPrefill;
    final shown = prefill != null
        ? null
        : credits ?? ref.watch(clMemberCreditTotalProvider(username));
    return CreditCountChip(
      credits: shown,
      add: prefill != null,
      onTap: () => unawaited(
        prefill == null
            ? showCreditSheet(context, username: username)
            : showCreditGrantDialog(
                context,
                username: username,
                programmeId: prefill.programmeId,
                trial: prefill.trial,
              ),
      ),
    );
  }
}
