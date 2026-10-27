// Issue 320, Issue 396, ProfileOptionsForm: the club's choices for the
// extended profile. Positions carry a value and a label per language of the
// club (English required); languages are a name and a code, English always
// first and fixed. Rows are added, removed and, for positions, moved; the
// lists are checked on Save.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _positions = ProfileOptionsFormFields.positionsId;
const String _languages = ProfileOptionsFormFields.languagesId;
const String _value = ProfileOptionsFormFields.valueKey;
const String _label = ProfileOptionsFormFields.labelKey;

const String _code = ProfileOptionsFormFields.codeKey;
const String _name = ProfileOptionsFormFields.nameKey;

Map<String, String> _lang(String code, String name) => {
  _code: code,
  _name: name,
};

Map<String, dynamic> _options() => {
  _positions: [
    {
      _value: 'Forward',
      _label: {'en': 'Forward', 'mr': 'फॉरवर्ड', 'hi': 'फ़ॉरवर्ड'},
    },
    {
      _value: 'Goalie',
      _label: {'en': 'Goalie', 'ta': 'கோல்கீப்பர்'},
    },
  ],
  _languages: [
    _lang('en', 'English'),
    _lang('mr', 'Marathi'),
    _lang('hi', 'Hindi'),
  ],
};

Widget _form({
  required GlobalKey<ProfileOptionsFormState> key,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) => ProfileOptionsForm(
  key: key,
  initialValues: initialValues ?? _options(),
  enabled: enabled,
);

Future<ProfileOptionsFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<ProfileOptionsFormState>();
  await pumpForm(
    tester,
    _form(key: key, initialValues: initialValues, enabled: enabled),
    size: size,
  );
  return key.currentState!;
}

/// The [index]th text input of the list [id]: a position row has its
/// value and then a label per language; a language row after English's,
/// which has none, its name and then its code.
Finder _input(String id, int index) => find
    .descendant(of: fieldWithId(id), matching: find.byType(EditableText))
    .at(index);

Future<void> _type(WidgetTester tester, String id, int index, String text) =>
    tester.enterText(_input(id, index), text).then((_) => tester.pump());

Future<void> _tapIn(WidgetTester tester, String id, IconData icon, int i) =>
    tester
        .tap(
          find
              .descendant(of: fieldWithId(id), matching: find.byIcon(icon))
              .at(i),
        )
        .then((_) => tester.pumpAndSettle());

Future<void> _tapText(WidgetTester tester, String text) =>
    tester.tap(find.text(text)).then((_) => tester.pumpAndSettle());

void main() {
  group('Issue 320: ProfileOptionsForm', () {
    testWidgets('Issue 320: each position shows its value and a label per '
        'language, English required, and each language its name and code', (
      tester,
    ) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Positions',
        'Value *',
        'English *',
        'Marathi',
        'Hindi',
        'Value *',
        'English *',
        'Marathi',
        'Hindi',
        'Languages',
        'Name *',
        'Code *',
        'Name *',
        'Code *',
      ]);
      expect(fieldIds(tester), [_positions, _languages]);
      expect(
        find.descendant(
          of: fieldWithId(_positions),
          matching: find.byType(EditableText),
        ),
        findsNWidgets(8),
      );
      expect(
        find.descendant(
          of: fieldWithId(_languages),
          matching: find.byType(EditableText),
        ),
        findsNWidgets(4),
      );
      expect(find.text('English (en)'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(
        tester,
        allowedButtonTexts: const {'Add position', 'Add language'},
      );
    });

    testWidgets('Issue 320: the seeded options come back with empty labels '
        'left out; Issue 396: a label in a language the club lacks is '
        'dropped', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _positions: [
          {
            _value: 'Forward',
            _label: {'en': 'Forward', 'mr': 'फॉरवर्ड', 'hi': 'फ़ॉरवर्ड'},
          },
          {
            _value: 'Goalie',
            _label: {'en': 'Goalie'},
          },
        ],
        _languages: [
          _lang('en', 'English'),
          _lang('mr', 'Marathi'),
          _lang('hi', 'Hindi'),
        ],
      });
    });

    testWidgets('Issue 320: with no options it starts with no position; '
        'Issue 396: English is always a language', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text('English (en)'), findsOneWidget);
      expect(state.validate(), {
        _positions: <Object?>[],
        _languages: [_lang('en', 'English')],
      });
    });

    testWidgets('Issue 396: English cannot be removed and stays first', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        initialValues: {
          _positions: const <Object?>[],
          _languages: [_lang('mr', 'Marathi'), _lang('en', 'English')],
        },
      );

      expect(
        find.descendant(
          of: fieldWithId(_languages),
          matching: find.byIcon(LucideIcons.trash2),
        ),
        findsOneWidget,
        reason: "Marathi's alone",
      );
      expect(state.validate()![_languages], [
        _lang('en', 'English'),
        _lang('mr', 'Marathi'),
      ]);
    });

    testWidgets('Issue 396: an added language gives every position a label '
        'in it, and a removed one takes its labels away', (tester) async {
      final state = await _pump(tester);

      await _tapText(tester, 'Add language');
      await _type(tester, _languages, 4, 'Tamil');
      await _type(tester, _languages, 5, 'ta');
      expect(find.text('Tamil'), findsNWidgets(3), reason: 'the input too');
      await _type(tester, _positions, 4, 'Forward ta');

      var values = state.validate()!;
      expect((values[_positions] as List).first, {
        _value: 'Forward',
        _label: {
          'en': 'Forward',
          'mr': 'फॉरवर्ड',
          'hi': 'फ़ॉरवर्ड',
          'ta': 'Forward ta',
        },
      });
      expect((values[_positions] as List).last, {
        _value: 'Goalie',
        _label: {'en': 'Goalie', 'ta': 'கோல்கீப்பர்'},
      }, reason: "Goalie's stored Tamil label shows again");

      // Hindi removed: its labels go with it.
      await _tapIn(tester, _languages, LucideIcons.trash2, 1);
      expect(find.text('Hindi'), findsNothing);
      values = state.validate()!;
      expect(values[_languages], [
        _lang('en', 'English'),
        _lang('mr', 'Marathi'),
        _lang('ta', 'Tamil'),
      ]);
      expect(
        ((values[_positions] as List).first as Map)[_label],
        {'en': 'Forward', 'mr': 'फॉरवर्ड', 'ta': 'Forward ta'},
      );
    });

    testWidgets('Issue 320: an added position and language come back '
        'trimmed, last', (tester) async {
      final state = await _pump(tester);

      await _tapText(tester, 'Add position');
      await _type(tester, _positions, 8, ' Defense ');
      await _type(tester, _positions, 9, ' Defence ');
      await _type(tester, _positions, 11, ' डिफ़ेंस ');
      await _tapText(tester, 'Add language');
      await _type(tester, _languages, 4, ' Tamil ');
      await _type(tester, _languages, 5, ' ta ');

      expect(state.isDirty, isTrue);
      final values = state.validate()!;
      expect((values[_positions] as List).last, {
        _value: 'Defense',
        _label: {'en': 'Defence', 'hi': 'डिफ़ेंस'},
      });
      expect(values[_languages], [
        _lang('en', 'English'),
        _lang('mr', 'Marathi'),
        _lang('hi', 'Hindi'),
        _lang('ta', 'Tamil'),
      ]);
    });

    final refusals =
        <
          ({
            String rule,
            String id,
            Future<void> Function(WidgetTester) edit,
            String message,
          })
        >[
          (
            rule: 'Issue 320: a position without a value',
            id: _positions,
            edit: (tester) => _type(tester, _positions, 0, ' '),
            message: 'Each position needs a value',
          ),
          (
            rule: 'Issue 320: two positions with the same value',
            id: _positions,
            edit: (tester) => _type(tester, _positions, 4, 'forward '),
            message: 'Two positions have the value "forward"',
          ),
          (
            rule: 'Issue 320: a position without an English label',
            id: _positions,
            edit: (tester) => _type(tester, _positions, 5, ''),
            message: 'Each position needs a label in English',
          ),
          (
            rule: 'Issue 320: a language without a name',
            id: _languages,
            edit: (tester) => _type(tester, _languages, 0, '  '),
            message: 'Each language needs a name',
          ),
          (
            rule: 'Issue 320: a language listed twice',
            id: _languages,
            edit: (tester) => _type(tester, _languages, 0, 'english'),
            message: '"english" is listed twice',
          ),
          (
            rule: 'Issue 396: a language without a code',
            id: _languages,
            edit: (tester) => _type(tester, _languages, 1, ' '),
            message: 'Each language needs a code',
          ),
          (
            rule: 'Issue 396: a code that is not a language code',
            id: _languages,
            edit: (tester) => _type(tester, _languages, 1, 'Mar athi'),
            message:
                '"Mar athi" is not a language code: use lowercase letters, '
                'like hi or kok',
          ),
          (
            rule: 'Issue 396: a code listed twice',
            id: _languages,
            edit: (tester) => _type(tester, _languages, 3, 'mr'),
            message: 'The code "mr" is listed twice',
          ),
        ];

    for (final r in refusals) {
      testWidgets('${r.rule} is refused under its list', (
        tester,
      ) async {
        final state = await _pump(tester);
        await r.edit(tester);

        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expectMessageOn(r.id, r.message);
      });
    }

    testWidgets('Issue 320: a newly added empty position is refused, and '
        'removing it makes the form valid again', (tester) async {
      final state = await _pump(tester);

      await _tapText(tester, 'Add position');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_positions, 'Each position needs a value');

      await _tapIn(tester, _positions, LucideIcons.trash2, 2);
      expect(state.validate(), isNotNull);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: a position moves up and down, and the order '
        'comes back', (tester) async {
      final state = await _pump(tester);
      List<Object?> order() => [
        for (final p in state.validate()![_positions] as List)
          (p as Map)[_value],
      ];

      await _tapIn(tester, _positions, LucideIcons.arrowUp, 1);
      expect(order(), ['Goalie', 'Forward']);
      expect(state.isDirty, isTrue);

      await _tapIn(tester, _positions, LucideIcons.arrowDown, 0);
      expect(order(), ['Forward', 'Goalie']);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: the first position cannot move up nor the last '
        'down', (tester) async {
      await _pump(tester);

      final up = tester.widgetList<ShadIconButton>(
        find.ancestor(
          of: find.byIcon(LucideIcons.arrowUp),
          matching: find.byType(ShadIconButton),
        ),
      );
      final down = tester.widgetList<ShadIconButton>(
        find.ancestor(
          of: find.byIcon(LucideIcons.arrowDown),
          matching: find.byType(ShadIconButton),
        ),
      );
      expect([for (final b in up) b.enabled], [false, true]);
      expect([for (final b in down) b.enabled], [true, false]);
    });

    testWidgets('Issue 320: a removed language is gone from the values', (
      tester,
    ) async {
      final state = await _pump(tester);

      await _tapIn(tester, _languages, LucideIcons.trash2, 0);
      expect(state.validate()![_languages], [
        _lang('en', 'English'),
        _lang('hi', 'Hindi'),
      ]);
      expect(state.isDirty, isTrue);
    });

    testWidgets('Issue 320: isDirty follows a label and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);

      await _type(tester, _positions, 2, 'x');
      expect(state.isDirty, isTrue);
      await _type(tester, _positions, 2, 'फॉरवर्ड');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: a refusal shows under its list and inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _positions);
      await expectShowsServerErrors(tester, state, _languages);
    });

    testWidgets('Issue 320: turned off while saving, every control is '
        'drawn off and typing is ignored', (tester) async {
      final key = GlobalKey<ProfileOptionsFormState>();
      Widget build({required bool enabled}) =>
          _form(key: key, enabled: enabled);

      // Twelve inputs, three buttons per position and one per language
      // after English, and the two add buttons.
      expect(await expectDrawnOffWhenTurnedOff(tester, build), 22);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 12);
    });

    testWidgets('Issue 320: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        _form(key: GlobalKey<ProfileOptionsFormState>()),
      );
    });
  });
}
