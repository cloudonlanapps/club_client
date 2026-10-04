import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown when a user logs in but their account status is `blocked`.
class AccountBlockedView extends StatelessWidget {
  const AccountBlockedView({required this.onBack, super.key});

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
                Icons.block,
                size: 48,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(height: 12),
              Text('Account blocked', style: theme.textTheme.h4),
              const SizedBox(height: 8),
              Text(
                'Your account has been blocked. Please contact an '
                'administrator if you believe this is in error.',
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
