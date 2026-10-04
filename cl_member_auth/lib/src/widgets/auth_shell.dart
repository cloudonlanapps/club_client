import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared Scaffold + brand-hero chrome for auth routes.
///
/// Mounted once at the `/auth/**` `ShellRoute` level so the hero,
/// footer, and any incidental shell state survive navigation between
/// sibling auth routes — only [child] swaps.
///
/// Brand inputs are read from providers:
/// - [appLogoUriProvider] for the logo image
/// - [appBrandingProvider] for the short brand-mark text
/// - `contactInfoProvider`, through [ContactFab], for the contact button
///
/// The host overrides those providers in its `ProviderScope`.
class AuthShell extends ConsumerWidget {
  const AuthShell({required this.child, super.key});

  /// The body view rendered below the hero (login, signup,
  /// forgot-password, etc.).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = width < 700 ? 180.0 : 240.0;
    final branding = ref.watch(appBrandingProvider);
    final hero = switch (branding.heroSurface) {
      ClubHeroSurface.primary => cs.primary,
      ClubHeroSurface.secondary => cs.secondary,
    };
    // Read the foreground off the hero itself rather than off a fixed slot, so
    // both surfaces stay legible without the caller having to pair them.
    final heroIsDark =
        ThemeData.estimateBrightnessForColor(hero) == Brightness.dark;
    final fg = heroIsDark ? cs.primaryForeground : cs.secondaryForeground;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final brandName = branding.shortName;

    // Tint the system status bar to match the hero so the brand surface
    // reads as continuous on Android.
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: hero,
      statusBarIconBrightness: heroIsDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: heroIsDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: cs.background,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            hero,
                            Color.alphaBlend(
                              // A saturated hero carries a deeper gradient; the
                              // same ratio on a light tint reads as dirty.
                              Colors.black.withValues(
                                alpha: heroIsDark ? 0.25 : 0.06,
                              ),
                              hero,
                            ),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: SizedBox(
                          height: heroHeight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 8, 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: brandName.isEmpty
                                        ? const SizedBox.shrink()
                                        : Text(
                                            brandName,
                                            style: theme.textTheme.h2.copyWith(
                                              color: fg,
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w600,
                                              fontFamily:
                                                  'packages/shadcn_ui/GeistMono',
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const AspectRatio(
                                  aspectRatio: 1,
                                  child: FittedBox(child: AppLogo()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
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
    );
  }
}
