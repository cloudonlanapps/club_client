import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/login_error_messages.dart';

/// Shown when a member who has left the club (status `left`) signs in.
class AccountLeftView extends StatelessWidget {
  const AccountLeftView({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ShadCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 48,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text('Account inactive', style: theme.textTheme.h4),
              const SizedBox(height: 8),
              Text(
                LoginErrorMessages.accountLeft,
                style: theme.textTheme.p,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ShadButton(
                onPressed: onBack,
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
