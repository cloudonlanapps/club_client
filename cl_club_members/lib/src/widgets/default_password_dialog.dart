import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show defaultUserPassword;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reveals the project-wide default password used when an admin creates
/// a user with **Use default password** ticked.
///
/// Mirrors the layout of `AdminResetPasswordResultDialog` (Copy + OK
/// actions, selectable bold/letter-spaced password text) so the two
/// flows feel consistent.
class DefaultPasswordDialog extends StatelessWidget {
  const DefaultPasswordDialog({super.key});

  static const String _password = defaultUserPassword;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AlertDialog(
      title: const Text('Default password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The new user will sign in with:',
              style: theme.textTheme.small,
            ),
            const SizedBox(height: 8),
            SelectableText(
              _password,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: _password));
            if (!context.mounted) return;
            ShadToaster.of(context).show(
              const ShadToast(description: Text('Copied to clipboard.')),
            );
          },
          icon: const Icon(LucideIcons.copy, size: 16),
          label: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
