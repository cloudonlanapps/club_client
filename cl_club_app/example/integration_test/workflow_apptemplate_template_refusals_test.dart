// workflow_apptemplate: what the application editor refuses, and where it
// says so (club_client#341; covers #321 and #114).
//
// The admin creates a draft. Before it is saved, Publish is greyed out with
// its reason, and Save too while texts are missing, which the State card
// lists. A title cleared of its English is refused on its field, and the
// draft keeps its title and stays a draft. A declaration the server refuses
// at its schema (a text in a language outside the label catalogue, which
// the editor keeps as it was given, as it keeps any language it does not
// show) shows the server's reason on the declaration field, with no toast,
// and nothing is stored. The admin then deletes the draft.
//
// Fixtures (all `workflow_apptemplate_` prefixed): the draft, created and
// deleted through the UI. The admin is the stack's sudo user.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_apptemplate_template_refusals_test.dart

import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationCustomText, ApplicationFormFields;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
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

const _kTitle = 'workflow_apptemplate Trial';
const _kApplications = 'Applications';

/// A language code outside the server's label catalogue.
const _kUnknownLanguage = 'zz';

/// What a printed text without its English is refused with
/// (`ApplicationFormStrings.englishRequired`).
const _kEnglishRequired = 'Needs text in English';

late Capabilities _caps;

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

/// The Save button of the editor open in [card].
Finder _saveIn(Finder card) => find.descendant(
  of: card,
  matching: find.widgetWithText(ShadButton, 'Save'),
);

/// The draft as the page's master holds it.
ApplicationTemplate _draft(WidgetTester tester) => container(tester)
    .read(clApplicationsMasterProvider)
    .value!
    .values
    .firstWhere((t) => t.content.title?.texts['en'] == _kTitle);

/// Presses the Save of the editor open in [card], which the editor or the
/// server refuses: it stays open, with no toast.
Future<void> _saveRefused(WidgetTester tester, Finder card) async {
  invokeShadButton(tester, _saveIn(card), reason: 'the section editor Save');
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
  expect(
    firstErrorToastMessage(tester),
    isNull,
    reason: 'a refusal about a field is never a toast',
  );
  expect(_saveIn(card), findsOneWidget, reason: 'the editor stays open');
}

/// Closes the editor open in [card] without saving.
Future<void> _cancelIn(WidgetTester tester, Finder card) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: card,
      matching: find.widgetWithText(ShadButton, 'Cancel'),
    ),
    reason: 'the section editor Cancel',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => _saveIn(card).evaluate().isEmpty,
    description: 'the section editor to close',
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
        await admin.applications.deleteApplication(t.id);
      }
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('the application editor refuses a text without English and a '
      'value the server rejects on their fields, and greys out what the '
      'draft cannot do yet', (tester) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);

    // 1. The admin creates a draft.
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
    final id = _draft(tester).id;

    // 2. Before it is saved, Publish is greyed out with its reason; so is
    // Save while texts are missing, which the State card lists.
    expect(tester.widget<ActionButton>(_step('publish')).enabled, isFalse);
    expect(find.text('Save it first'), findsOneWidget);
    expect(tester.widget<ActionButton>(_step('save')).enabled, isFalse);
    expect(find.text('2 texts missing'), findsOneWidget);
    final missing = find.byKey(const ValueKey('application.state.missing'));
    expect(missing, findsOneWidget);
    for (final place in ['Declaration', 'Footer line']) {
      expect(
        find.descendant(of: missing, matching: find.textContaining(place)),
        findsOneWidget,
        reason: '"$place" is listed as missing',
      );
    }
    expect(find.text('Draft'), findsOneWidget);

    // 3. A title cleared of its English is refused on the title field, and
    // the draft keeps its title and stays a draft.
    final heading = _section('heading');
    await tapSectionPencil(tester, heading);
    final title = find.descendant(
      of: find.byWidgetPredicate(
        (w) =>
            w is ShadFormBuilderField && w.id == ApplicationFormFields.titleId,
      ),
      matching: find.byType(EditableText),
    );
    await waitFor(
      tester,
      () => title.evaluate().isNotEmpty,
      description: 'the title input of the heading editor',
    );
    expect(title, findsOneWidget, reason: 'the title is English only');
    // The organisation, also required, is written, so the title is the one
    // text without English.
    await tester.enterText(
      find
          .descendant(
            of: find.byWidgetPredicate(
              (w) =>
                  w is ShadFormBuilderField &&
                  w.id == ApplicationFormFields.organisationId,
            ),
            matching: find.byType(EditableText),
          )
          .first,
      'workflow_apptemplate Skating Club',
    );
    await tester.enterText(title, '');
    await tester.pump();
    await _saveRefused(tester, heading);
    expect(
      find.descendant(of: heading, matching: find.text(_kEnglishRequired)),
      findsOneWidget,
      reason: 'the refusal shows on the title',
    );
    await _cancelIn(tester, heading);
    expect(_draft(tester).content.title?.texts['en'], _kTitle);
    expect(_draft(tester).status, ApplicationStatus.draft);
    expect(find.text('Draft'), findsOneWidget);
    expect(tester.widget<ActionButton>(_step('publish')).enabled, isFalse);

    // 4. A declaration the server refuses at its schema shows the server's
    // reason on the declaration field, and nothing is stored.
    final declaration = _section('declaration');
    await tapSectionPencil(tester, declaration);
    // The section's own form: the outermost one inside its card.
    tester
        .state<ShadFormState>(
          find
              .descendant(of: declaration, matching: find.byType(ShadForm))
              .first,
        )
        .setValue({
          ApplicationFormFields.declarationId: const ApplicationCustomText({
            'en': 'workflow_apptemplate: I declare the above is true.',
            _kUnknownLanguage: 'workflow_apptemplate',
          }),
        });
    await tester.pump();
    await _saveRefused(tester, declaration);
    await waitFor(
      tester,
      () => find
          .descendant(
            of: declaration,
            matching: find.textContaining('is not a language'),
          )
          .evaluate()
          .isNotEmpty,
      description: "the server's reason on the declaration field",
    );
    expect(_draft(tester).content.declaration, isNull);
    await _cancelIn(tester, declaration);
    expect(_draft(tester).status, ApplicationStatus.draft);

    // 5. Cleanup through the UI: Delete, confirmed.
    tester.widget<ActionButton>(_step('delete')).onPressed!();
    await settle(tester);
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
      () =>
          find.byKey(ValueKey('application.row.$id')).evaluate().isEmpty &&
          _step('delete').evaluate().isEmpty,
      description: 'the deleted draft to leave the list',
    );
    await logout(tester);
  });
}
