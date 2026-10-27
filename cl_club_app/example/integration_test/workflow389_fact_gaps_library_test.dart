// workflow389: the club's library texts and the `{fact}` gaps check
// (club_client#389, club_server#126).
//
// With applications on: the admin adds a selection to the club's Library on
// *Applications*, with a gap naming a fact the draft lacks; opens a draft
// that already uses one date-range fact in its declaration and has a
// second; inserts the club text into the selections, as written, gaps
// included; sees the State card list the gap naming no fact and Save
// greyed out; adds the fact under Facts; saves. The saved template keeps
// every gap, so each date-range fact prints in its own section, and its
// preview downloads as a PDF. The admin then reverts and deletes the draft
// and deletes the library text, through the UI.
//
// Fixtures (all `workflow389` prefixed): the draft, created with the SDK in
// setUpAll; the admin is the stack's sudo user. Everything past setUpAll
// runs through the UI, but for the texts of the dialog's kind and text
// fields, set on its form as workflow321 does, and the PDF's bytes, read
// from the store.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//     workflow389_fact_gaps_library_test.dart

import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationClauseKind, ApplicationCustomText;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationLibraryMasterProvider, clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' hide ApplicationClauseKind;
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

const _kTitle = 'workflow389 Season';
const _kDeclaration =
    'workflow389: I will play the matches from {match_dates}.';
const _kTextName = 'workflow389 Practice';
const _kText =
    'workflow389: I will attend practice from {practice_dates} '
    'at {venue}.';
const _kVenue = 'workflow389 Rink';

const _kApplications = 'Applications';

late Capabilities _caps;

/// The draft created in setUpAll.
int? _templateId;

Future<SecureClient> _adminClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// The step of the State card named [name] (`save`, `revert`, …).
Finder _step(String name) => find.byKey(ValueKey('application.step.$name'));

/// The section card of the editor named [name] (`facts`, …).
Finder _section(String name) =>
    find.byKey(ValueKey('application.section.$name'));

/// The State card's list of gaps naming no fact.
final Finder _unknownFacts = find.byKey(
  const ValueKey('application.state.unknownFacts'),
);

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

/// The EditableTexts inside section [card], in order.
Finder _inputsOf(Finder card) =>
    find.descendant(of: card, matching: find.byType(EditableText));

/// The id of the library text named [_kTextName] in the master the page
/// watches.
int _libraryTextId(WidgetTester tester) => container(tester)
    .read(clApplicationLibraryMasterProvider)
    .value!
    .values
    .firstWhere((t) => t.name == _kTextName)
    .id;

/// Confirms the ConfirmDialog that [label] opened: its own button is the
/// last one with that label on the page.
Future<void> _confirm(WidgetTester tester, String label) async {
  final confirm = find.widgetWithText(ShadButton, label);
  await waitFor(
    tester,
    () => confirm.evaluate().length > 1,
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
    if (!_caps.applications) return;
    // A draft complete but for the gap the club text brings: two
    // date-range facts, the matches' already used by the declaration.
    final today = DateTime.now().toUtc();
    final day = DateTime.utc(today.year, today.month, today.day);
    final admin = await _adminClient();
    try {
      final template = await admin.applications.createApplication(
        ApplicationContent(
          title: const ApplicationText({'en': _kTitle}),
          organisation: const ApplicationText({'en': 'workflow389 Club'}),
          declaration: const ApplicationText({'en': _kDeclaration}),
          formFooter: const ApplicationText({'en': 'workflow389 play fair'}),
          facts: {
            'match_dates': ApplicationFact.dateRange(
              day.add(const Duration(days: 30)),
              day.add(const Duration(days: 40)),
            ),
            'practice_dates': ApplicationFact.dateRange(
              day.add(const Duration(days: 10)),
              day.add(const Duration(days: 20)),
            ),
          },
        ),
      );
      _templateId = template.id;
    } finally {
      await admin.auth.logout();
    }
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
      for (final text in await admin.applications.listLibraryTexts()) {
        if (text.name.startsWith('workflow389')) {
          await admin.applications.deleteLibraryText(text.id);
        }
      }
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('an admin pastes a club library text with a gap, adds the '
      'fact it names and saves', (tester) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    // 1. The admin adds a selection to the club's Library.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
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
    final library = find.byKey(const ValueKey('application.library'));
    final add = find.descendant(
      of: library,
      matching: find.widgetWithText(ShadButton, 'Add text'),
    );
    await waitFor(
      tester,
      () =>
          add.evaluate().isNotEmpty &&
          tester.widget<ShadButton>(add).onPressed != null,
      description: 'the Library section with Add text',
    );
    invokeShadButton(tester, add, reason: 'Add text');
    await settle(tester);
    await waitFor(
      tester,
      () => find
          .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'name')
          .evaluate()
          .isNotEmpty,
      description: 'the Add text dialog',
    );
    await enterTextById(tester, 'name', _kTextName);
    final dialogForm = find.ancestor(
      of: find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == 'name',
      ),
      matching: find.byType(ShadForm),
    );
    tester.state<ShadFormState>(dialogForm.first).setValue({
      'kind': ApplicationClauseKind.selection,
      'text': const ApplicationCustomText({'en': _kText}),
    });
    await tester.pump();
    invokeShadButton(
      tester,
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.widgetWithText(ShadButton, 'Save'),
      ),
      reason: 'Add text dialog Save',
    );
    await settle(tester);
    await waitFor(
      tester,
      () =>
          find.byType(ShadDialog).evaluate().isEmpty &&
          find
              .descendant(of: library, matching: find.text(_kTextName))
              .evaluate()
              .isNotEmpty,
      description: 'the new text in the Library section',
    );
    final textId = _libraryTextId(tester);

    // 2. It opens the draft and pastes the club text into the selections.
    final row = find.byKey(ValueKey('application.row.$_templateId'));
    await waitFor(
      tester,
      () => row.evaluate().isNotEmpty,
      description: 'the draft in the admin list',
    );
    await tapVisible(tester, row);
    await settle(tester);
    await waitFor(
      tester,
      () => _step('save').evaluate().isNotEmpty,
      description: 'the draft to open in the editor',
    );
    expect(_unknownFacts, findsNothing, reason: 'every gap names a fact');
    await tapSectionPencil(tester, _section('selections'));
    final clubRow = find.descendant(
      of: _section('selections'),
      matching: find.byKey(ValueKey<String>('club.$textId')),
    );
    await waitFor(
      tester,
      () => clubRow.evaluate().isNotEmpty,
      description: "the club's text in the selections' library",
    );
    expect(
      find.descendant(of: clubRow, matching: find.textContaining(_kTextName)),
      findsOneWidget,
      reason: "a club text is marked as the club's, with its name",
    );
    tester
        .widget<GestureDetector>(
          find
              .descendant(of: clubRow, matching: find.byType(GestureDetector))
              .first,
        )
        .onTap!();
    await tester.pump();
    expect(
      find.descendant(
        of: _section('selections'),
        matching: find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == _kText,
        ),
      ),
      findsOneWidget,
      reason: 'the text is pasted as written, its gaps included',
    );
    await _saveSection(tester, _section('selections'));

    // 3. The State card lists the gap naming no fact; Save is off.
    await waitFor(
      tester,
      () => _unknownFacts.evaluate().isNotEmpty,
      description: 'the gaps naming no fact',
    );
    expect(
      find.descendant(
        of: _unknownFacts,
        matching: find.textContaining(
          'Selection 1 (English): no fact named venue',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.widget<ActionButton>(_step('save')).enabled, isFalse);

    // 4. It adds the fact under Facts, a name.
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
    final inputs = _inputsOf(_section('facts'));
    await tester.enterText(inputs.at(before), 'venue');
    await tester.enterText(inputs.at(before + 1), _kVenue);
    await tester.pump();
    await _saveSection(tester, _section('facts'));
    await waitFor(
      tester,
      () => _unknownFacts.evaluate().isEmpty,
      description: 'no gap naming no fact once the fact is added',
    );

    // 5. Save: the saved template keeps every gap, each date-range fact in
    // its own section, and its preview is a PDF.
    await _run(tester, 'save');
    await waitFor(
      tester,
      () =>
          _step('revert').evaluate().isNotEmpty &&
          tester.widget<ActionButton>(_step('revert')).enabled,
      description: 'the draft to be saved',
    );
    final saved = container(
      tester,
    ).read(clApplicationsMasterProvider).value![_templateId]!;
    expect(saved.status, ApplicationStatus.saved);
    expect(saved.content.declaration?.texts['en'], _kDeclaration);
    expect(saved.content.selections.single.texts['en'], _kText);
    expect(saved.content.facts.keys, contains('venue'));
    final bytes = await container(
      tester,
    ).read(clApplicationsMasterProvider.notifier).downloadPreview(_templateId!);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    // 6. Cleanup through the UI: revert and delete the draft, then delete
    // the library text.
    await _run(tester, 'revert');
    await _run(tester, 'delete');
    await _confirm(tester, 'Delete');
    await waitFor(
      tester,
      () => row.evaluate().isEmpty && find.text(_kTitle).evaluate().isEmpty,
      description: 'the deleted draft to leave the list',
    );
    final card = find.byKey(ValueKey('application.library.$textId'));
    await waitFor(
      tester,
      () => card.evaluate().isNotEmpty,
      description: 'the library text on the Applications page',
    );
    invokeShadButton(
      tester,
      find.descendant(
        of: card,
        matching: find.widgetWithText(ShadButton, 'Delete'),
      ),
      reason: 'the library text Delete',
    );
    await settle(tester);
    await _confirm(tester, 'Delete');
    await waitFor(
      tester,
      () => card.evaluate().isEmpty,
      description: 'the deleted text to leave the Library',
    );
    await logout(tester);
  });
}
