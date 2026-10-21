import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reveals the temporary [password] a user is created with when the admin
/// ticks **Use default password**: a random one per user (#221).
///
/// Mirrors the layout of `AdminResetPasswordResultDialog` (Copy + OK
/// actions, selectable bold/letter-spaced password text) so the two
/// flows feel consistent.
class DefaultPasswordDialog extends StatelessWidget {
  const DefaultPasswordDialog({required this.password, super.key});

  /// The password the user is created with.
  final String password;

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
              password,
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
            await Clipboard.setData(ClipboardData(text: password));
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
