// workflow_appelig: a member the application does not fit (club_client#341;
// covers #321 and #324).
//
// An application's age categories admit only members born in the last ten
// years. An active adult member with an identity document finds it under
// Applications and presses Download: the server refuses their form, and the
// refusal shows under the button, with no toast and nothing handed to the
// PDF action. The admin then unpublishes and deletes the application through
// its editor.
//
// The PDF action is the desktop's viewer on Linux, so the test stands in for
// it (`debugPdfBytesHandler`, cl_club_app) and checks it is never run.
//
// Fixtures (all `workflow_appelig_` prefixed), made with the SDK in setUpAll:
// the member and their identity document, and the published application
// with its age category (the refusal under test is the member's, so the
// template is a fixture). The admin is the stack's sudo user.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_appelig_ineligible_member_test.dart

import 'dart:typed_data';

import 'package:cl_club_app/src/utils/pdf_actions.dart'
    show debugPdfBytesHandler;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart' show kIdentityDocumentTag;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/forms.dart';
import '_helpers/navigation.dart';
import '_helpers/photos.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kMember = 'workflow_appelig_member';
const _kMemberPwd = 'WorkflowAppeligPwd!2024';
const _kTitle = 'workflow_appelig Junior trial';

const _kApplications = 'Applications';
const _kQuestion = 'Is your profile complete?';
const Key _kYes = ValueKey('application.profileComplete.yes');

/// The refusal of a member no age category fits
/// (`ApplicationViewStrings.notEligible`).
const _kNotEligible =
    'Not eligible for this application: none of its age categories matches '
    'the date of birth and gender on the profile.';

late Capabilities _caps;

/// The published application; set in setUpAll.
late int _templateId;

/// The bytes each run of the PDF action was handed.
final List<Uint8List> _pdfRuns = [];

Future<SecureClient> _adminClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// The step of the State card named [name] (`unpublish`, `delete`, …).
Finder _step(String name) => find.byKey(ValueKey('application.step.$name'));

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

/// A text printed in English only.
ApplicationText _english(String text) => ApplicationText.custom({'en': text});

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
    if (!_caps.applications) return;
    final admin = await _adminClient();
    try {
      // An adult, so the age category below does not fit them.
      await admin.users.createUser(
        username: _kMember,
        passwordHash: _kMemberPwd,
        firstName: 'Appelig',
        lastName: 'Workflow',
        phone: '7400535101',
        email: '$_kMember@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(1990, 5, 1),
      );
      final now = DateTime.now().toUtc();
      final created = await admin.applications.createApplication(
        ApplicationContent(
          title: _english(_kTitle),
          organisation: _english('workflow_appelig Skating Club'),
          declaration: _english('workflow_appelig: I declare it is true.'),
          formFooter: _english('workflow_appelig play fair'),
          ageCategories: [
            ApplicationAgeCategory(
              label: const {'en': 'workflow_appelig Under-10'},
              bornOnOrAfterUtc: DateTime.utc(now.year - 10),
            ),
          ],
        ),
      );
      await admin.applications.saveApplication(created.id);
      await admin.applications.publishApplication(created.id);
      _templateId = created.id;
    } finally {
      await admin.auth.logout();
    }
    // Applications are offered to a member with an identity document.
    final member = await createTestClient(baseUrl: _kApiBaseUrl);
    await member.auth.login(_kMember, _kMemberPwd);
    try {
      final media = await member.media.upload(
        fileBytes: pixelPng,
        filename: 'workflow_appelig-document.png',
        contentType: 'image/png',
        accessRoles: const ['self', 'admin'],
        encrypt: true,
      );
      await member.userMedia.attach(
        _kMember,
        tag: kIdentityDocumentTag,
        mediaUuid: media.uuid,
      );
    } finally {
      await member.auth.logout();
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
          if (t.content.title?.texts?['en'] != _kTitle) continue;
          if (t.status == ApplicationStatus.published) {
            await admin.applications.unpublishApplication(t.id);
          }
          await admin.applications.deleteApplication(t.id);
        }
        await admin.users.deleteUser(_kMember);
      }
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('a member no age category fits sees the refusal under '
      'Download, with no toast and no file', (tester) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    final id = _templateId;
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    // 1. The member finds the application under Applications.
    await loginViaUi(tester, _kMember, _kMemberPwd);
    await _openApplications(tester);
    final row = find.byKey(ValueKey('application.download.$id'));
    final download = find.descendant(
      of: row,
      matching: find.widgetWithText(ShadButton, 'Download'),
    );
    await waitFor(
      tester,
      () => download.evaluate().isNotEmpty,
      description: 'the application with its Download',
    );

    // 2. Download (Yes to the profile question, which lists the blanks of a
    // member made without an address) is refused under the button.
    invokeShadButton(tester, download, reason: 'Download');
    await settle(tester);
    final refusal = find.descendant(
      of: row,
      matching: find.text(_kNotEligible),
    );
    await waitFor(
      tester,
      () =>
          find.text(_kQuestion).evaluate().isNotEmpty ||
          refusal.evaluate().isNotEmpty,
      description: 'the profile question or the refusal',
    );
    if (find.text(_kQuestion).evaluate().isNotEmpty) {
      invokeShadButton(tester, find.byKey(_kYes), reason: 'Yes');
      await settle(tester);
    }
    await waitFor(
      tester,
      () {
        final toast = firstErrorToastMessage(tester);
        if (toast != null) {
          throw TestFailure('the refusal came as a toast: "$toast"');
        }
        return refusal.evaluate().isNotEmpty;
      },
      description: 'the not-eligible refusal under Download',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(firstErrorToastMessage(tester), isNull, reason: 'no toast');
    expect(_pdfRuns, isEmpty, reason: 'nothing is handed to the PDF action');
    expect(
      tester.widget<ShadButton>(download).enabled,
      isTrue,
      reason: 'the button is on again after the refusal',
    );
    await logout(tester);

    // 3. Cleanup through the UI: the admin unpublishes and deletes it.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
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
    await logout(tester);
  });
}
