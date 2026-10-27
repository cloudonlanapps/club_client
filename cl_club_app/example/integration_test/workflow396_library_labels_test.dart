// workflow396: every library text and every label is the club's
// (club_client#396, club_server#133).
//
// With applications on: on *Club details* the admin finds a built-in clause
// the server seeded into the club's Library, listed like any text, renames
// it in place and renames it back; then, in the Labels card after the
// Library, writes a label's translation in the club's second language and
// writes it back as it was.
//
// Fixtures: none are created. The seeded clause and the label are read with
// the SDK in setUpAll, and tearDownAll puts back what they held if the UI
// did not get to (`workflow396` marks what the test writes). Everything
// past setUpAll runs through the UI.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//     workflow396_library_labels_test.dart

import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show applicationLabelsProvider, clApplicationLibraryMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

const _kClubDetails = 'Club details';
const _kApplications = 'Applications';

/// The seeded clause's name while the test holds it.
const _kRenamed = 'workflow396 seeded clause';

/// The label's translation while the test holds it.
const _kTranslation = 'workflow396 translation';

/// The label the test translates, when the server has it.
const _kPreferredLabel = 'field.full_name';

late Capabilities _caps;

/// The seeded clause, as it was.
ApplicationLibraryText? _seeded;

/// The label's key and its text, as it was.
String? _labelKey;
Map<String, String> _labelText = const {};

/// The club's language after English that the label is translated into.
String? _language;

Future<SecureClient> _adminClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// The Club details page's scrolling list.
Finder get _list => find
    .descendant(
      of: find.byKey(const ValueKey('clubIdentity.list')),
      matching: find.byType(Scrollable),
    )
    .first;

/// Scrolls the field [id] of the open editor into view, then types [text]
/// into it: below the fold `enterText` silently misses.
Future<void> _enter(WidgetTester tester, String id, String text) async {
  final field = find.byWidgetPredicate(
    (w) => w is ShadFormBuilderField && w.id == id,
    description: 'form field "$id"',
  );
  await tester.scrollUntilVisible(field, 200, scrollable: _list);
  await tester.pump();
  await enterTextById(tester, id, text);
}

/// Saves the inline editor open in [card]: its own Save, as other cards on
/// the page have theirs. Fails fast on an error toast, then waits for the
/// editor to close.
Future<void> _saveIn(WidgetTester tester, Finder card) async {
  final save = find.descendant(
    of: card,
    matching: find.widgetWithText(ShadButton, 'Save'),
  );
  invokeShadButton(tester, save, reason: 'the card editor Save');
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
  final toast = firstErrorToastMessage(tester);
  if (toast != null) throw TestFailure('save failed: "$toast"');
  await waitFor(
    tester,
    () => save.evaluate().isEmpty,
    description: 'the card editor to close once saved',
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
    if (!_caps.applications) return;
    final admin = await _adminClient();
    try {
      final texts = await admin.applications.listLibraryTexts();
      _seeded = texts.firstWhere(
        (t) => t.key != null,
        orElse: () => throw StateError('the library holds no seeded clause'),
      );
      final labels = await admin.applications.getLabels();
      _labelKey = labels.labels.containsKey(_kPreferredLabel)
          ? _kPreferredLabel
          : labels.labels.keys.first;
      _labelText = Map.of(labels.labels[_labelKey]!);
      _language = labels.languages.firstWhere(
        (code) => code != 'en',
        orElse: () => throw StateError('the club has one language only'),
      );
    } finally {
      await admin.auth.logout();
    }
  });

  tearDownAll(() async {
    if (!_caps.applications) return;
    final admin = await _adminClient();
    try {
      // Only when the UI did not put them back.
      final seeded = _seeded;
      if (seeded != null) {
        final now = (await admin.applications.listLibraryTexts()).where(
          (t) => t.id == seeded.id,
        );
        if (now.isNotEmpty && now.single.name != seeded.name) {
          await admin.applications.updateLibraryText(
            seeded.id,
            ApplicationLibraryTextPatch(name: seeded.name),
          );
        }
      }
      final key = _labelKey;
      if (key != null) {
        final now = (await admin.applications.getLabels()).labels[key];
        if (now?[_language] != _labelText[_language]) {
          await admin.applications.updateLabel(
            key,
            ApplicationText(_labelText),
          );
        }
      }
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('a seeded clause is edited on Club details like any library '
      'text, and a label is translated in the Labels card', (tester) async {
    if (skipUnless(enabled: _caps.applications, feature: 'applications')) {
      return;
    }
    final seeded = _seeded!;
    final key = _labelKey!;
    final language = _language!;
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await waitFor(
      tester,
      () =>
          find
              .widgetWithText(SidebarItem, _kApplications)
              .evaluate()
              .isNotEmpty ||
          find.byTooltip('Open menu').evaluate().isNotEmpty,
      description: 'the member zone sidebar',
    );
    await openSidebarEntry(tester, _kClubDetails);

    // 1. The seeded clause is in the Library, renamed and renamed back.
    final card = find.byKey(ValueKey('application.library.${seeded.id}'));
    await waitFor(
      tester,
      () => card.evaluate().isNotEmpty,
      description: 'the seeded clause in the Library card',
    );
    expect(
      find.descendant(of: card, matching: find.text(seeded.name)),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.widgetWithText(ShadButton, 'Delete'),
      ),
      findsOneWidget,
      reason: 'a seeded text is deletable like any other',
    );
    String? nameNow() => container(
      tester,
    ).read(clApplicationLibraryMasterProvider).value?[seeded.id]?.name;

    await tapSectionPencil(tester, card);
    await _enter(tester, 'name', _kRenamed);
    await _saveIn(tester, card);
    await waitFor(
      tester,
      () => nameNow() == _kRenamed,
      description: 'the renamed clause in the library',
    );
    expect(
      find.descendant(of: card, matching: find.text(_kRenamed)),
      findsWidgets,
    );

    await tapSectionPencil(tester, card);
    await _enter(tester, 'name', seeded.name);
    await _saveIn(tester, card);
    await waitFor(
      tester,
      () => nameNow() == seeded.name,
      description: 'the clause renamed back',
    );

    // 2. A label's translation, written and written back.
    final labels = find.byKey(const ValueKey('application.labels'));
    final label = find.byKey(ValueKey('application.labels.$key'));
    await waitFor(
      tester,
      () => labels.evaluate().isNotEmpty && label.evaluate().isNotEmpty,
      description: 'the label in the Labels card',
    );
    String? translationNow() => container(
      tester,
    ).read(applicationLabelsProvider).value?.labels[key]?[language];

    await tapSectionPencil(tester, label);
    await _enter(tester, 'text_$language', _kTranslation);
    await _saveIn(tester, label);
    await waitFor(
      tester,
      () => translationNow() == _kTranslation,
      description: 'the translation stored',
    );
    expect(
      find.descendant(of: label, matching: find.text(_kTranslation)),
      findsOneWidget,
    );

    final original = _labelText[language] ?? '';
    await tapSectionPencil(tester, label);
    await _enter(tester, 'text_$language', original);
    await _saveIn(tester, label);
    await waitFor(
      tester,
      () => (translationNow() ?? '') == original,
      description: 'the translation written back',
    );
    await logout(tester);
  });
}
