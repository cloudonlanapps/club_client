import 'dart:async';
import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart'
    show InquiryChoice, InquiryForm, InquiryFormFields, InquiryFormState;
import 'package:cl_club_website/src/l10n/site_strings.dart';
import 'package:cl_club_website/src/widgets/inquiry_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier, capabilitiesProvider, clPublicInquiryProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One submission, as the notifier was handed it.
typedef _Submission = ({
  InquiryKind kind,
  String name,
  String email,
  String message,
  String token,
  String? phone,
  Map<String, dynamic>? extra,
  String? website,
});

/// Hands out a token and records what each submission carried.
class _RecordingNotifier extends ClPublicInquiryNotifier {
  final List<String?> phones = [];
  final List<_Submission> submissions = [];

  /// How many tokens were asked for.
  int tokens = 0;

  /// What the next submissions fail with; null lets them through.
  Exception? failure;

  /// When set, a submission waits for it before answering.
  Completer<void>? hold;

  @override
  Future<String> formToken() async {
    tokens += 1;
    return 'token';
  }

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
    await hold?.future;
    final refusal = failure;
    if (refusal != null) throw refusal;
    phones.add(phone);
    submissions.add((
      kind: kind,
      name: name,
      email: email,
      message: message,
      token: token,
      phone: phone,
      extra: extra,
      website: website,
    ));
  }
}

/// The site's copy the Issue 84 cases read: the labels as a club's ARB
/// writes them, required marks included.
const _siteCopy = {
  'contactFormNameLabel': 'Name *',
  'contactFormNamePlaceholder': 'Your full name',
  'contactFormEmailLabel': 'Email *',
  'contactFormEmailPlaceholder': 'you@example.test',
  'contactFormPhoneLabel': 'Phone',
  'contactFormPhonePlaceholder': '99999 99999',
  'contactFormSending': 'Sending',
  'contactFormErrorRequired': 'Needed.',
  'contactFormErrorEmail': 'Not an email address.',
  'contactFormErrorRateLimited': 'Too many messages just now.',
  'contactFormErrorGeneric': 'Something went wrong.',
};

const _ageGroup = InquiryChoice(
  key: 'ageGroup',
  label: 'Age group *',
  placeholder: 'Select an age group',
  options: {'child': 'Child', 'adult': 'Adult'},
);

Future<Capabilities> _noCountryCode() async =>
    const Capabilities(creditSystem: false);

/// The one message [text], shown inside the form's field [id].
Finder _onField(String id, String text) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is ShadFormBuilderField && widget.id == id,
  ),
  matching: find.text(text),
);

InquiryFormState _formState(WidgetTester tester) =>
    tester.state<InquiryFormState>(find.byType(InquiryForm));

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
  Map<String, String> strings = const {},
  InquiryKind kind = InquiryKind.contact,
  bool messageRequired = true,
  List<InquiryChoice> choices = const [],
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
          strings: SiteStrings(strings),
          child: Scaffold(
            body: SingleChildScrollView(
              child: InquiryView(
                kind: kind,
                title: 'Contact',
                description: 'Write to us',
                messageLabel: 'Message',
                messagePlaceholder: 'Your message',
                submitLabel: 'Send',
                thanksTitle: 'Thanks',
                thanksBody: 'We will reply',
                messageRequired: messageRequired,
                choices: choices,
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

  group('Issue 84: the website hosts InquiryForm', () {
    testWidgets('Issue 84: the host draws the title, the description and '
        'Send around the form, whose rows carry one required mark', (
      tester,
    ) async {
      await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
        choices: const [_ageGroup],
      );

      expect(find.byType(InquiryForm), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Write to us'), findsOneWidget);
      final send = find.widgetWithText(ShadButton, 'Send');
      expect(send, findsOneWidget);
      expect(
        find.descendant(of: find.byType(InquiryForm), matching: send),
        findsNothing,
      );
      for (final label in ['Name *', 'Email *', 'Phone', 'Age group']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Message *'), findsOneWidget);
      expect(find.text('Your full name'), findsOneWidget);
    });

    testWidgets('Issue 84: a missing name, email and message each show on '
        'their own field, and nothing is sent', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
      );

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      for (final id in [
        InquiryFormFields.nameId,
        InquiryFormFields.emailId,
        InquiryFormFields.messageId,
      ]) {
        expect(_onField(id, 'Needed.'), findsOneWidget, reason: id);
      }
      expect(find.text('Needed.'), findsNWidgets(3));
      expect(notifier.submissions, isEmpty);
      expect(find.text('Thanks'), findsNothing);
    });

    testWidgets('Issue 84: a malformed email shows on the email field, and '
        'nothing is sent', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
      );

      await _type(tester, _name, 'Robin Example');
      await _type(tester, _email, 'robin-at-example');
      await _type(tester, _message, 'Hello');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(
        _onField(InquiryFormFields.emailId, 'Not an email address.'),
        findsOneWidget,
      );
      expect(find.text('Needed.'), findsNothing);
      expect(notifier.submissions, isEmpty);
    });

    testWidgets('Issue 84: a submission with no phone, no answer and an '
        'empty honeypot sends them as absent', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
        choices: const [_ageGroup],
      );

      await _type(tester, _name, '  Robin Example ');
      await _type(tester, _email, ' robin@example.test ');
      await _type(tester, _message, ' Hello ');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(notifier.submissions, [
        (
          kind: InquiryKind.contact,
          name: 'Robin Example',
          email: 'robin@example.test',
          message: 'Hello',
          token: 'token',
          phone: null,
          extra: null,
          website: null,
        ),
      ]);
      expect(find.text('Thanks'), findsOneWidget);
      expect(find.text('We will reply'), findsOneWidget);
      expect(find.byType(InquiryForm), findsNothing);
    });

    testWidgets('Issue 84: an interest with an answer, a phone and a filled '
        'honeypot sends all three, and needs no message', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
        kind: InquiryKind.interest,
        messageRequired: false,
        choices: const [_ageGroup],
      );

      await _type(tester, _name, 'Robin Example');
      await _type(tester, _email, 'robin@example.test');
      await _type(tester, _phone, '98765 43210');
      await tester.tap(find.text('Select an age group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adult').last);
      await tester.pumpAndSettle();
      _formState(tester).formKey.currentState!.setFieldValue(
        InquiryFormFields.honeypotId,
        'https://spam.example.test',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(notifier.submissions, hasLength(1));
      final sent = notifier.submissions.single;
      expect(sent.kind, InquiryKind.interest);
      expect(sent.message, '');
      expect(sent.phone, '+919876543210');
      expect(sent.extra, {'ageGroup': 'adult'});
      expect(sent.website, 'https://spam.example.test');
    });

    testWidgets('Issue 84: the token is fetched once, when the view '
        'appears', (tester) async {
      final notifier = await _pump(tester, capabilities: _noCountryCode);

      expect(notifier.tokens, 1);

      await _fillAndSend(tester, '');
      expect(notifier.tokens, 1);
      expect(notifier.submissions.single.token, 'token');
    });

    testWidgets('Issue 84: while it sends, the fields and Send are off', (
      tester,
    ) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
      );
      notifier.hold = Completer<void>();

      await _type(tester, _name, 'Robin Example');
      await _type(tester, _email, 'robin@example.test');
      await _type(tester, _message, 'Hello');
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sending'), findsOneWidget);
      expect(
        tester.widget<ShadButton>(find.byType(ShadButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<InquiryForm>(find.byType(InquiryForm)).enabled,
        false,
      );

      notifier.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Thanks'), findsOneWidget);
    });

    testWidgets('Issue 84: a rate-limit refusal shows inline in the form, '
        'which keeps what was typed and can be sent again', (tester) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
      );
      notifier.failure = const ServerException(
        statusCode: 429,
        code: 'RATE_LIMITED',
        message: 'internal detail',
      );

      await _fillAndSend(tester, '');

      expect(
        find.descendant(
          of: find.byType(InquiryForm),
          matching: find.text('Too many messages just now.'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('internal detail'), findsNothing);
      expect(find.text('Thanks'), findsNothing);
      expect(find.text('Robin Example'), findsOneWidget);
      expect(
        tester.widget<InquiryForm>(find.byType(InquiryForm)).enabled,
        true,
      );

      notifier.failure = null;
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(notifier.submissions, hasLength(1));
      expect(find.text('Thanks'), findsOneWidget);
    });

    testWidgets('Issue 84: any other failure shows the generic message', (
      tester,
    ) async {
      final notifier = await _pump(
        tester,
        capabilities: _noCountryCode,
        strings: _siteCopy,
      );
      notifier.failure = Exception('connection refused');

      await _fillAndSend(tester, '');

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.textContaining('connection refused'), findsNothing);
    });

    test(
      'Issue 84: cl_club_website/lib builds no input control of its own',
      () {
        final control = RegExp(
          r'\b(ShadInput|ShadTextarea|ShadSelect|ShadCheckbox|ShadSwitch|'
          'ShadRadio|ShadRadioGroup|ShadSlider|ShadDatePicker|ShadTimePicker|'
          'ShadInputOTP|ShadForm|TextField|TextFormField|EditableText|'
          'DropdownButton|Checkbox|Switch|Radio|Slider|TextEditingController)'
          r'\w*(<[^>]*>)?(\.\w+)?\(',
        );
        final files = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList();
        // Guards the reading of the folder: no file would pass anything.
        expect(files.length, greaterThan(20));
        final offenders = [
          for (final file in files)
            if (control.hasMatch(file.readAsStringSync())) file.path,
        ];
        expect(offenders, isEmpty);
      },
    );
  });
}
