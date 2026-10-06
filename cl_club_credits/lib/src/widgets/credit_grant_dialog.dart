import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/credit_action_kind.dart';
import 'credit_action_form.dart';

/// ➕ Add credit for [username], alone in a dialog (club_client#41): what a
/// picker's "+" chip opens, with no credit view behind it. [programmeId]
/// and [trial] pre-fill it (club_core#105). Resolves to true once the
/// credit was added; the accounts master bumps `creditsVersion`, so the
/// picker refreshes itself.
Future<bool> showCreditGrantDialog(
  BuildContext context, {
  required String username,
  int? programmeId,
  bool trial = false,
}) async {
  final done = await showShadDialog<bool>(
    context: context,
    builder: (context) => CreditActionForm.dialog(
      kind: CreditActionKind.grant,
      username: username,
      programmeId: programmeId,
      trial: trial,
    ),
  );
  return done ?? false;
}
