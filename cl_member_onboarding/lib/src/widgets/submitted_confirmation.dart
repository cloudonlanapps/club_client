import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

class SubmittedConfirmation extends StatelessWidget {
  const SubmittedConfirmation({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = isMobileWidth(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 420,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.hourglass_top_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thanks for signing up!',
                  style: theme.textTheme.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "We're reviewing your application now - you'll hear "
                  'from us shortly.',
                  style: theme.textTheme.p,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ShadButton(
                  onPressed: onBack,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
