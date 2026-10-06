import 'package:cl_club_admin/src/widgets/inquiry_detail.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'support/admin_test_scope.dart';
import 'support/recording_url_launcher.dart';

Future<RecordingUrlLauncher> _pump(WidgetTester tester, Inquiry shown) async {
  final original = UrlLauncherPlatform.instance;
  final launcher = RecordingUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    adminScope(
      inquiries: StubInquiries(inboxOf([shown])),
      overrides: [defaultCountryCodeProvider.overrideWithValue('91')],
      child: InquiryDetail(inquiry: shown),
    ),
  );
  await tester.pumpAndSettle();
  return launcher;
}

void main() {
  group('Issue 32: the inquiry sheet reaches the sender', () {
    testWidgets('Issue 32: Call opens tel: with the number and WhatsApp '
        'opens wa.me with its international digits', (tester) async {
      final launcher = await _pump(
        tester,
        inquiry(1, phone: '+91 98765 43210'),
      );

      expect(find.text('+91 98765 43210'), findsOneWidget);

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
        'of a bare number', (tester) async {
      final launcher = await _pump(tester, inquiry(2, phone: '9876543210'));

      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://wa.me/919876543210']);
    });

    testWidgets('Issue 32: Reply with Email opens mailto: to the sender '
        'with Re: and the subject the form sent', (tester) async {
      final launcher = await _pump(
        tester,
        inquiry(3, extra: const {'subject': 'ice time'}),
      );

      expect(find.text('sender3@example.com'), findsOneWidget);

      await tester.tap(find.text('Reply with Email'));
      await tester.pumpAndSettle();

      expect(launcher.launched, [
        'mailto:sender3@example.com?subject=Re%3A%20ice%20time',
      ]);
    });

    testWidgets('Issue 32: Reply with Email has no subject when the inquiry '
        'has none', (tester) async {
      final launcher = await _pump(
        tester,
        inquiry(4, extra: const {'programme': 'Juniors'}),
      );

      await tester.tap(find.text('Reply with Email'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['mailto:sender4@example.com']);
    });

    testWidgets('Issue 32: an inquiry without a phone shows no phone row '
        'and no phone buttons', (tester) async {
      await _pump(tester, inquiry(5));

      expect(find.text('Phone'), findsNothing);
      expect(find.text('Call'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.byIcon(LucideIcons.phone), findsNothing);
      expect(find.byIcon(LucideIcons.messageCircle), findsNothing);
      expect(find.text('Reply with Email'), findsOneWidget);
    });
  });
}
