// workflow_appjourney: a new member's way to an application form, from
// sign-up to a download after approval (club_client#341; covers #321, #324,
// #340).
//
// The admin creates, saves and publishes an application. A new account, a
// member under 18, signs up, uploads an identity document and submits it,
// and lands on the waiting page with the application listed. Update profile
// opens the onboarding profile page, where the member fills in their
// guardian, sports details and background (a position and a language from
// the club's profile options, sent as lists: club_client#343). Download on
// the waiting page asks "Is your profile complete?" and lists what is
// blank, none of those among it; No opens the profile page. There, No
// only closes the question and Yes downloads. Back on the waiting page, Yes
// downloads too. The admin approves the member, who signs in again and
// downloads the form from Applications.
//
// The PDF action is the desktop's viewer on Linux, so the test stands in for
// it (`debugPdfBytesHandler`, cl_club_app) and checks the bytes each
// Download hands it.
//
// Against club_server main the onboarding profile page saves only the
// extended cards (Guardian, Sports details, Background) for a pending
// member, so the "nothing blank, no question" path of #340 cannot be
// reached here: the server takes only the extended fields from a member who
// is not active (`check_profile_edit_access`, 403 ACCOUNT_NOT_ACTIVE), so
// Personal details, contact and address fail with "Could not save" (#340
// assumed the server takes every card). The address stays blank.
//
// The club's profile options are set for the test through the SDK, as the
// super admin, and put back as they were afterwards.

// Fixtures (all `workflow_appjourney_` prefixed): the member, signed up
// through the UI, and the application, created through the UI; both are
// deleted through the UI. The admin is the stack's sudo user.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_appjourney_member_journey_test.dart

import 'dart:typed_data';

import 'package:cl_club_app/src/utils/pdf_actions.dart'
    show debugPdfBytesHandler;
import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationCustomText, SignupGender, UserFormFields;
import 'package:cl_club_members/src/widgets/background_card.dart';
import 'package:cl_club_members/src/widgets/guardian_card.dart';
import 'package:cl_club_members/src/widgets/personal_details_card.dart';
import 'package:cl_club_members/src/widgets/sports_details_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider, imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/editors.dart';
import '_helpers/forms.dart';
import '_helpers/navigation.dart';
import '_helpers/photos.dart';
import '_helpers/pump.dart';
import '_helpers/surface.dart';
import '_helpers/users.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kMember = 'workflow_appjourney_member';
const _kMemberPwd = 'WorkflowAppjourneyPwd!2024';
const _kMemberEmail = 'workflow_appjourney_member@example.com';
const _kMemberPhone = '7400534101';
const _kGuardian = 'Appjourney Guardian';
const _kPosition = 'workflow_appjourney_forward';
const _kLanguage = 'workflow_appjourney Marathi';

const _kTitle = 'workflow_appjourney Trial';
const _kOrganisation = 'workflow_appjourney Skating Club';
const _kFooter = 'workflow_appjourney play fair';
const _kDeclaration = 'workflow_appjourney: I declare the above is true.';

const _kApplications = 'Applications';
const _kQuestion = 'Is your profile complete?';
const Key _kYes = ValueKey('application.profileComplete.yes');
const Key _kNo = ValueKey('application.profileComplete.no');

/// The printed fields still blank once the member has filled in the cards
/// a pending member may save: the address (club_client#340).
const _kBlankAfterProfile = ['Address'];

/// The printed fields the member fills in on the profile page, which the
/// question then no longer lists.
const _kFilledOnProfile = [
  'Nationality',
  'Preferred language',
  'Club / District',
  'Preferred position',
  'Past experience',
  'Guardian',
];

/// The printed fields sign-up fills, which the question never lists.
const _kFilledBySignup = [
  'First name',
  'Last name',
  'Date of Birth',
  'Gender',
  'Phone',
  'Email',
];

late Capabilities _caps;

/// The club's profile options before the test, put back after it.
ProfileOptions? _savedOptions;

/// The bytes each run of the PDF action was handed, in order.
final List<Uint8List> _pdfRuns = [];

Future<SecureClient> _adminClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// The step of the State card named [name] (`save`, `publish`, …).
Finder _step(String name) => find.byKey(ValueKey('application.step.$name'));

/// The section card of the editor named [name] (`heading`, …).
Finder _section(String name) =>
    find.byKey(ValueKey('application.section.$name'));

/// Waits for the step [name] to be enabled, then runs it.
Future<void> _run(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () =>
        _step(name).evaluate().isNotEmpty &&
        tester.widget<ActionButton>(_step(name)).enabled,
    description: 'the "$name" step to be enabled',
  );
  tester.widget<ActionButton>(_step(name)).onPressed!();
  await settle(tester);
}

/// Saves the inline editor open in [card] with its own Save, and waits for
/// it to close. Fails fast on an error toast.
Future<void> _saveCard(WidgetTester tester, Finder card) async {
  final save = find.descendant(
    of: card,
    matching: find.widgetWithText(ShadButton, 'Save'),
  );
  invokeShadButton(tester, save, reason: 'the section editor Save');
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
  final toast = firstErrorToastMessage(tester);
  if (toast != null) throw TestFailure('section save failed: "$toast"');
  await waitFor(
    tester,
    () => save.evaluate().isEmpty,
    description: 'the section editor to close once saved',
  );
}

/// Opens *Applications* from the sidebar.
Future<void> _openApplications(WidgetTester tester) async {
  await waitFor(
    tester,
    () =>
        find
            .widgetWithText(SidebarItem, _kApplications)
            .evaluate()
            .isNotEmpty ||
        find.byTooltip('Open menu').evaluate().isNotEmpty,
    description: 'the Applications sidebar entry',
  );
  await openSidebarEntry(tester, _kApplications);
}

/// The admin creates the application through the UI, writes what it needs,
/// saves and publishes it, and returns its id.
Future<int> _publishApplicationViaUi(WidgetTester tester) async {
  await _openApplications(tester);
  final create = find.widgetWithText(ShadButton, 'Create application');
  await waitFor(
    tester,
    () => create.evaluate().isNotEmpty,
    description: 'the Create application button',
  );
  invokeShadButton(tester, create, reason: 'Create application');
  await settle(tester);
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'title')
        .evaluate()
        .isNotEmpty,
    description: 'the create dialog',
  );
  await enterTextById(tester, 'title', _kTitle);
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Save'),
    reason: 'create dialog Save',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => _step('save').evaluate().isNotEmpty,
    description: 'the new draft to open in the editor',
  );

  // The organisation and the footer line: the first and last texts of the
  // heading section.
  await tapSectionPencil(tester, _section('heading'));
  final inputs = find.descendant(
    of: _section('heading'),
    matching: find.byType(EditableText),
  );
  await tester.enterText(inputs.first, _kOrganisation);
  await tester.enterText(inputs.last, _kFooter);
  await tester.pump();
  await _saveCard(tester, _section('heading'));

  // The declaration, written for this application. The section's own form
  // is the outermost one inside its card.
  await tapSectionPencil(tester, _section('declaration'));
  tester
      .state<ShadFormState>(
        find
            .descendant(
              of: _section('declaration'),
              matching: find.byType(ShadForm),
            )
            .first,
      )
      .setValue({
        'declaration': const ApplicationCustomText({'en': _kDeclaration}),
      });
  await tester.pump();
  await _saveCard(tester, _section('declaration'));

  await _run(tester, 'save');
  await _run(tester, 'publish');
  await waitFor(
    tester,
    () => tester.widget<ActionButton>(_step('unpublish')).enabled,
    description: 'the application to be published',
  );
  final templates = container(tester).read(clApplicationsMasterProvider);
  return templates.value!.values
      .firstWhere((t) => t.content.title?.texts['en'] == _kTitle)
      .id;
}

/// Signs up [_kMember] through the login page's Sign up link.
Future<void> _signupViaUi(WidgetTester tester) async {
  await go(tester, '/auth/login');
  await waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Sign up').evaluate().isNotEmpty,
    description: 'the Sign up link on the login page',
  );
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Sign up'),
    reason: 'the Sign up link',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => find.text('Create an account').evaluate().isNotEmpty,
    description: 'the sign-up form',
  );
  await enterTextById(tester, 'username', _kMember);
  await enterTextById(tester, 'email', _kMemberEmail);
  await enterTextById(tester, 'password', _kMemberPwd);
  await enterTextById(tester, 'confirmPassword', _kMemberPwd);
  await enterTextById(tester, 'firstName', 'Appjourney');
  await enterTextById(tester, 'lastName', 'Workflow');
  await enterTextById(tester, 'phone', _kMemberPhone);
  setShadFormValues(tester, {
    'gender': SignupGender.preferNotToSay,
    // Under 18, so the form prints a guardian.
    'dateOfBirthUtc': DateTime.utc(DateTime.now().year - 15, 3, 1),
  });
  await tester.pump();
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Create account'),
    reason: 'Create account',
  );
  await settle(tester);
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('sign-up refused: "$toast"');
      return find
          .widgetWithText(ShadButton, 'Create account')
          .evaluate()
          .isEmpty;
    },
    description: 'the sign-up form to close',
  );
}

/// From the welcome page: Continue, upload the (stubbed) identity document,
/// accept the privacy policy and Submit.
Future<void> _submitDocumentViaUi(WidgetTester tester) async {
  await waitFor(
    tester,
    () => find.text('Welcome aboard - almost!').evaluate().isNotEmpty,
    description: 'the onboarding welcome page',
  );
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Continue'),
    reason: 'the welcome page Continue',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => find.byIcon(Icons.add).evaluate().isNotEmpty,
    description: 'the identity-document add tile',
  );
  await tapVisible(tester, find.byIcon(Icons.add).first);
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);

  final privacy = find.byWidgetPredicate(
    (w) => w is ShadCheckboxFormField && w.id == 'privacyAccepted',
  );
  await waitFor(
    tester,
    () => privacy.evaluate().isNotEmpty,
    description: 'the privacy checkbox',
  );
  tester
      .widget<ShadCheckbox>(
        find.descendant(of: privacy, matching: find.byType(ShadCheckbox)),
      )
      .onChanged
      ?.call(true);
  await settle(tester);

  final submit = find.widgetWithText(ShadButton, 'Submit');
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('submission blocked: "$toast"');
      if (find.textContaining("Couldn't upload").evaluate().isNotEmpty) {
        throw TestFailure('the identity document did not upload');
      }
      return submit.evaluate().isNotEmpty &&
          tester.widget<ShadButton>(submit).onPressed != null;
    },
    description: 'Submit to enable after the upload',
  );
  invokeShadButton(tester, submit, reason: 'the documents Submit');
  await settle(tester);
}

/// The waiting page, with the published application listed.
Future<void> _waitForWaitingPage(WidgetTester tester, int id) async {
  await waitFor(
    tester,
    () => find.text('Thanks for signing up!').evaluate().isNotEmpty,
    description: 'the waiting page',
  );
  await waitFor(
    tester,
    () => _downloadButtonIn(_row(id)).evaluate().isNotEmpty,
    description: 'the application listed on the waiting page',
  );
}

/// The download row of application [id] in a published list.
Finder _row(int id) => find.byKey(ValueKey('application.download.$id'));

/// The Download button inside [scope].
Finder _downloadButtonIn(Finder scope) => find.descendant(
  of: scope,
  matching: find.widgetWithText(ShadButton, 'Download'),
);

/// The Applications section of the onboarding profile page.
final Finder _profileSection = find.byKey(
  const ValueKey('profile.section.applications'),
);

/// The onboarding profile page (`OnboardingProfileView.bodyKey`).
final Finder _profilePage = find.byKey(
  const ValueKey('onboarding.profile.body'),
);

/// Presses the Download button inside [scope].
Future<void> _pressDownload(WidgetTester tester, Finder scope) async {
  invokeShadButton(tester, _downloadButtonIn(scope), reason: 'Download');
  await settle(tester);
}

/// Waits for "Is your profile complete?" to show.
Future<void> _waitForQuestion(WidgetTester tester) => waitFor(
  tester,
  () => find.text(_kQuestion).evaluate().isNotEmpty,
  description: 'the "$_kQuestion" dialog',
);

/// Answers the open question with the button keyed [answer].
Future<void> _answer(WidgetTester tester, Key answer) async {
  invokeShadButton(tester, find.byKey(answer), reason: 'answer $answer');
  await settle(tester);
  await waitFor(
    tester,
    () => find.text(_kQuestion).evaluate().isEmpty,
    description: 'the question to close',
  );
}

/// Waits for the PDF action's run number [n] (from 1) and checks it was
/// handed a PDF.
Future<void> _expectPdfRun(WidgetTester tester, int n) async {
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('download failed: "$toast"');
      return _pdfRuns.length >= n;
    },
    description: 'the PDF action to run ($n)',
    timeout: const Duration(seconds: 40),
  );
  expect(_pdfRuns, hasLength(n), reason: 'one run per Download');
  expect(_pdfRuns.last, isNotEmpty, reason: 'the action is handed the form');
  expect(
    String.fromCharCodes(_pdfRuns.last.take(4)),
    '%PDF',
    reason: 'the bytes are a PDF',
  );
}

/// The signed-in member, as the session holds them.
UserPrivate _me(WidgetTester tester) =>
    container(tester).read(authStateProvider).valueOrNull!;

/// The Guardian card of the profile page.
final Finder _guardianCard = find.byKey(GuardianCard.cardKey);

/// The Sports details card of the profile page.
final Finder _sportsCard = find.byKey(SportsDetailsCard.cardKey);

/// The Background card of the profile page.
final Finder _backgroundCard = find.byKey(BackgroundCard.cardKey);

/// Sets [values] on the form of the editor open in [card], the outermost
/// one inside it.
Future<void> _setCardValues(
  WidgetTester tester,
  Finder card,
  Map<String, Object?> values,
) async {
  tester
      .state<ShadFormState>(
        find.descendant(of: card, matching: find.byType(ShadForm)).first,
      )
      .setValue(values);
  await tester.pump();
}

/// The card of [type] on the page.
Finder _card(Type type) =>
    find.byElementPredicate((e) => e.widget.runtimeType == type);

/// Opens the editor of [card], waiting for its field [anchorId].
Future<void> _editCard(
  WidgetTester tester,
  Finder card,
  String anchorId,
) async {
  await tapSectionPencil(tester, card);
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == anchorId)
        .evaluate()
        .isNotEmpty,
    description: 'the editor with field "$anchorId"',
  );
}

/// The onboarding shell's back arrow.
Future<void> _back(WidgetTester tester) async {
  final back = find.widgetWithIcon(IconButton, LucideIcons.arrowLeft);
  expect(back, findsOneWidget, reason: 'the onboarding back arrow');
  tester.widget<IconButton>(back).onPressed!();
  await settle(tester);
}

/// Approves the one pending member through the users list's Act Now.
Future<void> _approveViaUi(WidgetTester tester) async {
  await go(tester, '/memberzone/users');
  final actNow = find.widgetWithText(ShadButton, 'Act Now');
  await waitFor(
    tester,
    () => actNow.evaluate().isNotEmpty,
    description: 'the pending-approvals Act Now banner',
  );
  invokeShadButton(tester, actNow, reason: 'Act Now');
  await settle(tester);
  final approve = find.widgetWithText(ShadButton, 'Approve');
  await waitFor(
    tester,
    () => approve.evaluate().isNotEmpty,
    description: 'the Approve button on the review page',
  );
  invokeShadButton(tester, approve, reason: 'Approve');
  await settle(tester);
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('approval failed: "$toast"');
      return approve.evaluate().isEmpty;
    },
    description: 'the member to be approved',
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Unpublishes and deletes application [id] from its editor.
Future<void> _deleteApplicationViaUi(WidgetTester tester, int id) async {
  await _openApplications(tester);
  final card = find.byKey(ValueKey('application.row.$id'));
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'the application in the admin list',
  );
  await tapVisible(tester, card);
  await settle(tester);
  await _run(tester, 'unpublish');
  await _run(tester, 'delete');
  final confirm = find.widgetWithText(ShadButton, 'Delete');
  await waitFor(
    tester,
    () => confirm.evaluate().length > 1,
    description: 'the delete confirmation',
  );
  tester.widget<ShadButton>(confirm.last).onPressed!();
  await settle(tester);
  await waitFor(
    tester,
    () => card.evaluate().isEmpty && find.text(_kTitle).evaluate().isEmpty,
    description: 'the deleted application to leave the list',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  setUpAll(() async {
    _caps = await stackCapabilities(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
    if (!_caps.extendedProfile) return;
    final admin = await _adminClient();
    try {
      final saved = await admin.users.getProfileOptions();
      _savedOptions = saved;
      await admin.users.setProfileOptions(
        ProfileOptions(
          positions: [
            ...saved.positions,
            const ProfilePosition(value: _kPosition, label: {'en': 'Forward'}),
          ],
          languages: [...saved.languages, _kLanguage],
        ),
      );
    } finally {
      await admin.auth.logout();
    }
  });

  setUp(() {
    _pdfRuns.clear();
    debugPdfBytesHandler = (bytes, fileName) async => _pdfRuns.add(bytes);
  });

  tearDown(() => debugPdfBytesHandler = null);

  tearDownAll(() async {
    final admin = await _adminClient();
    try {
      if (_caps.applications) {
        // Only when the UI cleanup did not run to the end.
        final left = await admin.applications.listApplications(limit: 100);
        for (final t in left.items) {
          if (t.content.title?.texts['en'] != _kTitle) continue;
          if (t.status == ApplicationStatus.published) {
            await admin.applications.unpublishApplication(t.id);
          }
          await admin.applications.deleteApplication(t.id);
        }
      }
      try {
        await admin.users.deleteUser(_kMember);
      } on ServerException catch (e) {
        // Never signed up, or already deleted through the UI.
        // ignore: avoid_print
        print('[test] $_kMember not deleted in tearDownAll: ${e.code}');
      }
      final saved = _savedOptions;
      if (saved != null) await admin.users.setProfileOptions(saved);
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('a new member signs up, completes their profile from the '
      'waiting page and downloads their form before and after approval', (
    tester,
  ) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    if (skipUnless(
      enabled: _caps.extendedProfile,
      feature: 'extended profile',
    )) {
      return;
    }
    await useTestSurface(tester, const Size(1600, 4000));
    await pumpApp(
      tester,
      apiBaseUrl: _kApiBaseUrl,
      extraOverrides: [
        imagePickerProvider.overrideWithValue(
          stubPicker('workflow_appjourney-document.png'),
        ),
      ],
    );
    await ensureLoggedOut(tester);

    // 1. The admin publishes an application.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    final id = await _publishApplicationViaUi(tester);
    await logout(tester);

    // 2. A new account signs up, uploads an identity document and submits
    // it, and lands on the waiting page with the application listed.
    await _signupViaUi(tester);
    await loginViaUi(tester, _kMember, _kMemberPwd);
    await _submitDocumentViaUi(tester);
    await _waitForWaitingPage(tester, id);
    expect(_me(tester).status, UserStatus.pending);

    // 3. Update profile opens the profile page, with every card, where the
    // member fills in their guardian, sports details and background; back
    // returns to the waiting page.
    invokeShadButton(
      tester,
      find.widgetWithText(ShadButton, 'Update profile'),
      reason: 'Update profile',
    );
    await settle(tester);
    await waitFor(
      tester,
      () => _profilePage.evaluate().isNotEmpty,
      description: 'the onboarding profile page',
    );
    expect(find.text('Your profile'), findsOneWidget);
    expect(_card(PersonalDetailsCard), findsOneWidget);
    await _editCard(tester, _guardianCard, UserFormFields.guardianNameId);
    await enterTextById(tester, UserFormFields.guardianNameId, _kGuardian);
    await enterTextById(tester, UserFormFields.guardianRelationId, 'Parent');
    await enterTextById(tester, UserFormFields.guardianPhoneId, '7400534102');
    await _saveCard(tester, _guardianCard);
    await waitFor(
      tester,
      () => _me(tester).guardian?.name == _kGuardian,
      description: 'the saved guardian to reach the session',
    );
    await _editCard(tester, _sportsCard, UserFormFields.clubDistrictId);
    await enterTextById(tester, UserFormFields.clubDistrictId, 'Pune');
    await enterTextById(tester, UserFormFields.pastExperienceId, 'Two seasons');
    await _setCardValues(tester, _sportsCard, {
      UserFormFields.preferredPositionsId: _kPosition,
    });
    await _saveCard(tester, _sportsCard);
    await _editCard(tester, _backgroundCard, UserFormFields.nationalityId);
    await enterTextById(tester, UserFormFields.nationalityId, 'Indian');
    await _setCardValues(tester, _backgroundCard, {
      UserFormFields.preferredLanguagesId: _kLanguage,
    });
    await _saveCard(tester, _backgroundCard);
    await waitFor(
      tester,
      () =>
          _me(tester).preferredPositions.join() == _kPosition &&
          _me(tester).preferredLanguages.join() == _kLanguage,
      description: 'the saved position and language to reach the session',
    );
    await _back(tester);
    await _waitForWaitingPage(tester, id);

    // 4. Download asks first, listing what is blank; No opens the profile
    // page and downloads nothing.
    await _pressDownload(tester, _row(id));
    await _waitForQuestion(tester);
    for (final field in _kBlankAfterProfile) {
      expect(
        find.text('• $field'),
        findsOneWidget,
        reason: 'Issue 340: "$field" is blank and listed',
      );
    }
    for (final field in [
      ..._kFilledBySignup,
      ..._kFilledOnProfile,
      'Middle name',
    ]) {
      expect(
        find.text('• $field'),
        findsNothing,
        reason: 'Issue 340: "$field" is not listed',
      );
    }
    await _answer(tester, _kNo);
    await waitFor(
      tester,
      () => _profilePage.evaluate().isNotEmpty,
      description: 'No to open the profile page',
    );
    expect(_pdfRuns, isEmpty, reason: 'No downloads nothing');

    // 5. On the profile page No only closes the question, and Yes downloads
    // the form with its blanks.
    await waitFor(
      tester,
      () => _downloadButtonIn(_profileSection).evaluate().isNotEmpty,
      description: 'the Applications section of the profile page',
    );
    await _pressDownload(tester, _profileSection);
    await _waitForQuestion(tester);
    await _answer(tester, _kNo);
    expect(_profilePage, findsOneWidget, reason: 'No stays on the page');
    expect(_pdfRuns, isEmpty, reason: 'No downloads nothing');
    await _pressDownload(tester, _profileSection);
    await _waitForQuestion(tester);
    await _answer(tester, _kYes);
    await _expectPdfRun(tester, 1);

    // 6. Back on the waiting page, Download asks again, and Yes downloads.
    await _back(tester);
    await _waitForWaitingPage(tester, id);
    await _pressDownload(tester, _row(id));
    await _waitForQuestion(tester);
    await _answer(tester, _kYes);
    await _expectPdfRun(tester, 2);
    invokeShadButton(
      tester,
      find.widgetWithText(ShadButton, 'Back to sign in'),
      reason: 'Back to sign in',
    );
    await waitFor(
      tester,
      () => currentUser(tester) == null,
      description: 'the member to be signed out',
    );
    await settle(tester);

    // 7. The admin approves the member.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await _approveViaUi(tester);
    await logout(tester);

    // 8. The member signs in again and downloads the form from
    // Applications.
    await loginViaUi(tester, _kMember, _kMemberPwd);
    expect(_me(tester).status, UserStatus.active);
    await _openApplications(tester);
    await waitFor(
      tester,
      () => _downloadButtonIn(_row(id)).evaluate().isNotEmpty,
      description: 'the application on the member Applications page',
    );
    await _pressDownload(tester, _row(id));
    await _waitForQuestion(tester);
    await _answer(tester, _kYes);
    await _expectPdfRun(tester, 3);
    await logout(tester);

    // 9. Cleanup through the UI: the application, then the member.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await _deleteApplicationViaUi(tester, id);
    await softDeleteUserViaUi(tester, _kMember);
    await logout(tester);
  });
}
