// Issue 320, UserSportsDetailsForm: the sports details of the extended
// profile. Every field is optional; the positions are checkboxes of the
// club's positions, any number ticked (Issue 335), and a position the club
// no longer lists stays ticked. Its values are its fields as typed: the
// host's adapter trims.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadCheckbox;

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _club = UserFormFields.clubDistrictId;
const String _position = UserFormFields.preferredPositionsId;
const String _experience = UserFormFields.pastExperienceId;

const List<ProfilePositionOption> _positions = [
  ProfilePositionOption(value: 'Forward', label: 'Forward'),
  ProfilePositionOption(value: 'Defense', label: 'Defence'),
  ProfilePositionOption(value: 'Goalie', label: 'Goalkeeper'),
];

Map<String, dynamic> _member() => {
  _club: 'Pune District',
  _position: ['Defense'],
  _experience: 'Two seasons of club hockey',
};

Widget _form({
  required GlobalKey<UserSportsDetailsFormState> key,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) => UserSportsDetailsForm(
  key: key,
  initialValues: initialValues ?? _member(),
  positions: _positions,
  enabled: enabled,
);

Future<UserSportsDetailsFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserSportsDetailsFormState>();
  await pumpForm(
    tester,
    _form(key: key, initialValues: initialValues, enabled: enabled),
    size: size,
  );
  return key.currentState!;
}

void main() {
  group('Issue 320: UserSportsDetailsForm', () {
    testWidgets('Issue 320: it shows club or district, preferred positions '
        'and past experience, none required', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Club / District',
        'Preferred positions',
        'Past experience',
      ]);
      expect(fieldIds(tester), UserFormFields.sportsDetailsIds);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
      expect(find.text('Defence'), findsOneWidget);
    });

    testWidgets('Issue 320: the seeded values come back unchanged under '
        'exactly the three ids', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();
      expect(values, _member());
      expect(values!.keys, UserFormFields.sportsDetailsIds);
    });

    testWidgets('Issue 335: a blank member comes back as empty texts and '
        'no position, with the muted line shown', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text(UserFormStrings.noPositionChosen), findsOneWidget);
      expect(state.validate(), {
        _club: '',
        _position: <String>[],
        _experience: '',
      });
    });

    testWidgets('Issue 335: a box for every position by its label; two '
        'ticked come back as both values', (tester) async {
      final state = await _pump(tester);

      for (final text in ['Forward', 'Defence', 'Goalkeeper']) {
        expect(
          find.descendant(
            of: fieldWithId(_position),
            matching: find.widgetWithText(ShadCheckbox, text),
          ),
          findsOneWidget,
          reason: text,
        );
      }
      expect(choiceTicked(tester, _position, 'Defence'), isTrue);
      expect(find.text(UserFormStrings.noPositionChosen), findsNothing);

      await tapChoice(tester, _position, 'Goalkeeper');
      expect(state.validate()![_position], ['Defense', 'Goalie']);
      expect(state.isDirty, isTrue);

      await tapChoice(tester, _position, 'Goalkeeper');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 335: none ticked comes back as an empty list', (
      tester,
    ) async {
      final state = await _pump(tester);

      await tapChoice(tester, _position, 'Defence');
      expect(find.text(UserFormStrings.noPositionChosen), findsOneWidget);
      expect(state.validate()![_position], <String>[]);
      expect(state.isDirty, isTrue);
    });

    testWidgets('Issue 335: a position the club no longer lists stays '
        'ticked and is kept', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          ..._member(),
          _position: ['Centre', 'Forward'],
        },
      );

      expect(choiceTicked(tester, _position, 'Centre'), isTrue);
      expect(choiceTicked(tester, _position, 'Forward'), isTrue);
      expect(state.isDirty, isFalse);
      expect(state.validate()![_position], ['Centre', 'Forward']);

      await tapChoice(tester, _position, 'Goalkeeper');
      expect(state.validate()![_position], ['Forward', 'Goalie', 'Centre']);
    });

    testWidgets('Issue 320: what is typed comes back as typed, multi-line '
        'experience included', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _club, ' Mumbai ');
      await enterField(tester, _experience, 'School team\nState camp');

      expect(state.validate(), {
        ..._member(),
        _club: ' Mumbai ',
        _experience: 'School team\nState camp',
      });
    });

    testWidgets('Issue 320: values of other sections are neither shown nor '
        'returned', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), UserFormFields.cityId: 'Nagpur'},
      );

      expect(find.text('Nagpur'), findsNothing);
      expect(state.validate(), _member());
    });

    testWidgets('Issue 320: isDirty follows each text and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);

      for (final id in [_club, _experience]) {
        final before = _member()[id] as String;
        await enterField(tester, id, '${before}1');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 320: a refusal shows on its field and inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _position);
      await expectShowsServerErrors(tester, state, _club);
    });

    testWidgets('Issue 320: with enabled off every field is off and no '
        'box ticks', (tester) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_club, _experience]);
      await tapChoice(tester, _position, 'Goalkeeper');
      expect(choiceTicked(tester, _position, 'Goalkeeper'), isFalse);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: turned off while saving, every control is '
        'drawn off and typing is ignored', (tester) async {
      final key = GlobalKey<UserSportsDetailsFormState>();
      Widget build({required bool enabled}) =>
          _form(key: key, enabled: enabled);

      expect(await expectDrawnOffWhenTurnedOff(tester, build), 5);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 2);
    });

    testWidgets('Issue 320: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        _form(key: GlobalKey<UserSportsDetailsFormState>()),
      );
    });
  });
}
