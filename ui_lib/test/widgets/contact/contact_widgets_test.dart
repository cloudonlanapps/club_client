import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EmailContact, PhoneContact;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../support/recording_url_launcher.dart';

Future<RecordingUrlLauncher> _pump(WidgetTester tester, Widget child) async {
  final original = UrlLauncherPlatform.instance;
  final launcher = RecordingUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  await tester.pumpWidget(ShadApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
  return launcher;
}

void main() {
  group('Issue 32: a phone number with its actions', () {
    testWidgets('Issue 32: shows the number with Call and WhatsApp, each '
        'opening its link', (tester) async {
      final launcher = await _pump(
        tester,
        const PhoneContact(number: '+91 98765 43210', defaultCountryCode: '91'),
      );

      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.byIcon(LucideIcons.phone), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launcher.launched, [
        'tel:+919876543210',
        'https://wa.me/919876543210',
      ]);
    });

    testWidgets('Issue 32: WhatsApp puts the default country code in front '
        'of a stored bare number', (tester) async {
      final launcher = await _pump(
        tester,
        const PhoneContact(number: '9876543210', defaultCountryCode: '91'),
      );

      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://wa.me/919876543210']);
    });

    testWidgets('Issue 32: Call only leaves WhatsApp out', (tester) async {
      final launcher = await _pump(
        tester,
        const PhoneContact.callOnly(number: '9876543210'),
      );

      expect(find.text('WhatsApp'), findsNothing);
      expect(find.byIcon(LucideIcons.messageCircle), findsNothing);

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['tel:9876543210']);
    });

    testWidgets('Issue 32: the buttons are outline buttons', (tester) async {
      await _pump(
        tester,
        const PhoneContact(number: '9876543210', defaultCountryCode: '91'),
      );

      final buttons = tester.widgetList<ShadButton>(find.byType(ShadButton));
      expect(buttons, hasLength(2));
      expect(
        buttons.map((b) => b.variant),
        everyElement(ShadButtonVariant.outline),
      );
    });
  });

  group('Issue 32: an email address with its action', () {
    testWidgets('Issue 32: the button carries the given label and opens the '
        'address with the subject', (tester) async {
      final launcher = await _pump(
        tester,
        const EmailContact(
          address: 'robin@example.test',
          actionLabel: 'Reply with Email',
          subject: 'Re: ice time',
        ),
      );

      expect(find.text('robin@example.test'), findsOneWidget);
      expect(find.byIcon(LucideIcons.mail), findsOneWidget);

      await tester.tap(find.text('Reply with Email'));
      await tester.pumpAndSettle();

      expect(launcher.launched, [
        'mailto:robin@example.test?subject=Re%3A%20ice%20time',
      ]);
    });

    testWidgets('Issue 32: without a subject the link is the address alone', (
      tester,
    ) async {
      final launcher = await _pump(
        tester,
        const EmailContact(address: 'robin@example.test', actionLabel: 'Email'),
      );

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['mailto:robin@example.test']);
    });
  });
}
