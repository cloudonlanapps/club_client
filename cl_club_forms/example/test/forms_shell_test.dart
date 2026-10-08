import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms_example/constants/demo_keys.dart';
import 'package:cl_club_forms_example/constants/demo_strings.dart';
import 'package:cl_club_forms_example/data/demo_samples.dart';
import 'package:cl_club_forms_example/data/form_demo_entries.dart';
import 'package:cl_club_forms_example/models/form_demo_group.dart';
import 'package:cl_club_forms_example/widgets/forms_sidebar.dart';
import 'package:cl_club_forms_example/widgets/top_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/demo_harness.dart';

/// The messages of the login form's two required fields.
const String usernameRequired = 'Username is required';
const String passwordRequired = 'Password is required';

void main() {
  testWidgets('Issue 76: the sidebar names the app, every family and every '
      'entry', (tester) async {
    // Tall enough that the list builds every item.
    await pumpDemo(tester, const Size(1280, 3000));

    expect(find.text(DemoStrings.appName), findsOneWidget);
    for (final group in FormDemoGroup.values) {
      expect(find.text(group.title.toUpperCase()), findsOneWidget);
    }
    for (final entry in FormDemoEntries.all) {
      expect(find.byKey(DemoKeys.sidebarItem(entry.id)), findsOneWidget);
    }
  });

  testWidgets('Issue 76: tapping an entry of the sidebar shows its form', (
    tester,
  ) async {
    await pumpDemo(tester, kDesktop);
    expect(find.byType(LoginForm), findsOneWidget);

    final item = find.byKey(DemoKeys.sidebarItem('venue-create'));
    await tester.scrollUntilVisible(
      item,
      200,
      scrollable: find.descendant(
        of: find.byType(FormsSidebar),
        matching: find.byType(Scrollable),
      ),
    );
    // Wholly into view: an item that only peeks in at the edge of the
    // sidebar is found but its centre cannot be tapped.
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsNothing);
    expect(find.byType(VenueCreateForm), findsOneWidget);
  });

  testWidgets('Issue 76: on a phone the sidebar is a drawer', (tester) async {
    await pumpDemo(tester, kPhone);
    expect(find.byType(FormsSidebar), findsNothing);

    await tester.tap(find.byKey(DemoKeys.openSidebar));
    await tester.pumpAndSettle();
    expect(find.byType(FormsSidebar), findsOneWidget);

    await tester.tap(find.byKey(DemoKeys.sidebarItem('forgot-password')));
    await tester.pumpAndSettle();
    expect(find.byType(FormsSidebar), findsNothing);
    expect(find.byType(ForgotPasswordForm), findsOneWidget);
  });

  testWidgets('Issue 76: the toggle switches between light and dark', (
    tester,
  ) async {
    await pumpDemo(tester, kDesktop);
    Brightness brightness() =>
        ShadTheme.of(tester.element(find.byType(LoginForm))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(find.byKey(DemoKeys.themeToggle));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
  });

  for (final surface in kSurfaces.entries) {
    testWidgets('Issue 76: the top bar holds Validate, Reset and the theme '
        'toggle, ${surface.key}', (tester) async {
      await pumpDemo(tester, surface.value);
      final bar = find.byType(TopBarActions);

      expect(bar, findsOneWidget);
      for (final key in [
        DemoKeys.validate,
        DemoKeys.reset,
        DemoKeys.themeToggle,
      ]) {
        expect(
          find.descendant(of: bar, matching: find.byKey(key)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(DemoKeys.formCard),
            matching: find.byKey(key),
          ),
          findsNothing,
        );
      }
      // Above the card, not beside or under it.
      expect(
        tester.getBottomLeft(bar).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(DemoKeys.formCard)).dy),
      );
    });

    testWidgets('Issue 76: Validate on the untouched login form shows its '
        'required messages, ${surface.key}', (tester) async {
      await pumpDemo(tester, surface.value);
      expect(find.text(usernameRequired), findsNothing);

      await tester.tap(find.byKey(DemoKeys.validate));
      await tester.pumpAndSettle();

      expect(find.text(usernameRequired), findsOneWidget);
      expect(find.text(passwordRequired), findsOneWidget);
    });

    testWidgets('Issue 76: Reset removes the messages and clears a typed '
        'value, ${surface.key}', (tester) async {
      await pumpDemo(tester, surface.value);
      await tester.enterText(find.byType(EditableText).first, 'typed.name');
      await tester.tap(find.byKey(DemoKeys.validate));
      await tester.pumpAndSettle();
      expect(find.text('typed.name'), findsOneWidget);
      expect(find.text(passwordRequired), findsOneWidget);

      await tester.tap(find.byKey(DemoKeys.reset));
      await tester.pumpAndSettle();

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.text('typed.name'), findsNothing);
      expect(find.text(passwordRequired), findsNothing);
    });
  }

  testWidgets('Issue 76: Reset puts a form back to its sample data', (
    tester,
  ) async {
    await pumpEntry(tester, entryWithId('rename'), kDesktop);
    final sample = DemoSamples.venues.first.name;
    expect(find.text(sample), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Another name');
    await tester.pumpAndSettle();
    expect(find.text(sample), findsNothing);

    await tester.tap(find.byKey(DemoKeys.reset));
    await tester.pumpAndSettle();

    expect(find.text(sample), findsOneWidget);
    expect(find.text('Another name'), findsNothing);
  });

  testWidgets('Issue 76: choosing another entry and coming back starts the '
      'form fresh', (tester) async {
    await pumpDemo(tester, kDesktop);
    await tester.tap(find.byKey(DemoKeys.validate));
    await tester.pumpAndSettle();
    expect(find.text(usernameRequired), findsOneWidget);

    await tester.tap(find.byKey(DemoKeys.sidebarItem('forgot-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DemoKeys.sidebarItem('login')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text(usernameRequired), findsNothing);
  });

  test('Issue 76: the web page and manifest carry the app name', () {
    final page = File('web/index.html').readAsStringSync();
    expect(page, contains('<title>${DemoStrings.appName}</title>'));
    expect(
      page,
      contains(
        'name="apple-mobile-web-app-title" '
        'content="${DemoStrings.appName}"',
      ),
    );
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"name": "${DemoStrings.appName}"'));
    expect(manifest, contains('"short_name": "${DemoStrings.appName}"'));
  });
}
