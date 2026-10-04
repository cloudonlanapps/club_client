import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

class IntroCard extends StatelessWidget {
  const IntroCard({
    required this.documentsRequired,
    required this.onContinue,
    super.key,
  });

  /// Whether the next step is uploading an identity document (the server's
  /// `identityVerification`) or submitting straight for review.
  final bool documentsRequired;
  final VoidCallback onContinue;

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
                  LucideIcons.fileText,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome aboard - almost!',
                  style: theme.textTheme.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  documentsRequired
                      ? "Just upload a copy of an identity document and we'll "
                            'have you skating with us in no time.'
                      : "Submit your application and we'll have you skating "
                            'with us in no time.',
                  style: theme.textTheme.p,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ShadButton(
                  onPressed: onContinue,
                  child: Text(
                    documentsRequired ? 'Continue' : 'Submit for review',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
