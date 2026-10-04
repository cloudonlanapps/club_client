import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Mirrors the web splash in `web/index.html` (logo + app name + spinner)
/// so the Flutter-side loading state hands off seamlessly from the HTML
/// splash and stays consistent on native platforms.
class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final fullName = ref.watch(appBrandingProvider).fullName;
    return ColoredBox(
      color: theme.colorScheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              fullName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
