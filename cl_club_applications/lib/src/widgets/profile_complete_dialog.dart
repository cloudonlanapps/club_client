import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';

/// Asks a member whether their profile is complete before they download
/// their own form, which prints from it, listing the printed fields that
/// are [blank] on it; null when the profile could not be read
/// (club_client#340). Resolves to true for **Yes**, false for **No**, and
/// null when the dialog is dismissed without an answer.
Future<bool?> showProfileCompleteDialog(
  BuildContext context, {
  required List<String>? blank,
}) => showShadDialog<bool>(
  context: context,
  builder: (_) => ProfileCompleteDialog(blank: blank),
);

/// "Is your profile complete?", with the blank fields and **No** and
/// **Yes**. Each answer closes the dialog with its value; the caller acts on
/// it.
class ProfileCompleteDialog extends StatelessWidget {
  const ProfileCompleteDialog({required this.blank, super.key});

  /// Key of the **Yes** button.
  static const Key yesKey = ValueKey('application.profileComplete.yes');

  /// Key of the **No** button.
  static const Key noKey = ValueKey('application.profileComplete.no');

  /// The labels of the printed fields blank on the profile; null when the
  /// profile could not be read.
  final List<String>? blank;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fields = blank ?? const <String>[];
    return ShadDialog(
      title: const Text(ApplicationViewStrings.profileCompleteTitle),
      description: Text(
        fields.isEmpty
            ? ApplicationViewStrings.profileCompleteUnknown
            : ApplicationViewStrings.profileCompleteMessage,
      ),
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
      child: fields.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ApplicationViewSizes.smallGap,
              children: [
                for (final field in fields)
                  Text('• $field', style: theme.textTheme.p),
                Text(
                  ApplicationViewStrings.profileCompleteNote,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
    );
  }
}
