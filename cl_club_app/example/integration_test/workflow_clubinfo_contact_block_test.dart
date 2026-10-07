// workflow_clubinfo: the club details screen (club_core#20).
//
// A super-admin (`sudo`), from the sidebar's Admin section:
//
//   * sees the stored club_info (seeded through the SDK with keys the
//     forms do not edit, in the document and in its contact block) in three
//     section cards — Club, Contact, Address — none of them open for
//     editing;
//   * opens Contact and enters a phone that is not E.164 — Save is refused
//     in place and nothing is written;
//   * fixes it and saves Contact; adds a language code in the
//     Translations card, which writes nothing; opens Club, fills the short
//     name, the inquiry email and the tagline with a translation in that
//     language, and saves; opens Address, fills the city, and saves — each
//     section on its own (club_client#58);
//   * finds the document written as the website and the server read it
//     (the public club info), the unedited keys carried through;
//   * opens Contact us and finds the saved phone and city there: the app
//     reads the edit without a restart (club_core#53);
//   * clears what it filled, section by section, which is the UI cleanup:
//     those fields are gone from the document again, and Contact us falls
//     back to the bundled city while keeping the server's phone.
//
// The original club_info is put back through the SDK at the end (a
// never-written club_info reads null, which the server will not store, so
// that case restores `{}`).
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_clubinfo_contact_block_test.dart

import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart' show secureClientProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show SecureClient;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '_helpers/auth.dart';
import '_helpers/forms.dart';
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

const _kPreference = 'club_info';
const _kName = 'workflow_clubinfo Club';

/// The example app's bundled `assets/data/contact_info.json` address.
const _kBundledCity = 'Example City';
const _kBundledStatePostal = 'Example State, 000000';

/// The language the test adds in the Translations card.
const _kLanguage = 'mr';

/// What the test seeds: a name, a phone, and keys the forms do not edit.
const Map<String, dynamic> _kSeed = {
  'name': _kName,
  'workflow_clubinfo_extra': {'kept': true},
  'contact': {
    'phoneNumber': '+10000000000',
    'workflow_clubinfo_note': 'kept',
  },
};

/// The three section cards of the club details screen.
const Key _kClubSection = ValueKey('clubIdentity.section.club');
const Key _kContactSection = ValueKey('clubIdentity.section.contact');
const Key _kAddressSection = ValueKey('clubIdentity.section.address');

Finder _field(String id) => find.byKey(ValueKey('clubIdentity.$id'));

Finder get _list => find
    .descendant(
      of: find.byKey(const ValueKey('clubIdentity.list')),
      matching: find.byType(Scrollable),
    )
    .first;

/// Scroll [id]'s input into view, then type [text] into it.
Future<void> _enter(WidgetTester tester, String id, String text) async {
  await tester.scrollUntilVisible(_field(id), 200, scrollable: _list);
  await tester.enterText(
    find.descendant(of: _field(id), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
}

Future<void> _press(WidgetTester tester, String key) async {
  invokeShadButton(tester, find.byKey(ValueKey(key)), reason: key);
  await settle(tester);
}

/// Opens [section] for editing, as a tap on its pencil would, and waits
/// for [firstFieldId]'s input.
Future<void> _edit(
  WidgetTester tester,
  Key section,
  String firstFieldId,
) async {
  final pencil = find.descendant(
    of: find.byKey(section),
    matching: find.byType(SectionEditButton),
  );
  expect(pencil, findsOneWidget, reason: 'the pencil of $section');
  tester.widget<SectionEditButton>(pencil).onTap();
  await settle(tester);
  await waitFor(
    tester,
    () => _field(firstFieldId).evaluate().isNotEmpty,
    description: '$section to open for editing',
  );
}

/// Presses Save in [section].
Future<void> _pressSave(WidgetTester tester, Key section) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byKey(section),
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'Save of $section',
  );
  await settle(tester);
}

/// Presses Save in [section] and waits for it to leave edit mode, which it
/// does once the section is stored: [firstFieldId]'s input is gone.
Future<void> _save(
  WidgetTester tester,
  Key section,
  String firstFieldId,
) async {
  await _pressSave(tester, section);
  await waitFor(
    tester,
    () => _field(firstFieldId).evaluate().isEmpty,
    description: 'the save of $section to finish',
  );
}

/// Opens the sidebar entry [label], as a tap on it would.
Future<void> _openFromSidebar(WidgetTester tester, String label) async {
  final entry = find.widgetWithText(SidebarItem, label);
  expect(entry, findsWidgets, reason: label);
  tester.widget<SidebarItem>(entry.first).onTap();
  await settle(tester);
}

/// Opens Contact us and waits for [text] on it.
Future<void> _expectOnContactScreen(WidgetTester tester, String text) async {
  await _openFromSidebar(tester, 'Contact us');
  await waitFor(
    tester,
    () => find.text(text).evaluate().isNotEmpty,
    description: '"$text" on the contact screen',
  );
}

/// Opens Club details and waits for the stored club name in the Club card.
Future<void> _openClubDetails(WidgetTester tester) async {
  await _openFromSidebar(tester, 'Club details');
  await waitFor(
    tester,
    () => find.text(_kName).evaluate().isNotEmpty,
    description: 'the stored club name in the Club card',
  );
}

Future<Map<String, dynamic>> _stored(SecureClient client) async {
  final value = (await client.admin.getPreference(_kPreference)).value;
  return value is Map ? Map<String, dynamic>.from(value) : {};
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'a super-admin edits the club details and the website reads them',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await go(tester, '/memberzone/profile');

      final client = await container(tester).read(secureClientProvider.future);
      final original = (await client.admin.getPreference(_kPreference)).value;
      // Put the original back while the app (and its client) is still up;
      // a tearDown runs after the tree, and the client's network-status
      // notifier, are disposed.
      try {
        await client.admin.setPreference(_kPreference, _kSeed);

        // --- Open the screen from the sidebar's Admin section. --------------
        await _openClubDetails(tester);
        // Three sections, each read-only until its pencil is tapped.
        for (final section in [
          _kClubSection,
          _kContactSection,
          _kAddressSection,
        ]) {
          expect(find.byKey(section), findsOneWidget, reason: '$section');
        }
        expect(_field('name'), findsNothing);
        expect(_field('phoneNumber'), findsNothing);
        expect(find.widgetWithText(ShadButton, 'Save'), findsNothing);

        // --- A phone that is not E.164 is refused in place. -----------------
        await _edit(tester, _kContactSection, 'phoneNumber');
        await _enter(tester, 'phoneNumber', '98765 43210');
        await _pressSave(tester, _kContactSection);
        expect(find.textContaining('international format'), findsOneWidget);
        expect((await _stored(client))['contact'], _kSeed['contact']);

        // --- Fill in and save, one section at a time. -----------------------
        await _enter(tester, 'phoneNumber', '+919876543210');
        await _save(tester, _kContactSection, 'phoneNumber');
        // Contact alone was written: the rest is as seeded.
        final afterContact = await _stored(client);
        expect(afterContact.containsKey('shortName'), isFalse);
        expect(afterContact['contact'], {
          ...(_kSeed['contact'] as Map<String, dynamic>),
          'phoneNumber': '+919876543210',
        });

        // Adding a language writes nothing; the tagline then takes a text
        // in it.
        await _enter(tester, 'addLanguage', _kLanguage);
        await _press(tester, 'clubIdentity.addLanguage.add');
        expect(await _stored(client), afterContact);

        await _edit(tester, _kClubSection, 'name');
        await waitFor(
          tester,
          () => _field('tagline@$_kLanguage').evaluate().isNotEmpty,
          description: 'the tagline input in the added language',
        );
        await _enter(tester, 'shortName', 'WFC');
        await _enter(tester, 'inquiryEmail', 'workflow_clubinfo@example.com');
        await _enter(tester, 'tagline', 'workflow_clubinfo tagline');
        await _enter(
          tester,
          'tagline@$_kLanguage',
          'workflow_clubinfo tagline mr',
        );
        await _save(tester, _kClubSection, 'name');

        await _edit(tester, _kAddressSection, 'city');
        await _enter(tester, 'city', 'workflow_clubinfo city');
        await _save(tester, _kAddressSection, 'city');

        // --- The website's read carries the document as written. ------------
        var published = (await client.public.getPublicClubInfo()).clubInfo;
        expect(published['name'], _kName);
        expect(published['shortName'], 'WFC');
        expect(published['inquiryEmail'], 'workflow_clubinfo@example.com');
        expect(published['workflow_clubinfo_extra'], {'kept': true});
        expect(published['contact'], {
          'workflow_clubinfo_note': 'kept',
          'phoneNumber': '+919876543210',
          'tagline': {
            'default': 'workflow_clubinfo tagline',
            _kLanguage: 'workflow_clubinfo tagline mr',
          },
          'city': 'workflow_clubinfo city',
        });

        // --- The app reads the edit: Contact us (club_core#53). -------------
        // The server's phone and city, over the bundled block's address.
        await _expectOnContactScreen(tester, '+919876543210');
        expect(
          find.text('workflow_clubinfo city, $_kBundledStatePostal'),
          findsOneWidget,
        );

        // --- Cleanup through the UI: clear what was filled in, save. ---------
        await _openClubDetails(tester);
        await _edit(tester, _kClubSection, 'name');
        for (final id in [
          'shortName',
          'inquiryEmail',
          'tagline@$_kLanguage',
          'tagline',
        ]) {
          await _enter(tester, id, '');
        }
        await _save(tester, _kClubSection, 'name');
        await _edit(tester, _kAddressSection, 'city');
        await _enter(tester, 'city', '');
        await _save(tester, _kAddressSection, 'city');
        published = (await client.public.getPublicClubInfo()).clubInfo;
        expect(published.containsKey('shortName'), isFalse);
        expect(published.containsKey('inquiryEmail'), isFalse);
        expect(published['contact'], {
          'workflow_clubinfo_note': 'kept',
          'phoneNumber': '+919876543210',
        });

        // The city the server no longer has falls back to the bundled one.
        await _expectOnContactScreen(
          tester,
          '$_kBundledCity, $_kBundledStatePostal',
        );
        expect(find.text('+919876543210'), findsOneWidget);
      } finally {
        await client.admin.setPreference(
          _kPreference,
          original ?? <String, dynamic>{},
        );
      }
    },
  );
}
