// workflow400: an application carried as a JSON file (club_client#400;
// covers #398).
//
// With applications on: the admin creates a draft on *Applications*,
// writes what Finalize needs (organisation, footer line, a fact and a
// declaration naming it), finalizes and publishes it, and exports it with
// Export JSON at the foot of the editor. It then unpublishes, reverts and
// deletes it through the heading card, and imports the exported file with
// Import JSON beside Create application: a new draft opens in the editor
// with the same texts and facts.
//
// The save and the pick are the desktop's file dialogs on Linux, so the
// test stands in for them (`debugSaveFileBytes`, `debugPickJsonFile`,
// cl_club_app), capturing the exported bytes and handing them back.
//
// Fixtures (all `workflow400` prefixed): the application, created and
// deleted through the UI (tearDownAll deletes any left over). The admin is
// the stack's sudo user.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow400_application_json_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cl_club_app/src/utils/pick_json_file.dart'
    show debugPickJsonFile;
import 'package:cl_club_app/src/utils/save_file_bytes.dart'
    show debugSaveFileBytes;
import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationCustomText;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '_helpers/applications.dart';
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

const _kTitle = 'workflow400 Trial';
const _kOrganisation = 'workflow400 Skating Club';
const _kFooter = 'workflow400 play fair';
const _kVenue = 'workflow400 Rink';
const _kDeclaration = 'workflow400: I attend the trial at {venue}.';

const _kApplications = 'Applications';

late Capabilities _caps;

/// What Export JSON handed the save: the file name and its bytes.
final List<(String, Uint8List)> _saved = [];

Future<SecureClient> _adminClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// The section card of the editor named [name] (`heading`, …).
Finder _section(String name) =>
    find.byKey(ValueKey('application.section.$name'));

/// The EditableTexts inside section [card], in order.
Finder _inputsOf(Finder card) =>
    find.descendant(of: card, matching: find.byType(EditableText));

/// Saves the inline editor open in section [card]: its own Save. Fails
/// fast on an error toast.
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

/// The templates titled [_kTitle] the page's master holds.
List<ApplicationTemplate> _ours(WidgetTester tester) => [
  for (final t
      in container(tester).read(clApplicationsMasterProvider).value?.values ??
          const <ApplicationTemplate>[])
    if (t.content.title?.texts['en'] == _kTitle) t,
];

/// Opens the admin's *Applications* list under Club Management.
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
  await openSidebarEntry(tester, _kApplications, last: true);
}

/// Confirms the open dialog with its [label] button.
Future<void> _confirm(WidgetTester tester, String label) async {
  final confirm = find.descendant(
    of: find.byType(ShadDialog),
    matching: find.widgetWithText(ShadButton, label),
  );
  await waitFor(
    tester,
    () => confirm.evaluate().isNotEmpty,
    description: 'the "$label" confirmation',
  );
  tester.widget<ShadButton>(confirm.last).onPressed!();
  await settle(tester);
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
  });

  setUp(() {
    _saved.clear();
    debugSaveFileBytes = (name, bytes) async {
      _saved.add((name, bytes));
      return true;
    };
  });

  tearDown(() {
    debugSaveFileBytes = null;
    debugPickJsonFile = null;
  });

  tearDownAll(() async {
    if (!_caps.applications) return;
    final admin = await _adminClient();
    try {
      // Only when the UI cleanup did not run to the end.
      final left = await admin.applications.listApplications(limit: 100);
      for (final t in left.items) {
        if (t.content.title?.texts['en'] != _kTitle) continue;
        if (t.status == ApplicationStatus.published) {
          await admin.applications.unpublishApplication(t.id);
        }
        if (t.status != ApplicationStatus.draft) {
          await admin.applications.revertApplication(t.id);
        }
        await admin.applications.deleteApplication(t.id);
      }
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('an admin exports a published application as JSON, deletes '
      'it and imports the file as a new draft', (tester) async {
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
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.widgetWithText(ShadButton, 'Save'),
      ),
      reason: 'create dialog Save',
    );
    await settle(tester);
    await waitFor(
      tester,
      () => applicationStep('save').evaluate().isNotEmpty,
      description: 'the new draft to open in the editor',
    );
    expect(find.text('$_kTitle (Draft)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('application.exportJson')),
      findsNothing,
      reason: 'a draft is not exported',
    );

    // 2. What Finalize needs: the organisation and the footer line, a
    // fact, and a declaration naming it.
    await tapSectionPencil(tester, _section('heading'));
    final heading = _inputsOf(_section('heading'));
    await tester.enterText(heading.first, _kOrganisation);
    await tester.enterText(heading.last, _kFooter);
    await tester.pump();
    await _saveSection(tester, _section('heading'));

    await tapSectionPencil(tester, _section('facts'));
    final before = _inputsOf(_section('facts')).evaluate().length;
    invokeShadButton(
      tester,
      find.descendant(
        of: _section('facts'),
        matching: find.widgetWithText(ShadButton, 'Add fact'),
      ),
      reason: 'Add fact',
    );
    await settle(tester);
    await waitFor(
      tester,
      () => _inputsOf(_section('facts')).evaluate().length >= before + 2,
      description: "the new fact's inputs",
    );
    final facts = _inputsOf(_section('facts'));
    await tester.enterText(facts.at(before), 'venue');
    await tester.enterText(facts.at(before + 1), _kVenue);
    await tester.pump();
    await _saveSection(tester, _section('facts'));

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
      () =>
          find
              .byKey(const ValueKey('application.state.missing'))
              .evaluate()
              .isEmpty &&
          find
              .byKey(const ValueKey('application.state.unknownFacts'))
              .evaluate()
              .isEmpty,
      description: 'nothing blocking Finalize',
    );

    // 3. Finalize, then Publish.
    await runApplicationStep(tester, 'save');
    await runApplicationStep(tester, 'publish');
    await waitFor(
      tester,
      () => applicationStepEnabled(tester, 'unpublish'),
      description: 'the application to be published',
    );
    expect(find.text('$_kTitle (Published)'), findsOneWidget);
    final published = _ours(tester).single;

    // 4. Export JSON, at the foot of the editor, saves the content file.
    final export = find.byKey(const ValueKey('application.exportJson'));
    await waitFor(
      tester,
      () => export.evaluate().isNotEmpty,
      description: 'Export JSON on the published application',
    );
    invokeShadButton(tester, export, reason: 'Export JSON');
    await settle(tester);
    await waitFor(
      tester,
      () => _saved.isNotEmpty,
      description: 'the exported file handed to the save',
    );
    expect(_saved.single.$1, '$_kTitle.json');
    final file =
        jsonDecode(utf8.decode(_saved.single.$2)) as Map<String, dynamic>;
    expect(file['format'], 'club.application');
    expect(file['version'], 1);
    expect(
      ApplicationContent.fromMap(file['content'] as Map<String, dynamic>),
      published.content,
      reason: 'the file holds the published content',
    );
    final bytes = _saved.single.$2;

    // 5. Unpublish, Revert to draft and Delete (a bin icon, confirmed).
    await runApplicationStep(tester, 'unpublish');
    await runApplicationStep(tester, 'revert');
    await runApplicationStep(tester, 'delete');
    await _confirm(tester, 'Delete');
    final oldRow = find.byKey(ValueKey('application.row.${published.id}'));
    await waitFor(
      tester,
      () => oldRow.evaluate().isEmpty && find.text(_kTitle).evaluate().isEmpty,
      description: 'the deleted application to leave the list',
    );

    // 6. Import JSON, beside Create application, picks the exported file
    // and opens a new draft with the same texts and facts.
    debugPickJsonFile = () async => bytes;
    final import = find.byKey(const ValueKey('application.importJson'));
    await waitFor(
      tester,
      () => import.evaluate().isNotEmpty,
      description: 'the Import JSON button',
    );
    invokeShadButton(tester, import, reason: 'Import JSON');
    await settle(tester);
    await waitFor(
      tester,
      () => find.text('$_kTitle (Draft)').evaluate().isNotEmpty,
      description: 'the imported draft to open in the editor',
    );
    final imported = _ours(tester).single;
    expect(imported.id, isNot(published.id));
    expect(imported.status, ApplicationStatus.draft);
    expect(imported.content, published.content);
    expect(
      imported.content.facts['venue'],
      const ApplicationFact.name(_kVenue),
    );
    for (final text in [_kOrganisation, _kFooter, _kVenue]) {
      expect(
        find.textContaining(text),
        findsWidgets,
        reason: '"$text" reads in the imported draft',
      );
    }
    expect(applicationStepEnabled(tester, 'save'), isTrue);

    // 7. Cleanup through the UI: Delete the imported draft.
    await runApplicationStep(tester, 'delete');
    await _confirm(tester, 'Delete');
    await waitFor(
      tester,
      () => find
          .byKey(ValueKey('application.row.${imported.id}'))
          .evaluate()
          .isEmpty,
      description: 'the imported draft to leave the list',
    );
    await logout(tester);
  });
}
