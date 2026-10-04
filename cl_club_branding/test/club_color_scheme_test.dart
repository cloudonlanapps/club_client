import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const Map<String, Color> custom = {'filmOverlay': Colors.black};
const red = Color(0xFFFF0000);
const green = Color(0xFF00FF00);

void main() {
  group('Issue 53: buildClubColorScheme', () {
    test('Issue 53: a named source is that shadcn scheme plus the custom '
        'colours', () {
      for (final brightness in Brightness.values) {
        final scheme = buildClubColorScheme(
          brightness: brightness,
          source: const ClubColorSource(schemeName: 'green'),
          customColors: custom,
        );
        final base = ShadColorScheme.fromName('green', brightness: brightness);

        expect(scheme.primary, base.primary);
        expect(scheme.background, base.background);
        expect(scheme.custom, custom);
      }
    });

    test('Issue 53: tokens replace only what they name, per brightness', () {
      const source = ClubColorSource(
        schemeName: 'blue',
        light: ClubColorTokens(background: red),
        dark: ClubColorTokens(border: green),
      );
      final light = buildClubColorScheme(
        brightness: Brightness.light,
        source: source,
        customColors: custom,
      );
      final dark = buildClubColorScheme(
        brightness: Brightness.dark,
        source: source,
        customColors: custom,
      );
      final lightBase = ShadColorScheme.fromName('blue');
      final darkBase = ShadColorScheme.fromName(
        'blue',
        brightness: Brightness.dark,
      );

      expect(light.background, red);
      expect(light.border, lightBase.border);
      expect(dark.border, green);
      expect(dark.background, darkBase.background);
    });

    test('Issue 53: primary applies to both brightnesses', () {
      const source = ClubColorSource(schemeName: 'blue', primary: red);

      for (final brightness in Brightness.values) {
        final scheme = buildClubColorScheme(
          brightness: brightness,
          source: source,
          customColors: custom,
        );
        expect(scheme.primary, red);
      }
    });
  });

  group('Issue 53: neutralGhostButton', () {
    test('Issue 53: ghost buttons take the neutral foreground', () {
      final scheme = ShadColorScheme.fromName('blue');
      final theme = neutralGhostButton(scheme);

      expect(theme.foregroundColor, scheme.foreground);
      expect(theme.hoverForegroundColor, scheme.accentForeground);
    });
  });

  group('Issue 53: ClubColorTokens', () {
    test('Issue 53: parses #RRGGBB and AARRGGBB, skipping malformed', () {
      final tokens = ClubColorTokens.fromMap(const {
        'background': '#FF0000',
        'foreground': '8000FF00',
        'card': 'not-a-colour',
        'border': '',
      });

      expect(tokens.background, red);
      expect(tokens.foreground, const Color(0x8000FF00));
      expect(tokens.card, isNull);
      expect(tokens.border, isNull);
      expect(tokens.input, isNull);
    });

    test('Issue 53: round-trips through toMap, with value equality', () {
      const tokens = ClubColorTokens(background: red, muted: green);

      expect(ClubColorTokens.fromMap(tokens.toMap()), tokens);
      expect(ClubColorTokens.fromJson(tokens.toJson()), tokens);
      expect(
        ClubColorTokens.fromMap(tokens.toMap()).hashCode,
        tokens.hashCode,
      );
    });

    test('Issue 53: copyWith can clear a token', () {
      const tokens = ClubColorTokens(background: red);

      expect(tokens.copyWith(background: () => null).background, isNull);
      expect(tokens.copyWith(card: () => green).background, red);
    });
  });

  group('Issue 53: ClubColorSource', () {
    test('Issue 53: picks the tokens for a brightness', () {
      const source = ClubColorSource(
        schemeName: 'blue',
        light: ClubColorTokens(background: red),
        dark: ClubColorTokens(background: green),
      );

      expect(source.tokensFor(Brightness.light).background, red);
      expect(source.tokensFor(Brightness.dark).background, green);
    });

    test('Issue 53: value equality and copyWith', () {
      const source = ClubColorSource(schemeName: 'blue', primary: red);

      expect(source, const ClubColorSource(schemeName: 'blue', primary: red));
      expect(source.copyWith(primary: () => null).primary, isNull);
      expect(source.copyWith(schemeName: 'green').schemeName, 'green');
      expect(ClubColorSource.fromMap(source.toMap()), source);
    });
  });
}
