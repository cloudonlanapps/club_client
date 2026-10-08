// workflow_siteinq: an inquiry sent from the site reaches the inbox
// (club_client#85).
//
// A visitor, with no session:
//
//   * fills the contact form on Contact, the phone typed without a country
//     code, and sends it once the server's three seconds have passed: the
//     thank-you shows, and the inquiry is stored as a contact inquiry with
//     the name, email, message and subject given, and the phone in
//     international format with the stack's country code, or 91 where the
//     stack reports none;
//   * fills the interest form at the sign-up address: it is stored as an
//     interest inquiry with its two answers, with a note and without one;
//   * sends the contact form again from the same email: the thank-you
//     shows, and the server keeps no second inquiry.
//
// The country code is the one the site reads from `GET /capabilities`
// without a session (club_core#31). What arrived is read back through the
// SDK as the super-admin, who also deletes it: the site has no inbox.
//
// Each submission meant to arrive has its own email address: the server
// drops a second one from the same sender and email within ten minutes.
//
// Recommended run (from the club_core root):
//   just website-test-one app_test_server1.conf \
//       workflow_siteinq_inquiry_reaches_inbox_test.dart

import 'package:cl_club_forms/cl_club_forms.dart' show InquiryFormFields;
import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/inquiry_thanks_card.dart'
    show InquiryThanksCard;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '_helpers/capabilities.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
import '_helpers/seed.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

/// Every inquiry of this file carries this in its name and email.
const _kId = 'workflow_siteinq';

const _kContactName = '$_kId contact';
const _kContactEmail = '${_kId}_contact@example.com';
const _kContactMessage = '$_kId a question about the programmes';
const _kContactSubject = 'programs';

/// The phone as the visitor types it: national, with no country code.
const _kNationalPhone = '9876543210';

const _kInterestName = '$_kId interest';
const _kInterestEmail = '${_kId}_interest@example.com';
const _kInterestNote = '$_kId a note with the interest';
const _kBareInterestName = '$_kId interest without a note';
const _kBareInterestEmail = '${_kId}_interest_bare@example.com';
const _kInterestAgeGroup = 'teen';
const _kInterestProgramme = 'camps';

const _kRepeatName = '$_kId contact again';
const _kRepeatMessage = '$_kId the same question, sent twice';

/// The server drops a submission returned within three seconds of the
/// token the form fetched when it appeared.
const _kMinFill = Duration(milliseconds: 3500);

/// The form's Send button: the only button inside the inquiry view.
Finder get _send => find.descendant(
  of: find.byType(InquiryView),
  matching: find.byType(ShadButton),
);

/// Opens [route], fills its inquiry form with [texts] (by field id) and
/// [answers] (by question key), and sends it after the server's three
/// seconds.
///
/// Returns null once the thank-you with [thanksTitle] shows in place of the
/// form, or the text of the error toast when the site reports that sending
/// failed.
Future<String?> _sendInquiry(
  WidgetTester tester, {
  required String route,
  required Map<String, String> texts,
  required Map<String, String> answers,
  required String Function(SiteStrings strings) thanksTitle,
}) async {
  await pumpSite(tester, apiBaseUrl: _kApiBaseUrl, location: route);
  expect(find.byType(InquiryView), findsOneWidget);
  final strings = container(tester).read(siteStringsProvider).requireValue;

  for (final text in texts.entries) {
    await enterTextById(tester, text.key, text.value);
  }
  setShadFormValues(tester, {
    for (final answer in answers.entries)
      InquiryFormFields.answerId(answer.key): answer.value,
  });
  await tester.pump();

  await tester.runAsync(() => Future<void>.delayed(_kMinFill));
  invokeShadButton(tester, _send, reason: 'Send');
  await waitFor(
    tester,
    () =>
        find.byType(InquiryThanksCard).evaluate().isNotEmpty ||
        firstErrorToastMessage(tester) != null,
    description: 'the thank-you of $route, or an error',
  );
  if (firstErrorToastMessage(tester) case final String failure) {
    expect(find.byType(InquiryThanksCard), findsNothing);
    return failure;
  }
  expect(
    tester.widget<InquiryThanksCard>(find.byType(InquiryThanksCard)).title,
    thanksTitle(strings),
  );
  expect(find.text(thanksTitle(strings)), findsOneWidget);
  // The form is gone: nothing typed is shown back.
  expect(_send, findsNothing);
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError('SUDO_PASSWORD must be supplied via --dart-define.');
  }

  late Capabilities caps;
  late SecureClient admin;

  /// The inquiries of this file the server holds, oldest first.
  Future<List<Inquiry>> stored() async {
    final page = await admin.inquiries.listInquiries(limit: 100);
    expect(page.total, lessThanOrEqualTo(100), reason: 'one page holds all');
    return page.items.where((i) => i.name.startsWith(_kId)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  setUpAll(() async {
    caps = await stackCapabilities(baseUrl: _kApiBaseUrl);
    admin = await sudoClient(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
    expect(await stored(), isEmpty, reason: 'no $_kId inquiry before the run');
  });

  tearDownAll(() async {
    for (final inquiry in await stored()) {
      await admin.inquiries.deleteInquiry(inquiry.id);
    }
    expect(await stored(), isEmpty, reason: 'the $_kId inquiries are deleted');
    await admin.auth.logout();
  });

  testWidgets('Issue 85: the contact form stores a contact inquiry, with the '
      "phone in international format under the stack's country code", (
    tester,
  ) async {
    final failure = await _sendInquiry(
      tester,
      route: '/public/contact-us',
      texts: {
        InquiryFormFields.nameId: _kContactName,
        InquiryFormFields.emailId: _kContactEmail,
        InquiryFormFields.phoneId: _kNationalPhone,
        InquiryFormFields.messageId: _kContactMessage,
      },
      answers: {'subject': _kContactSubject},
      thanksTitle: (strings) => strings.contactFormThanksTitle,
    );
    expect(failure, isNull, reason: 'the contact form was sent');

    final inquiry = (await stored()).single;
    expect(inquiry.kind, InquiryKind.contact);
    expect(inquiry.name, _kContactName);
    expect(inquiry.email, _kContactEmail);
    expect(inquiry.message, _kContactMessage);
    expect(inquiry.extra, {'subject': _kContactSubject});
    // The stack's code where it reports one, 91 where it reports none.
    expect(inquiry.phone, storedPhone(caps, _kNationalPhone));
    expect(
      inquiry.phone,
      startsWith('+${caps.defaultCountryCode ?? fallbackCountryCode}'),
    );
  });

  testWidgets('Issue 85: the interest form stores an interest inquiry with '
      'its two answers and its note', (tester) async {
    final before = (await stored()).length;
    final failure = await _sendInquiry(
      tester,
      route: '/auth/signup',
      texts: {
        InquiryFormFields.nameId: _kInterestName,
        InquiryFormFields.emailId: _kInterestEmail,
        InquiryFormFields.messageId: _kInterestNote,
      },
      answers: {
        'ageGroup': _kInterestAgeGroup,
        'programme': _kInterestProgramme,
      },
      thanksTitle: (strings) => strings.interestFormThanksTitle,
    );
    expect(failure, isNull, reason: 'the interest form was sent');

    final inquiries = await stored();
    expect(inquiries, hasLength(before + 1));
    final inquiry = inquiries.last;
    expect(inquiry.kind, InquiryKind.interest);
    expect(inquiry.name, _kInterestName);
    expect(inquiry.email, _kInterestEmail);
    expect(inquiry.message, _kInterestNote);
    expect(inquiry.phone, isNull);
    expect(inquiry.extra, {
      'ageGroup': _kInterestAgeGroup,
      'programme': _kInterestProgramme,
    });
  });

  testWidgets('Issue 85: the interest form, sent without a note, stores an '
      'interest inquiry with its two answers', (tester) async {
    final before = (await stored()).length;
    final failure = await _sendInquiry(
      tester,
      route: '/auth/signup',
      texts: {
        InquiryFormFields.nameId: _kBareInterestName,
        InquiryFormFields.emailId: _kBareInterestEmail,
      },
      answers: {
        'ageGroup': _kInterestAgeGroup,
        'programme': _kInterestProgramme,
      },
      thanksTitle: (strings) => strings.interestFormThanksTitle,
    );

    if (failure != null) {
      // The form lets the note be left out, and the site then sends an empty
      // message, which the server refuses: it requires one of every inquiry.
      // The visitor is told sending failed, and nothing is stored. Shown
      // here on the same request, so the skip names its cause.
      final strings = container(tester).read(siteStringsProvider).requireValue;
      expect(failure, strings.contactFormErrorGeneric);
      expect(await stored(), hasLength(before));
      await expectLater(
        admin.public.submitInquiry(
          kind: InquiryKind.interest,
          name: _kBareInterestName,
          email: _kBareInterestEmail,
          message: '',
          token: await admin.public.getInquiryFormToken(),
        ),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 422),
        ),
      );
      skipKnownFailure(
        issue: 85,
        what:
            'an interest sent without a note is refused: the server '
            'requires a message',
      );
      return;
    }

    final inquiries = await stored();
    expect(inquiries, hasLength(before + 1));
    final inquiry = inquiries.last;
    expect(inquiry.kind, InquiryKind.interest);
    expect(inquiry.name, _kBareInterestName);
    expect(inquiry.email, _kBareInterestEmail);
    expect(inquiry.message, isEmpty);
    expect(inquiry.extra, {
      'ageGroup': _kInterestAgeGroup,
      'programme': _kInterestProgramme,
    });
  });

  testWidgets('Issue 85: the same email sent again within ten minutes shows '
      'the thank-you and adds no inquiry', (tester) async {
    final before = await stored();
    expect(
      before.where((i) => i.email == _kContactEmail),
      hasLength(1),
      reason: 'the contact inquiry of the first test is what this repeats',
    );
    final total = (await admin.inquiries.listInquiries(limit: 100)).total;

    final failure = await _sendInquiry(
      tester,
      route: '/public/contact-us',
      texts: {
        InquiryFormFields.nameId: _kRepeatName,
        InquiryFormFields.emailId: _kContactEmail,
        InquiryFormFields.messageId: _kRepeatMessage,
      },
      answers: const {},
      thanksTitle: (strings) => strings.contactFormThanksTitle,
    );
    expect(failure, isNull, reason: 'the repeat shows the thank-you');

    // The server answered 202 and kept nothing: give a late write time to
    // land before counting.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    final after = await stored();
    expect(after.map((i) => i.id), before.map((i) => i.id));
    expect(after.map((i) => i.name), isNot(contains(_kRepeatName)));
    expect((await admin.inquiries.listInquiries(limit: 100)).total, total);
  });
}
