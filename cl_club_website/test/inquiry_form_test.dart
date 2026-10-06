import 'dart:async';

import 'package:cl_club_website/src/l10n/site_strings.dart';
import 'package:cl_club_website/src/widgets/inquiry_form.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier, capabilitiesProvider, clPublicInquiryProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Hands out a token and records the phone a submission carried.
class _RecordingNotifier extends ClPublicInquiryNotifier {
  final List<String?> phones = [];

  @override
  Future<String> formToken() async => 'token';

  @override
  Future<void> submit({
    required InquiryKind kind,
    required String name,
    required String email,
    required String message,
    required String token,
    String? phone,
    Map<String, dynamic>? extra,
    String? website,
  }) async {
    phones.add(phone);
  }
}

const _name = 0;
const _email = 1;
const _phone = 2;
const _message = 3;

Future<void> _type(WidgetTester tester, int field, String text) =>
    tester.enterText(find.byType(ShadInput).at(field), text);

/// Pumps the form on a site whose server answers `GET /capabilities` with
/// [capabilities].
Future<_RecordingNotifier> _pump(
  WidgetTester tester, {
  required Future<Capabilities> Function() capabilities,
}) async {
  final notifier = _RecordingNotifier();
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clPublicInquiryProvider.overrideWith(() => notifier),
        capabilitiesProvider.overrideWith((ref) => capabilities()),
      ],
      child: ShadApp(
        home: SiteStringsScope(
          strings: SiteStrings(const {}),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: InquiryForm(
                kind: InquiryKind.contact,
                title: 'Contact',
                description: 'Write to us',
                messageLabel: 'Message',
                messagePlaceholder: 'Your message',
                submitLabel: 'Send',
                thanksTitle: 'Thanks',
                thanksBody: 'We will reply',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

Future<void> _fillAndSend(WidgetTester tester, String phone) async {
  await _type(tester, _name, 'Robin Example');
  await _type(tester, _email, 'robin@example.test');
  await _type(tester, _phone, phone);
  await _type(tester, _message, 'Hello');
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 31: the public inquiry form stores an international phone', () {
    testWidgets('Issue 31: a server reporting 44 gets +44', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: () async =>
            const Capabilities(creditSystem: false, defaultCountryCode: '44'),
      );

      await _fillAndSend(tester, '09876 543210');

      expect(notifier.phones, ['+449876543210']);
      expect(find.text('Thanks'), findsOneWidget);
    });

    testWidgets('Issue 31: a server reporting none gets +91', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: () async => const Capabilities(creditSystem: false),
      );

      await _fillAndSend(tester, '98765 43210');

      expect(notifier.phones, ['+919876543210']);
    });

    testWidgets('Issue 31: the country code is read when the form appears, '
        'not when it is sent', (tester) async {
      var reads = 0;
      final answer = Completer<Capabilities>();
      final notifier = await _pump(
        tester,
        capabilities: () {
          reads += 1;
          return answer.future;
        },
      );

      expect(reads, 1, reason: 'the form must start the read on appearing');

      answer.complete(
        const Capabilities(creditSystem: false, defaultCountryCode: '44'),
      );
      await tester.pump();
      await _fillAndSend(tester, '9876543210');

      expect(notifier.phones, ['+449876543210']);
      expect(reads, 1);
    });
  });
}
