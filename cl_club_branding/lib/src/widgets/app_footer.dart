import 'dart:async';

import 'package:cl_club_branding/src/providers/app_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const String buildTimestamp = String.fromEnvironment('BUILD_TIMESTAMP');

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  void _showBuildInfo(BuildContext context) {
    final value = buildTimestamp.isEmpty
        ? '(no build timestamp embedded)'
        : buildTimestamp;
    final theme = ShadTheme.of(context);
    final toaster = ShadToaster.of(context);
    toaster.show(
      ShadToast(
        // Long duration acts as "stays open until dismissed". The action
        // button is the close affordance — tapping Copy also calls hide()
        // so the toast goes away after the value lands on the clipboard.
        duration: const Duration(days: 1),
        title: const Text('Build info'),
        description: Text(
          value,
          style: theme.textTheme.small,
        ),
        action: ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) unawaited(toaster.hide());
          },
          child: const Text('Copy'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final shortName = ref.watch(appBrandingProvider).shortName;

    return GestureDetector(
      onLongPress: () => _showBuildInfo(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(color: theme.colorScheme.border),
          ),
        ),
        child: Center(
          child: Text(
            '© ${DateTime.now().year} $shortName • '
            'All rights reserved.',
            style: theme.textTheme.muted.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
