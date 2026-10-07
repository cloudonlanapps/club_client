// Issue 61, UserPersonalDetailsForm. Every point applies. The form has no
// button of its own. Its values are its fields as typed: nothing is
// trimmed here (the host's adapter does).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _nickname = UserFormFields.nicknameId;
const String _useName = UserFormFields.useNamePubliclyId;
const String _publicProfile = UserFormFields.isPublicProfileId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;

const _noName = 'First name or last name is required';
const List<String> _names = [_first, _middle, _last, _nickname];
const _nameRows = ['First name *', 'Middle name', 'Last name *', 'Nickname'];

Map<String, dynamic> _member() => {
  _first: 'Robin',
  _middle: 'K',
  _last: 'Rao',
  _nickname: 'Rob',
  _useName: true,
  _publicProfile: true,
  _gender: SignupGender.other,
  _dob: DateTime.utc(2010, 3, 4),
};

Future<UserPersonalDetailsFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  bool canEditGender = false,
  bool canEditDateOfBirth = false,
  bool canEditUseNamePublicly = false,
  bool canEditPublicProfile = false,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserPersonalDetailsFormState>();
  await pumpForm(
    tester,
    UserPersonalDetailsForm(
      key: key,
      initialValues: initialValues ?? _member(),
      enabled: enabled,
      canEditGender: canEditGender,
      canEditDateOfBirth: canEditDateOfBirth,
      canEditUseNamePublicly: canEditUseNamePublicly,
      canEditPublicProfile: canEditPublicProfile,
    ),
    size: size,
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: UserPersonalDetailsForm, its fields', () {
    testWidgets('Issue 61: for a viewer with no extra right it shows the '
        'four names as fields and the public name, gender and date of '
        'birth read-only, each row stacked', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        ..._nameRows,
        'Show name publicly',
        'Gender',
        'Date of birth',
      ]);
      expect(fieldIds(tester), _names);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('4 Mar 2010'), findsOneWidget);
      expect(sideBySide(tester, _first, _middle), isFalse);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: canEditGender makes the gender a required '
        'field and puts it in the values', (tester) async {
      final state = await _pump(tester, canEditGender: true);

      expect(fieldIds(tester), [..._names, _gender]);
      expect(rowLabels(tester), [
        ..._nameRows,
        'Show name publicly',
        'Gender *',
        'Date of birth',
      ]);
      expect(state.validate()!.keys, [..._names, _gender]);
    });

    testWidgets('Issue 61: canEditDateOfBirth makes the date of birth a '
        'required field and puts it in the values', (tester) async {
      final state = await _pump(tester, canEditDateOfBirth: true);

      expect(fieldIds(tester), [..._names, _dob]);
      expect(rowLabels(tester), [
        ..._nameRows,
        'Show name publicly',
        'Gender',
        'Date of birth *',
      ]);
      expect(state.validate()!.keys, [..._names, _dob]);
    });

    testWidgets('Issue 61: canEditUseNamePublicly makes the public name a '
        'tick and puts it in the values', (tester) async {
      final state = await _pump(tester, canEditUseNamePublicly: true);

      expect(fieldIds(tester), [..._names, _useName]);
      expect(rowLabels(tester), [..._nameRows, 'Gender', 'Date of birth']);
      expect(find.text('Show name publicly'), findsOneWidget);
      expect(state.validate()!.keys, [..._names, _useName]);
    });

    testWidgets("Issue 61: canEditPublicProfile shows the coach's two "
        'ticks and puts both flags in the values', (tester) async {
      final state = await _pump(tester, canEditPublicProfile: true);

      expect(fieldIds(tester), [..._names, _publicProfile, _useName]);
      expect(find.text('Show my profile publicly'), findsOneWidget);
      expect(find.text('Show my name on my public profile'), findsOneWidget);
      expect(state.validate()!.keys, [..._names, _publicProfile, _useName]);
    });
  });

  group('Issue 61: UserPersonalDetailsForm, its rules', () {
    testWidgets('Issue 61: an editable gender that is not set is refused '
        'on its field, and taken once picked', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), _gender: null},
        canEditGender: true,
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_gender, 'Gender is required');

      await pickOption(tester, _gender, 'Male');
      expect(state.validate()![_gender], SignupGender.male);
      await tester.pumpAndSettle();
      expect(find.text('Gender is required'), findsNothing);
    });

    testWidgets('Issue 61: an editable date of birth that is not set is '
        'refused on its field, and taken once set', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), _dob: null},
        canEditDateOfBirth: true,
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_dob, 'Date of birth is required');

      await setField(tester, state, _dob, DateTime(2011, 5, 6));
      expect(state.validate()![_dob], DateTime(2011, 5, 6));
    });

    testWidgets('Issue 61: a read-only gender and date of birth that were '
        'never set do not block the save', (tester) async {
      final state = await _pump(tester, initialValues: const {_first: 'Robin'});

      expect(find.text('Not set'), findsNWidgets(2));
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: neither first nor last name is refused inline, '
        'whatever the middle name and nickname hold', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _first, '');
      await enterField(tester, _last, '   ');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(_noName);
    });

    testWidgets('Issue 61: a first name alone, or a last name alone, is '
        'enough, and the inline message goes', (tester) async {
      final state = await _pump(tester, initialValues: const {});
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(_noName);

      await enterField(tester, _last, 'Rao');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(_noName), findsNothing);

      await enterField(tester, _last, '');
      await enterField(tester, _first, 'Robin');
      expect(state.validate(), isNotNull);
    });
  });

  group('Issue 61: UserPersonalDetailsForm, its values', () {
    testWidgets('Issue 61: with no extra right, validate returns exactly '
        'the four names as typed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _first, ' Robin ');
      await enterField(tester, _middle, '');

      expect(state.validate(), {
        _first: ' Robin ',
        _middle: '',
        _last: 'Rao',
        _nickname: 'Rob',
      });
    });

    testWidgets('Issue 61: with every right, the seeded values come back '
        'unchanged under exactly the eight ids, with their types', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        canEditGender: true,
        canEditDateOfBirth: true,
        canEditUseNamePublicly: true,
        canEditPublicProfile: true,
      );

      expect(state.isDirty, isFalse);
      final values = state.validate();

      expect(values, _member());
      expect(
        values!.keys.toSet(),
        UserFormFields.personalDetailsIds.toSet(),
      );
      expect(values[_gender], isA<SignupGender>());
      expect(values[_dob], isA<DateTime>());
      expect(values[_useName], isA<bool>());
      expect(values[_publicProfile], isA<bool>());
    });

    testWidgets('Issue 61: a member with only a first name comes back '
        'with the other names empty and the flags false', (tester) async {
      final state = await _pump(
        tester,
        initialValues: const {_first: 'Robin'},
        canEditUseNamePublicly: true,
        canEditPublicProfile: true,
      );

      expect(state.validate(), {
        _first: 'Robin',
        _middle: '',
        _last: '',
        _nickname: '',
        _publicProfile: false,
        _useName: false,
      });
    });

    testWidgets('Issue 61: a coach who makes the profile private gets the '
        'public name false too', (tester) async {
      final state = await _pump(tester, canEditPublicProfile: true);

      await tapCheckbox(tester, _publicProfile);
      final values = state.validate()!;

      expect(values[_publicProfile], isFalse);
      expect(values[_useName], isFalse);
    });

    testWidgets('Issue 61: a coach with a private profile who makes it '
        'public chooses the public name separately', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), _publicProfile: false, _useName: false},
        canEditPublicProfile: true,
      );

      await tapCheckbox(tester, _publicProfile);
      expect(state.validate(), containsPair(_useName, false));

      await tapCheckbox(tester, _useName);
      final values = state.validate()!;
      expect(values[_publicProfile], isTrue);
      expect(values[_useName], isTrue);
    });
  });

  group('Issue 61: UserPersonalDetailsForm, dirty check', () {
    testWidgets('Issue 61: isDirty follows each name, and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      for (final id in _names) {
        final before = _member()[id] as String;
        await enterField(tester, id, '${before}x');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the public-name tick, the '
        'gender and the date of birth, and is false again when each is '
        'put back', (tester) async {
      final state = await _pump(
        tester,
        canEditGender: true,
        canEditDateOfBirth: true,
        canEditUseNamePublicly: true,
      );
      expect(state.isDirty, isFalse);

      await tapCheckbox(tester, _useName);
      expect(state.isDirty, isTrue);
      await tapCheckbox(tester, _useName);
      expect(state.isDirty, isFalse);

      await pickOption(tester, _gender, 'Female');
      expect(state.isDirty, isTrue);
      await pickOption(tester, _gender, 'Other');
      expect(state.isDirty, isFalse);

      await setField(tester, state, _dob, DateTime.utc(2011, 5, 6));
      expect(state.isDirty, isTrue);
      await setField(tester, state, _dob, DateTime.utc(2010, 3, 4));
      expect(state.isDirty, isFalse);
    });

    testWidgets("Issue 61: isDirty follows the coach's public-profile "
        'tick, and is false again when the profile is made public again', (
      tester,
    ) async {
      final state = await _pump(tester, canEditPublicProfile: true);
      expect(state.isDirty, isFalse);

      await tapCheckbox(tester, _publicProfile);
      expect(state.isDirty, isTrue);

      await tapCheckbox(tester, _publicProfile);
      expect(state.isDirty, isFalse);
      expect(state.validate(), containsPair(_useName, true));
    });
  });

  group('Issue 61: UserPersonalDetailsForm, server errors, disabled, '
      'narrow', () {
    testWidgets('Issue 61: a refusal shows on the nickname and inline, and '
        'the form saves again afterwards', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _nickname);

      state.showErrors(
        fieldErrors: const {_nickname: 'That nickname is taken.'},
        formError: 'Could not save the details.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_nickname, 'That nickname is taken.');
      expectInlineMessage('Could not save the details.');

      await enterField(tester, _nickname, 'Robby');
      expect(state.validate()![_nickname], 'Robby');
      await tester.pumpAndSettle();
      expect(find.text('That nickname is taken.'), findsNothing);
      expect(find.text('Could not save the details.'), findsNothing);
    });

    testWidgets('Issue 61: a refusal for a protected field the viewer sees '
        'read-only shows inline', (tester) async {
      final state = await _pump(tester);

      state.showErrors(fieldErrors: const {_dob: 'Date of birth is locked.'});
      await tester.pumpAndSettle();

      expectInlineMessage('Date of birth is locked.');
    });

    testWidgets('Issue 61: with enabled off no name, tick or select '
        'responds', (tester) async {
      final state = await _pump(
        tester,
        enabled: false,
        canEditGender: true,
        canEditDateOfBirth: true,
        canEditPublicProfile: true,
      );

      expectEveryFieldOff(tester);
      expect(fieldIds(tester), [
        ..._names,
        _publicProfile,
        _useName,
        _gender,
        _dob,
      ]);
      await expectTapsIgnored(tester, _names);
      await tapCheckbox(tester, _publicProfile);
      await tapCheckbox(tester, _useName);
      await tapSelect(tester, _gender);
      expect(find.text('Female'), findsNothing);
      expect(state.isDirty, isFalse);
      expect(state.validate(), _member());
    });

    testWidgets('Issue 61: it fits a phone with every right and its '
        'messages showing', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {_gender: SignupGender.preferNotToSay},
        canEditGender: true,
        canEditDateOfBirth: true,
        canEditPublicProfile: true,
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Date of birth is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 61: it fits a phone with the protected fields '
        'read-only', (tester) async {
      await _pump(tester, size: kPhoneSurface);

      expect(tester.takeException(), isNull);
    });
  });
}
