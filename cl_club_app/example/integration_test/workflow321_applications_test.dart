// workflow321: printable applications, end to end (club_client#321, design
// §2–§3).
//
// With applications on: the admin opens *Applications*, creates a draft,
// writes the footer line and the declaration in their sections, saves it
// (the server decides its layout) and publishes it; a member who has
// uploaded an identity document finds it under their own *Applications*,
// with Download, and their form downloads as a PDF; the admin then
// unpublishes and deletes it through the editor. With applications off (the
// server offers them only with identity verification), no *Applications*
// entry appears.
//
// Fixtures (all `workflow321_` prefixed): a member with an identity
// document, created with the SDK in setUpAll; the admin is the stack's sudo
// user. Everything past setUpAll runs through the UI, but for the PDF's
// bytes, read from the store the Download button calls: opening the PDF
// would launch the desktop's viewer.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf workflow321_applications_test.dart

import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationCustomText;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider, kIdentityDocumentTag;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/editors.dart';
import '_helpers/forms.dart';
import '_helpers/navigation.dart';
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

const _kMember = 'workflow321_member';
const _kMemberPwd = 'Workflow321MemberPwd!2024';
const _kTitle = 'workflow321 Trial';
const _kFooter = 'workflow321 play fair';
const _kOrganisation = 'workflow321 Skating Club';
const _kDeclaration = 'workflow321: I declare the above is true.';

const _kApplications = 'Applications';

late Capabilities _caps;

/// The template the admin creates; set once it is created.
int? _templateId;

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

/// Saves the inline editor open in section [card]: its own Save, since the
/// State card has a Save of its own. Fails fast on an error toast.
Future<void> _saveSection(WidgetTester tester, Finder card) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: card,
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'the section editor Save',
  );
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
  final toast = firstErrorToastMessage(tester);
  if (toast != null) throw TestFailure('section save failed: "$toast"');
  await waitFor(
    tester,
    () => find
        .descendant(of: card, matching: find.widgetWithText(ShadButton, 'Save'))
        .evaluate()
        .isEmpty,
    description: 'the section editor to close once saved',
  );
}

/// The id of the template titled [_kTitle] in the master the page watches.
int _createdId(WidgetTester tester) {
  final templates = container(tester).read(clApplicationsMasterProvider);
  return templates.value!.values
      .firstWhere(
        (t) => t.content.title?.texts?['en'] == _kTitle,
      )
      .id;
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
    final admin = await _adminClient();
    try {
      await admin.users.createUser(
        username: _kMember,
        passwordHash: _kMemberPwd,
        firstName: 'Appmember',
        lastName: 'Workflow',
        phone: '7400532101',
        email: '$_kMember@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(1995, 1, 1),
      );
    } finally {
      await admin.auth.logout();
    }
    if (!_caps.applications) return;
    // Applications are offered to a member with an identity document.
    final member = await createTestClient(baseUrl: _kApiBaseUrl);
    await member.auth.login(_kMember, _kMemberPwd);
    try {
      final media = await member.media.upload(
        fileBytes: _fixturePng,
        filename: 'workflow321-document.png',
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
      }
      await admin.users.deleteUser(_kMember);
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('an admin publishes an application and a member downloads '
      'their form', (tester) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    // 1. The admin creates a draft from Applications.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
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
    expect(
      find.byKey(const ValueKey('application.state.missing')),
      findsOneWidget,
      reason: 'a new draft lacks its declaration and footer line',
    );
    expect(tester.widget<ActionButton>(_step('save')).enabled, isFalse);

    // 2. It writes the organisation and the footer line, the first and last
    // texts of the heading section.
    await tapSectionPencil(tester, _section('heading'));
    final inputs = find.descendant(
      of: _section('heading'),
      matching: find.byType(EditableText),
    );
    await tester.enterText(inputs.first, _kOrganisation);
    await tester.enterText(inputs.last, _kFooter);
    await tester.pump();
    await _saveSection(tester, _section('heading'));

    // 3. And the declaration, written for this application.
    await tapSectionPencil(tester, _section('declaration'));
    // The section's own form: the outermost one inside its card.
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
    await _saveSection(tester, _section('declaration'));
    await waitFor(
      tester,
      () => find
          .byKey(const ValueKey('application.state.missing'))
          .evaluate()
          .isEmpty,
      description: 'nothing missing before Save',
    );

    // 4. Save decides the layout; Publish shows it to members.
    await _run(tester, 'save');
    await _run(tester, 'publish');
    expect(
      find.text('Layout: decided when the application is saved'),
      findsNothing,
      reason: 'a saved application shows the layout the server stored',
    );
    expect(find.textContaining('Layout: '), findsOneWidget);
    await waitFor(
      tester,
      () => tester.widget<ActionButton>(_step('unpublish')).enabled,
      description: 'the application to be published',
    );
    _templateId = _createdId(tester);
    await logout(tester);

    // 5. The member finds it under Applications, with Download.
    await loginViaUi(tester, _kMember, _kMemberPwd);
    await _openApplications(tester);
    await waitFor(
      tester,
      () => find.text(_kTitle).evaluate().isNotEmpty,
      description: 'the published application in the member list',
    );
    final row = find.byKey(ValueKey('application.download.$_templateId'));
    expect(
      find.descendant(
        of: row,
        matching: find.widgetWithText(ShadButton, 'Download'),
      ),
      findsOneWidget,
    );
    // The bytes the Download button would open.
    final bytes = await container(
      tester,
    ).read(clApplicationsMasterProvider.notifier).downloadOwnForm(_templateId!);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(find.textContaining('Not eligible'), findsNothing);
    await logout(tester);

    // 6. The admin unpublishes and deletes it from the editor.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await _openApplications(tester);
    final card = find.byKey(ValueKey('application.row.$_templateId'));
    await waitFor(
      tester,
      () => card.evaluate().isNotEmpty,
      description: 'the application in the admin list',
    );
    await tapVisible(tester, card);
    await settle(tester);
    await _run(tester, 'unpublish');
    await _run(tester, 'delete');
    // The confirmation's own Delete is the last one on the page.
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

  testWidgets('with applications off no Applications entry appears', (
    tester,
  ) async {
    if (skipIf(enabled: _caps.applications, feature: 'applications')) return;
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await waitFor(
      tester,
      () =>
          find.byType(SidebarItem).evaluate().isNotEmpty ||
          find.byTooltip('Open menu').evaluate().isNotEmpty,
      description: 'the member zone',
    );
    final menu = find.byTooltip('Open menu');
    if (find.byType(SidebarItem).evaluate().isEmpty) {
      await tapVisible(tester, menu.first);
      await settle(tester);
    }
    expect(find.widgetWithText(SidebarItem, _kApplications), findsNothing);
    await closeDrawer(tester);
    await logout(tester);
  });
}

/// A valid 32x32 PNG, the identity document (the same fixture as
/// workflow3's: the server converts it to WebP, so it must be well formed).
const List<int> _fixturePng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x20,
  0x00,
  0x00,
  0x00,
  0x20,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0xFC,
  0x18,
  0xED,
  0xA3,
  0x00,
  0x00,
  0x00,
  0x2B,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0xDA,
  0xED,
  0xCD,
  0x41,
  0x01,
  0x00,
  0x40,
  0x04,
  0x00,
  0x30,
  0x2E,
  0x97,
  0x60,
  0x22,
  0x8A,
  0x75,
  0x25,
  0xF8,
  0x6D,
  0x05,
  0x96,
  0xD5,
  0x13,
  0x97,
  0x5E,
  0x1C,
  0x13,
  0x08,
  0x04,
  0x02,
  0x81,
  0x40,
  0x20,
  0x10,
  0x08,
  0x04,
  0x5B,
  0x3E,
  0x8D,
  0x39,
  0x01,
  0xBC,
  0xB1,
  0xB2,
  0x4F,
  0x45,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
