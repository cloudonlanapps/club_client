import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_strings.dart';

/// Asks a member whether their profile is complete before they download
/// their own form, which prints from it (club_client#340). Resolves to true
/// for **Yes**, false for **No**, and null when the dialog is dismissed
/// without an answer.
Future<bool?> showProfileCompleteDialog(BuildContext context) =>
    showShadDialog<bool>(
      context: context,
      builder: (_) => const ProfileCompleteDialog(),
    );

/// "Is your profile complete?", with **No** and **Yes**. Each answer closes
/// the dialog with its value; the caller acts on it.
class ProfileCompleteDialog extends StatelessWidget {
  const ProfileCompleteDialog({super.key});

  /// Key of the **Yes** button.
  static const Key yesKey = ValueKey('application.profileComplete.yes');

  /// Key of the **No** button.
  static const Key noKey = ValueKey('application.profileComplete.no');

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text(ApplicationViewStrings.profileCompleteTitle),
      description: const Text(ApplicationViewStrings.profileCompleteMessage),
      actions: [
        ShadButton.outline(
          key: noKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(ApplicationViewStrings.profileCompleteNo),
        ),
        ShadButton(
          key: yesKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(ApplicationViewStrings.profileCompleteYes),
        ),
      ],
    );
  }
}
