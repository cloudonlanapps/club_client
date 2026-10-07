import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard, SectionEditButton;

import 'support/admin_test_scope.dart';

const _stored = ClubIdentity(
  name: 'Example Club',
  contact: ClubContactDetails(
    phoneNumber: '+10000000000',
    city: LocalizedText('Example City', {'mr': 'Udaharan'}),
  ),
  extra: {'values': <String>[]},
);

const Key _club = ValueKey('clubIdentity.section.club');
const Key _contact = ValueKey('clubIdentity.section.contact');
const Key _address = ValueKey('clubIdentity.section.address');
const Key _translations = ValueKey('clubIdentity.section.translations');

/// The language codes [stub]'s stored identity holds a translation in.
List<String> clubIdentityLanguagesOfStored(StubClubIdentity stub) => {
  for (final value in (stub.saved.toMap()['contact'] as Map).values)
    if (value is Map) ...value.keys.cast<String>().where((k) => k != 'default'),
}.toList();

Future<StubClubIdentity> _pump(
  WidgetTester tester, {
  ClubIdentity saved = _stored,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = StubClubIdentity(saved);
  await tester.pumpWidget(
    adminScope(
      overrides: [clClubIdentityMasterProvider.overrideWith(() => stub)],
      child: ClubIdentityView(currentUser: adminViewer(superAdmin: true)),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

Finder _field(String id) => find.byKey(ValueKey('clubIdentity.$id'));

Finder _input(String id) =>
    find.descendant(of: _field(id), matching: find.byType(EditableText));

Finder _in(Key section, Finder matching) =>
    find.descendant(of: find.byKey(section), matching: matching);

/// The inputs of the sections open for editing: every input but the
/// Translations card's language code, which is always there.
Finder get _sectionInputs => find.byWidgetPredicate(
  (widget) =>
      widget is ShadInputFormField &&
      widget.key != const ValueKey('clubIdentity.addLanguage'),
);

/// Taps the pencil of [section].
Future<void> _edit(WidgetTester tester, Key section) async {
  await tester.tap(_in(section, find.byType(SectionEditButton)));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String id, String text) async {
  await tester.enterText(_input(id), text);
  await tester.pump();
}

/// Taps Add language in the Translations card.
Future<void> _addLanguage(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('clubIdentity.addLanguage.add')));
  await tester.pumpAndSettle();
}

/// Taps Save in [section].
Future<void> _save(WidgetTester tester, Key section) async {
  await tester.tap(_in(section, find.widgetWithText(ShadButton, 'Save')));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 20: the club details screen', () {
    testWidgets('Issue 20: an invalid field blocks the save', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _contact);
      await _enter(tester, 'phoneNumber', '98765 43210');
      await _save(tester, _contact);

      expect(stub.saves, isEmpty);
      expect(find.textContaining('international format'), findsOneWidget);
    });

    testWidgets('Issue 20: adding a language code offers it on every '
        'translatable field', (tester) async {
      final stub = await _pump(tester);

      await _enter(tester, 'addLanguage', 'Marathi');
      await _addLanguage(tester);
      expect(find.textContaining('two- or three-letter'), findsOneWidget);

      await _enter(tester, 'addLanguage', 'hi');
      await _addLanguage(tester);
      expect(find.text('Translations: mr, hi'), findsOneWidget);

      await _edit(tester, _club);
      expect(_input('tagline@hi'), findsOneWidget);
      await _edit(tester, _contact);
      expect(_input('whatsappMessage@hi'), findsOneWidget);
      expect(_input('emailSubject@hi'), findsOneWidget);
      await _edit(tester, _address);
      for (final id in ['address', 'addressLine2', 'city', 'state']) {
        expect(_input('$id@hi'), findsOneWidget, reason: id);
      }

      await _enter(tester, 'city', 'Pune');
      await _enter(tester, 'city@hi', 'पुणे');
      await _save(tester, _address);

      expect(
        stub.saves.single.contact?.city,
        const LocalizedText('Pune', {'mr': 'Udaharan', 'hi': 'पुणे'}),
      );
    });

    testWidgets('Issue 20: a refused save says so and keeps the edits', (
      tester,
    ) async {
      final stub = await _pump(tester)
        ..refuseWith = const ServerException(
          statusCode: 422,
          code: 'VALIDATION_ERROR',
          message: 'bad',
        );

      await _edit(tester, _club);
      await _enter(tester, 'shortName', 'EXC');
      await _save(tester, _club);

      expect(stub.saves, isEmpty);
      expect(
        find.text('Could not save the club details. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('bad'), findsNothing);
      expect(find.text('EXC'), findsOneWidget);
      expect(_input('shortName'), findsOneWidget);
    });
  });

  group('Issue 58: the club details screen, section by section', () {
    testWidgets('Issue 58: shows three section cards with the stored '
        'values, and no input until a pencil is tapped', (tester) async {
      await _pump(tester);

      expect(find.text('Club details'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is EditableSectionCard),
        findsNWidgets(3),
      );
      expect(_in(_club, find.text('Example Club')), findsOneWidget);
      expect(_in(_contact, find.text('+10000000000')), findsOneWidget);
      expect(_in(_address, find.text('Example City')), findsOneWidget);
      expect(_in(_address, find.text('City (mr)')), findsOneWidget);
      expect(_in(_address, find.text('Udaharan')), findsOneWidget);
      expect(find.byType(SectionEditButton), findsNWidgets(3));
      expect(_sectionInputs, findsNothing);
      expect(find.widgetWithText(ShadButton, 'Save'), findsNothing);
    });

    testWidgets('Issue 58: an empty optional value has no row, and an empty '
        'section shows its hint', (tester) async {
      await _pump(
        tester,
        saved: const ClubIdentity(name: 'Example Club'),
      );

      expect(_in(_club, find.text('Name')), findsOneWidget);
      expect(find.text('Short name'), findsNothing);
      expect(find.text('Tagline'), findsNothing);
      expect(find.text('Inquiry email'), findsNothing);
      expect(
        _in(_contact, find.text('Tap to add contact details')),
        findsOneWidget,
      );
      expect(
        _in(_address, find.text('Tap to add the address')),
        findsOneWidget,
      );
    });

    testWidgets('Issue 58: a pencil opens its own section only, with an '
        'input per language the stored values use', (tester) async {
      await _pump(tester);

      await _edit(tester, _address);

      expect(_input('city'), findsOneWidget);
      expect(_input('city@mr'), findsOneWidget);
      expect(_input('state@mr'), findsOneWidget);
      expect(_input('name'), findsNothing);
      expect(_input('phoneNumber'), findsNothing);
      expect(find.widgetWithText(ShadButton, 'Save'), findsOneWidget);
      expect(
        _in(_address, find.textContaining('Add a language')),
        findsNothing,
      );
    });

    testWidgets('Issue 58: saving one section sends only its fields and '
        'leaves the others unchanged', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _club);
      await _enter(tester, 'shortName', 'EXC');
      await _enter(tester, 'inquiryEmail', 'desk@club.example');
      await _save(tester, _club);

      expect(
        stub.saves.single,
        _stored.copyWith(
          shortName: () => 'EXC',
          inquiryEmail: () => 'desk@club.example',
        ),
      );
      expect(stub.saves.single.toMap(), {
        'values': <String>[],
        'name': 'Example Club',
        'shortName': 'EXC',
        'inquiryEmail': 'desk@club.example',
        'contact': {
          'phoneNumber': '+10000000000',
          'city': {'default': 'Example City', 'mr': 'Udaharan'},
        },
      });
      expect(find.text('Club updated.'), findsOneWidget);
      // Back in read mode, on the stored values.
      expect(_sectionInputs, findsNothing);
      expect(_in(_club, find.text('EXC')), findsOneWidget);
    });

    testWidgets('Issue 58: each section saves on its own, over what the '
        'one before stored', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _contact);
      await _enter(tester, 'email', 'hello@club.example');
      await _save(tester, _contact);
      expect(find.text('Contact updated.'), findsOneWidget);

      await _edit(tester, _address);
      await _enter(tester, 'postalCode', '000000');
      await _enter(tester, 'city@mr', '');
      await _save(tester, _address);
      expect(find.text('Address updated.'), findsOneWidget);

      expect(stub.saves, hasLength(2));
      expect(stub.saves.first.toMap()['contact'], {
        'phoneNumber': '+10000000000',
        'email': 'hello@club.example',
        'city': {'default': 'Example City', 'mr': 'Udaharan'},
      });
      expect(stub.saves.last.toMap(), {
        'values': <String>[],
        'name': 'Example Club',
        'contact': {
          'phoneNumber': '+10000000000',
          'email': 'hello@club.example',
          'city': 'Example City',
          'postalCode': '000000',
        },
      });
    });

    testWidgets('Issue 58: the Translations card lists the languages, says '
        'what adding one does, and adding stores nothing', (tester) async {
      final stub = await _pump(tester);

      expect(_in(_translations, find.text('Translations')), findsOneWidget);
      expect(
        _in(_translations, find.text('Translations: mr')),
        findsOneWidget,
      );
      expect(
        _in(
          _translations,
          find.textContaining('saved with the section it is used in'),
        ),
        findsOneWidget,
      );
      expect(
        _in(_translations, find.byType(SectionEditButton)),
        findsNothing,
      );

      await _enter(tester, 'addLanguage', 'hi');
      await _addLanguage(tester);

      expect(stub.saves, isEmpty);
      expect(find.text('Translations: mr, hi'), findsOneWidget);
      // The field is emptied for the next code.
      expect(_in(_translations, find.text('hi')), findsNothing);
    });

    testWidgets('Issue 58: a language already listed is refused in the '
        'Translations card', (tester) async {
      await _pump(tester);

      await _enter(tester, 'addLanguage', 'mr');
      await _addLanguage(tester);

      expect(find.text('mr is already offered'), findsOneWidget);
      expect(find.text('Translations: mr'), findsOneWidget);
    });

    testWidgets('Issue 58: a language added in the Translations card gets '
        'an input in a section opened afterwards, and in one already '
        'open', (tester) async {
      await _pump(tester, saved: const ClubIdentity(name: 'Example Club'));
      expect(
        find.text(
          'Translations: none yet — every field shows its default text.',
        ),
        findsOneWidget,
      );

      await _edit(tester, _club);
      expect(_input('tagline@hi'), findsNothing);

      await _enter(tester, 'addLanguage', 'hi');
      await _addLanguage(tester);

      expect(_input('tagline@hi'), findsOneWidget);
      await _edit(tester, _address);
      expect(_input('city@hi'), findsOneWidget);
    });

    testWidgets('Issue 58: a language added but never used is not '
        'written', (tester) async {
      final stub = await _pump(tester);

      await _enter(tester, 'addLanguage', 'hi');
      await _addLanguage(tester);
      await _edit(tester, _address);
      await _enter(tester, 'postalCode', '000000');
      await _save(tester, _address);

      expect(stub.saves.single.toMap(), {
        'values': <String>[],
        'name': 'Example Club',
        'contact': {
          'phoneNumber': '+10000000000',
          'city': {'default': 'Example City', 'mr': 'Udaharan'},
          'postalCode': '000000',
        },
      });
      expect(clubIdentityLanguagesOfStored(stub), ['mr']);
    });

    testWidgets('Issue 58: a translation without a default is refused in '
        'its own section', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _address);
      await _enter(tester, 'city', '');
      await _save(tester, _address);

      expect(stub.saves, isEmpty);
      expect(
        _in(
          _address,
          find.text('City has a translation but no default text.'),
        ),
        findsOneWidget,
      );
      expect(_input('city@mr'), findsOneWidget);
    });

    testWidgets('Issue 58: Save with nothing changed closes the editor '
        'without a write', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _club);
      await _save(tester, _club);

      expect(stub.saves, isEmpty);
      expect(_sectionInputs, findsNothing);
    });

    testWidgets('Issue 58: Cancel puts back what is stored', (tester) async {
      final stub = await _pump(tester);

      await _edit(tester, _club);
      await _enter(tester, 'name', 'Other Club');
      await tester.tap(_in(_club, find.widgetWithText(ShadButton, 'Cancel')));
      await tester.pumpAndSettle();

      expect(stub.saves, isEmpty);
      expect(find.text('Example Club'), findsOneWidget);
      expect(find.text('Other Club'), findsNothing);
    });

    testWidgets('Issue 58: a failure that is not a refusal shows a fixed '
        'message, never the exception', (tester) async {
      final stub = await _pump(tester)
        ..failWith = StateError('socket closed');

      await _edit(tester, _club);
      await _enter(tester, 'shortName', 'EXC');
      await _save(tester, _club);

      expect(stub.saves, isEmpty);
      expect(
        find.text('Could not save the club details. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('socket closed'), findsNothing);
      expect(_input('shortName'), findsOneWidget);
    });
  });
}
