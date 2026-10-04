import 'dart:async';

import 'package:cl_club_branding/cl_club_branding.dart'
    show AppFooter, ContactFab;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared scaffolding for every onboarding route.
///
/// Mounted once at the `/onboarding/**` `ShellRoute` level so the
/// scaffold (and any incidental shell state) survives navigation
/// between sibling onboarding routes — only [child] swaps.
///
/// Watches [authStateProvider] for title derivation and the logout
/// action. The null-user case (e.g. during sign-out) collapses to a
/// loading spinner because there is no user-derived title to render.
///
/// Gate evaluation and the "Not available" fail-state live in the
/// screens (`OnboardingWelcomeScreen`, `OnboardingSubmitDocumentsScreen`),
/// not here. This widget owns chrome only.
class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({
    required this.title,
    required this.child,
    this.onBack,
    this.onRefresh,
    this.onToggleTheme,
    this.isDark = false,
    super.key,
  });

  final String Function(UserPrivate user) title;

  /// Optional back-button callback. When non-null the app bar renders a
  /// back button that calls it; pass `null` on routes where back has no
  /// destination (e.g. the welcome screen is the root of the onboarding
  /// flow). The shell never pops the route itself — the host owns navigation.
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  /// The body view rendered inside the onboarding scaffold (e.g.
  /// `OnboardingWelcomeView`, `OnboardingSubmitDocumentsView`).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    void logout() {
      unawaited(ref.read(authStateProvider.notifier).logout());
    }

    final resolvedTitle = title(user);
    final actions = <Widget>[
      if (onRefresh != null)
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(LucideIcons.refreshCw, size: 24),
          tooltip: 'Refresh',
        ),
      if (onToggleTheme != null)
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(
            isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 24,
          ),
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
        ),
    ];
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar — onboarding owns its own chrome. Optional back button
            // (shown only when the router supplies onBack; this widget never
            // pops the route itself), title, refresh/theme actions, logout.
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(LucideIcons.arrowLeft, size: 24),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      resolvedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...actions,
                  IconButton(
                    onPressed: logout,
                    icon: const Icon(LucideIcons.logOut, size: 24),
                    tooltip: 'Log out',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: child),
                  if (!keyboardOpen)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 16, 8),
                        child: ContactFab(),
                      ),
                    ),
                  if (!keyboardOpen) const AppFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
