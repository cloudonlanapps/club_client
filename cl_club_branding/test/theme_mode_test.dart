import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Issue 53: the remembered theme mode', () {
    test('Issue 53: follows the system until the host says otherwise', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('Issue 53: starts from the mode the host loaded at startup', () {
      final container = ProviderContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('Issue 53: a chosen mode is stored for the next start', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(await ThemeModeStorage.load(), ThemeMode.dark);
    });

    test('Issue 53: toggling flips from what is on screen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeModeProvider.notifier);

      await notifier.toggle(isDark: true);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(await ThemeModeStorage.load(), ThemeMode.light);

      await notifier.toggle(isDark: false);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(await ThemeModeStorage.load(), ThemeMode.dark);
    });

    test('Issue 53: nothing stored loads as system', () async {
      expect(await ThemeModeStorage.load(), ThemeMode.system);
    });

    test('Issue 53: an unrecognised stored value loads as system', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeStorage.key: 'sepia',
      });

      expect(await ThemeModeStorage.load(), ThemeMode.system);
    });
  });

  group('Issue 53: isDarkTheme', () {
    test('Issue 53: an explicit mode ignores the platform', () {
      expect(isDarkTheme(ThemeMode.dark, Brightness.light), isTrue);
      expect(isDarkTheme(ThemeMode.light, Brightness.dark), isFalse);
    });

    test('Issue 53: system follows the platform brightness', () {
      expect(isDarkTheme(ThemeMode.system, Brightness.dark), isTrue);
      expect(isDarkTheme(ThemeMode.system, Brightness.light), isFalse);
    });
  });

  group('Issue 53: the WidgetRef helpers', () {
    testWidgets('Issue 53: watchIsDark reads the platform under system', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool isDark;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              isDark = ref.watchIsDark(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(isDark, isTrue);
    });

    testWidgets('Issue 53: toggleThemeMode rebuilds the watchers', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool isDark;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              isDark = ref.watchIsDark(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(isDark, isFalse);

      widgetRef.toggleThemeMode(isDark: isDark);
      await tester.pumpAndSettle();

      expect(isDark, isTrue);
    });
  });
}
