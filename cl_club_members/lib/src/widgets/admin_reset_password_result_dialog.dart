import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Dialog showing a server-generated password with Copy and OK buttons.
class AdminResetPasswordResultDialog extends StatelessWidget {
  const AdminResetPasswordResultDialog({
    required this.password,
    super.key,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AlertDialog(
      title: const Text('Password Reset'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New temporary password:',
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
