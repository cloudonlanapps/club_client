import 'package:cl_club_forms/cl_club_forms.dart' show InquiryFormFields;
import 'package:cl_club_website/src/l10n/site_strings.dart';
import 'package:cl_club_website/src/models/inquiry_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what one inquiry submission carried.
class _RecordingNotifier extends ClPublicInquiryNotifier {
  int calls = 0;
  InquiryKind? kind;
  String? name;
  String? email;
  String? message;
  String? token;
  String? phone;
  Map<String, dynamic>? extra;
  String? website;

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
    calls += 1;
    this.kind = kind;
    this.name = name;
    this.email = email;
    this.message = message;
    this.token = token;
    this.phone = phone;
    this.extra = extra;
    this.website = website;
  }
}

Future<_RecordingNotifier> _submit(
  String typed,
  String code, {
  Map<String, String> answers = const {},
  String honeypot = '',
}) async {
  final notifier = _RecordingNotifier();
  await InquiryFormSubmit.create(
    notifier: notifier,
    defaultCountryCode: code,
    kind: InquiryKind.contact,
    token: 'token',
    values: {
      InquiryFormFields.nameId: 'Robin Example',
      InquiryFormFields.emailId: 'robin@example.test',
      InquiryFormFields.phoneId: typed,
      InquiryFormFields.messageId: 'Hello',
      InquiryFormFields.answersId: answers,
      InquiryFormFields.honeypotId: honeypot,
    },
  );
  expect(notifier.calls, 1);
  return notifier;
}

void main() {
  group('Issue 31: InquiryFormSubmit.create stores an international phone', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          expect((await _submit(typed, code)).phone, '+${code}9876543210');
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      expect((await _submit('+44 98765 43210', '91')).phone, '+449876543210');
      expect((await _submit('0044 98765-43210', '91')).phone, '+449876543210');
    });

    test('Issue 31: no phone is sent as none', () async {
      expect((await _submit('', '91')).phone, isNull);
      expect((await _submit('   ', '91')).phone, isNull);
    });

    test('Issue 31: answers and the honeypot travel as before', () async {
      final empty = await _submit('', '91');
      expect(empty.extra, isNull);
      expect(empty.website, isNull);

      final filled = await _submit(
        '',
        '91',
        answers: {'ageGroup': 'adult'},
        honeypot: 'https://spam.example.test',
      );
      expect(filled.extra, {'ageGroup': 'adult'});
      expect(filled.website, 'https://spam.example.test');
    });
  });

  group('Issue 84: InquiryFormSubmit takes the map of the form', () {
    test('Issue 84: create sends the map of InquiryForm.validate', () async {
      final notifier = _RecordingNotifier();
      await InquiryFormSubmit.create(
        notifier: notifier,
        defaultCountryCode: '91',
        kind: InquiryKind.interest,
        token: 'fill-time',
        values: {
          InquiryFormFields.nameId: 'Robin Example',
          InquiryFormFields.emailId: 'robin@example.test',
          InquiryFormFields.phoneId: '',
          InquiryFormFields.messageId: '',
          InquiryFormFields.answersId: <String, String>{},
          InquiryFormFields.honeypotId: '',
        },
      );

      expect(notifier.calls, 1);
      expect(notifier.kind, InquiryKind.interest);
      expect(notifier.name, 'Robin Example');
      expect(notifier.email, 'robin@example.test');
      expect(notifier.message, '');
      expect(notifier.token, 'fill-time');
      expect(notifier.phone, isNull);
      expect(notifier.extra, isNull);
      expect(notifier.website, isNull);
    });

    test('Issue 84: a refusal is worded from the copy, never the error', () {
      final strings = SiteStrings(const {
        'contactFormErrorRateLimited': 'Too many',
        'contactFormErrorGeneric': 'Try again',
      });
      ServerException refused(int status) => ServerException(
        statusCode: status,
        code: 'SOME_CODE',
        message: 'internal detail',
      );

      // Issue 97: only the rate limit is the form's to show; the rest is
      // the host's toast.
      expect(InquiryFormSubmit.formErrorFor(refused(429), strings), 'Too many');
      expect(InquiryFormSubmit.formErrorFor(refused(422), strings), isNull);
      expect(
        InquiryFormSubmit.formErrorFor(Exception('offline'), strings),
        isNull,
      );
      expect(InquiryFormSubmit.failureMessage(strings), 'Try again');
    });

    test('Issue 84: a required mark in the copy is left to the form', () {
      expect(inquiryLabelWithoutMark('Name *'), 'Name');
      expect(inquiryLabelWithoutMark('Name*'), 'Name');
      expect(inquiryLabelWithoutMark('Phone'), 'Phone');
      expect(inquiryLabelWithoutMark('5 * 2 lessons'), '5 * 2 lessons');

      final copy = buildInquiryFormCopy(
        strings: SiteStrings(const {
          'contactFormNameLabel': 'Name *',
          'contactFormEmailLabel': 'Email *',
          'contactFormPhoneLabel': 'Phone',
          'contactFormErrorRequired': 'Needed',
          'contactFormErrorEmail': 'Not an email',
        }),
        messageLabel: 'Message *',
        messagePlaceholder: 'Your message',
      );
      expect(copy.nameLabel, 'Name');
      expect(copy.emailLabel, 'Email');
      expect(copy.phoneLabel, 'Phone');
      expect(copy.messageLabel, 'Message');
      expect(copy.messagePlaceholder, 'Your message');
      expect(copy.nameRequired, 'Needed');
      expect(copy.emailRequired, 'Needed');
      expect(copy.messageRequired, 'Needed');
      expect(copy.emailInvalid, 'Not an email');
    });
  });
}
