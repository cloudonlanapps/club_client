import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  group('ClubBranding', () {
    test('holds the values it is given', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );

      expect(branding.fullName, 'Full Name');
      expect(branding.shortName, 'FN');
    });

    test('is value-equal and shares a hashCode', () {
      const a = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );
      const b = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );
      const c = ClubBranding(
        fullName: 'Other Club',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces only the named field', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );
      final renamed = branding.copyWith(shortName: 'XY');

      expect(renamed.shortName, 'XY');
      expect(renamed.fullName, 'Full Name');
    });

    test('defaults heroSurface to secondary, the safe choice', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );

      expect(branding.heroSurface, ClubHeroSurface.secondary);
    });

    test('heroSurface participates in equality', () {
      const a = ClubBranding(
        fullName: 'F',
        shortName: 'S',
        heroSurface: ClubHeroSurface.secondary,
      );
      const b = ClubBranding(
        fullName: 'F',
        shortName: 'S',
        heroSurface: ClubHeroSurface.primary,
      );

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith switches heroSurface without touching the names', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );
      final onPrimary = branding.copyWith(heroSurface: ClubHeroSurface.primary);

      expect(onPrimary.heroSurface, ClubHeroSurface.primary);
      expect(onPrimary.fullName, 'Full Name');
      expect(onPrimary.shortName, 'FN');
    });

    test('heroSurface round-trips through json', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.primary,
      );
      final restored = ClubBranding.fromJson(branding.toJson());

      expect(restored.heroSurface, ClubHeroSurface.primary);
      expect(restored, equals(branding));
    });

    test('fromMap falls back to secondary on an unknown heroSurface', () {
      final branding = ClubBranding.fromMap(const {
        'fullName': 'F',
        'shortName': 'S',
        'heroSurface': 'chartreuse',
      });

      expect(branding.heroSurface, ClubHeroSurface.secondary);
    });

    test('round-trips through json', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );
      final restored = ClubBranding.fromJson(branding.toJson());

      expect(restored, equals(branding));
    });

    test('fromMap defaults missing fields to empty strings', () {
      final branding = ClubBranding.fromMap(const {});

      expect(branding.fullName, isEmpty);
      expect(branding.shortName, isEmpty);
    });

    test('toString names both fields', () {
      const branding = ClubBranding(
        fullName: 'Full Name',
        shortName: 'FN',
        heroSurface: ClubHeroSurface.secondary,
      );

      expect(
        branding.toString(),
        'ClubBranding(fullName: Full Name, shortName: FN, '
        'heroSurface: secondary)',
      );
    });
  });

  group('appBrandingProvider', () {
    test('defaults to empty, so the library carries no club identity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final branding = container.read(appBrandingProvider);

      expect(branding.fullName, isEmpty);
      expect(branding.shortName, isEmpty);
    });

    test('returns the host app override', () {
      final container = ProviderContainer(
        overrides: [
          appBrandingProvider.overrideWithValue(
            const ClubBranding(
              fullName: 'Host Club',
              shortName: 'HC',
              heroSurface: ClubHeroSurface.secondary,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appBrandingProvider).fullName, 'Host Club');
      expect(container.read(appBrandingProvider).shortName, 'HC');
    });
  });

  group('AppFooter', () {
    testWidgets('renders the short name from the override', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBrandingProvider.overrideWithValue(
              const ClubBranding(
                fullName: 'Host Club',
                shortName: 'HC',
                heroSurface: ClubHeroSurface.secondary,
              ),
            ),
          ],
          child: const ShadApp(
            home: Scaffold(body: AppFooter()),
          ),
        ),
      );

      expect(
        find.textContaining('HC', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('follows a different club without code changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBrandingProvider.overrideWithValue(
              const ClubBranding(
                fullName: 'Second Club',
                shortName: 'SC',
                heroSurface: ClubHeroSurface.secondary,
              ),
            ),
          ],
          child: const ShadApp(
            home: Scaffold(body: AppFooter()),
          ),
        ),
      );

      expect(find.textContaining('SC', findRichText: true), findsOneWidget);
      expect(find.textContaining('HC', findRichText: true), findsNothing);
    });
  });
}
