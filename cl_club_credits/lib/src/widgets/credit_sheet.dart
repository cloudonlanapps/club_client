import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../views/credit_view.dart';

/// The widest the credit sheet grows on a large screen.
const double creditSheetMaxWidth = 520;

/// Opens [username]'s credit view in a full-height sheet (club_core#102):
/// where a `CreditChip` showing a number leads. A modal the chip itself
/// opens, so no route is involved, it works over a dialog, and closing it
/// returns to the same screen, already refreshed through `creditsVersion`.
/// The view's actions open inside it, so it is the top of the stack
/// (club_client#41).
Future<void> showCreditSheet(BuildContext context, {required String username}) {
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.right,
    builder: (context) => CreditSheet(username: username),
  );
}

/// The sheet [showCreditSheet] opens: the viewer from auth, and the view.
class CreditSheet extends ConsumerWidget {
  const CreditSheet({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final size = MediaQuery.sizeOf(context);
    return ShadSheet(
      scrollable: false,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        maxWidth: size.width < creditSheetMaxWidth
            ? size.width
            : creditSheetMaxWidth,
      ),
      child: SizedBox(
        height: size.height,
        child: viewer == null
            ? const Center(child: CircularProgressIndicator())
            : CreditView(currentUser: viewer, username: username),
      ),
    );
  }
}
