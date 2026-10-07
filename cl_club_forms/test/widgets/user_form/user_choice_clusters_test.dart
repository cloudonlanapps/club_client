// The field clusters of the user forms that hold choices: gender and date
// of birth, the public-name ticks, the role ticks and the default-password
// tick.
// Each is mounted alone in a bare ShadForm. A cluster has no validate() or
// isDirty of its own (the embedding form has); those points are tested on
// the forms. The in-cluster action is "Show" beside the default-password
// tick.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_default_password_field.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_field_pair.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_gender_dob_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_public_name_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_role_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _useName = UserFormFields.useNamePubliclyId;
const String _publicProfile = UserFormFields.isPublicProfileId;
const String _admin = UserFormFields.assignAdminId;
const String _coach = UserFormFields.assignCoachId;
const String _useDefault = UserFormFields.useDefaultPasswordId;

/// Whether the tick with [id] is ticked, as drawn.
bool _ticked(WidgetTester tester, String id) => tester
    .widget<ShadCheckbox>(
      find.descendant(of: fieldWithId(id), matching: find.byType(ShadCheckbox)),
    )
    .value;

bool _fieldIsOn(WidgetTester tester, String id) =>
    tester.widget<ShadFormBuilderField<dynamic>>(fieldWithId(id)).enabled;

void main() {
  group('Issue 61: UserGenderDobFields', () {
    testWidgets('Issue 61: it shows gender and date of birth, both '
        'required, with their hints', (tester) async {
      await pumpCluster(tester, const UserGenderDobFields());

      expect(rowLabels(tester), ['Gender *', 'Date of birth *']);
      expect(fieldIds(tester), [_gender, _dob]);
      expect(find.text('Select gender'), findsOneWidget);
      expect(find.text('Select date of birth'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: it shows the hints it is given', (tester) async {
      await pumpCluster(
        tester,
        const UserGenderDobFields(
          genderPlaceholder: 'Select',
          dateOfBirthPlaceholder: 'Pick date',
        ),
      );

      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Pick date'), findsOneWidget);
      expect(find.text('Select gender'), findsNothing);
    });

    testWidgets('Issue 61: no gender and no date of birth are refused, '
        'each on its field', (tester) async {
      final form = await pumpCluster(tester, const UserGenderDobFields());

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();

      expectMessageOn(_gender, 'Gender is required');
      expectMessageOn(_dob, 'Date of birth is required');
    });

    testWidgets('Issue 61: a gender picked and a date set are taken, and '
        'the messages go', (tester) async {
      final form = await pumpCluster(tester, const UserGenderDobFields());
      form.saveAndValidate();
      await tester.pumpAndSettle();

      await pickOption(tester, _gender, 'Female');
      form.setFieldValue(_dob, DateTime(2010, 3, 4));
      await tester.pumpAndSettle();

      expect(form.saveAndValidate(), isTrue);
      await tester.pumpAndSettle();
      expect(form.value, {
        _gender: SignupGender.female,
        _dob: DateTime(2010, 3, 4),
      });
      expect(find.text('Gender is required'), findsNothing);
      expect(find.text('Date of birth is required'), findsNothing);
      expect(find.text('4 Mar 2010'), findsOneWidget);
    });

    testWidgets("Issue 61: it starts from the form's values, the date "
        'read as "4 Mar 2010"', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserGenderDobFields(),
        initial: {_gender: SignupGender.other, _dob: DateTime.utc(2010, 3, 4)},
      );

      expect(find.text('Other'), findsOneWidget);
      expect(find.text('4 Mar 2010'), findsOneWidget);
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: with canEditGender off the gender is a '
        'read-only row and no field', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserGenderDobFields(canEditGender: false),
        initial: {_gender: SignupGender.female, _dob: DateTime.utc(2010, 3, 4)},
      );

      expect(rowLabels(tester), ['Gender', 'Date of birth *']);
      expect(fieldIds(tester), [_dob]);
      expect(find.text('Female'), findsOneWidget);
      expect(form.fields.keys, [_dob]);
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: with canEditDateOfBirth off the date is a '
        'read-only row and no field', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserGenderDobFields(canEditDateOfBirth: false),
        initial: {_gender: SignupGender.female, _dob: DateTime.utc(2010, 3, 4)},
      );

      expect(rowLabels(tester), ['Gender *', 'Date of birth']);
      expect(fieldIds(tester), [_gender]);
      expect(find.text('4 Mar 2010'), findsOneWidget);
      expect(form.fields.keys, [_gender]);
    });

    testWidgets('Issue 61: read-only and never set, both read "Not set" '
        'and nothing is required', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserGenderDobFields(
          canEditGender: false,
          canEditDateOfBirth: false,
        ),
      );

      expect(rowLabels(tester), ['Gender', 'Date of birth']);
      expect(fieldIds(tester), isEmpty);
      expect(find.text('Not set'), findsNWidgets(2));
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: the two sit side by side where there is room '
        'and follow pairMinWidth', (tester) async {
      await pumpCluster(tester, const UserGenderDobFields());
      expect(sideBySide(tester, _gender, _dob), isTrue);

      await pumpCluster(
        tester,
        const UserGenderDobFields(pairMinWidth: UserFieldPair.never),
      );
      expect(sideBySide(tester, _gender, _dob), isFalse);

      await pumpCluster(
        tester,
        const UserGenderDobFields(pairMinWidth: UserFieldPair.always),
        initial: {
          _gender: SignupGender.preferNotToSay,
          _dob: DateTime.utc(2010, 9, 24),
        },
        size: kPhoneSurface,
      );
      expect(sideBySide(tester, _gender, _dob), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 61: with enabled off both are off and the gender '
        'does not open', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserGenderDobFields(enabled: false),
      );

      expectEveryFieldOff(tester);
      await tapSelect(tester, _gender);
      expect(find.text('Female'), findsNothing);
      await tester.tap(find.text('Select date of birth'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(form.value[_dob], isNull);
      expect(
        find.byWidgetPredicate(
          (widget) => '${widget.runtimeType}' == 'CalendarNavigationHeader',
        ),
        findsNothing,
        reason: 'the date picker opened',
      );
    });
  });

  group('Issue 61: UserPublicNameFields', () {
    testWidgets('Issue 61: for a viewer who may edit neither, the public '
        'name is a read-only Yes or No', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(),
        initial: const {_useName: true},
      );
      expect(rowLabels(tester), ['Show name publicly']);
      expect(fieldIds(tester), isEmpty);
      expect(find.text('Yes'), findsOneWidget);
      expect(form.fields, isEmpty);

      await pumpCluster(
        tester,
        const UserPublicNameFields(),
        initial: const {_useName: false},
      );
      expect(find.text('No'), findsOneWidget);

      await pumpCluster(tester, const UserPublicNameFields());
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('Issue 61: with canEditUseNamePublicly it is one tick that '
        "starts from the form's value and follows a tap", (tester) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditUseNamePublicly: true),
        initial: const {_useName: true},
      );

      expect(fieldIds(tester), [_useName]);
      expect(find.text('Show name publicly'), findsOneWidget);
      expect(_ticked(tester, _useName), isTrue);

      await tapCheckbox(tester, _useName);
      expect(form.value[_useName], isFalse);
      expect(_ticked(tester, _useName), isFalse);

      await tapCheckbox(tester, _useName);
      expect(form.value[_useName], isTrue);
    });

    testWidgets('Issue 61: with canEditPublicProfile it is two ticks, the '
        'name one off and unticked while the profile is not public', (
      tester,
    ) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        initial: const {_publicProfile: false, _useName: true},
      );

      expect(fieldIds(tester), [_publicProfile, _useName]);
      expect(find.text('Show my profile publicly'), findsOneWidget);
      expect(find.text('Show my name on my public profile'), findsOneWidget);
      expect(find.text('Show name publicly'), findsNothing);
      expect(_ticked(tester, _publicProfile), isFalse);
      expect(_ticked(tester, _useName), isFalse);
      expect(_fieldIsOn(tester, _useName), isFalse);

      await tapCheckbox(tester, _useName);
      expect(form.value[_useName], isFalse, reason: 'the name tick is off');
    });

    testWidgets('Issue 61: making the profile public turns the name tick '
        'on, and making it private again unticks and locks it', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        initial: const {_publicProfile: false, _useName: false},
      );

      await tapCheckbox(tester, _publicProfile);
      expect(form.value[_publicProfile], isTrue);
      expect(_fieldIsOn(tester, _useName), isTrue);
      expect(_ticked(tester, _useName), isFalse);

      await tapCheckbox(tester, _useName);
      expect(form.value[_useName], isTrue);
      expect(_ticked(tester, _useName), isTrue);

      await tapCheckbox(tester, _publicProfile);
      expect(form.value[_publicProfile], isFalse);
      expect(form.value[_useName], isFalse);
      expect(_ticked(tester, _useName), isFalse);
      expect(_fieldIsOn(tester, _useName), isFalse);
    });

    testWidgets('Issue 61: a public profile with a public name opens with '
        'both ticked', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        initial: const {_publicProfile: true, _useName: true},
      );

      expect(_ticked(tester, _publicProfile), isTrue);
      expect(_ticked(tester, _useName), isTrue);
      expect(_fieldIsOn(tester, _useName), isTrue);
      expect(form.value, {_publicProfile: true, _useName: true});
    });

    testWidgets('Issue 61: canEditPublicProfile wins over '
        'canEditUseNamePublicly', (tester) async {
      await pumpCluster(
        tester,
        const UserPublicNameFields(
          canEditPublicProfile: true,
          canEditUseNamePublicly: true,
        ),
      );

      expect(fieldIds(tester), [_publicProfile, _useName]);
    });

    test('Issue 61: useNamePublicly is the tick alone unless the profile '
        'ties it, and then needs the profile public too', () {
      bool read({required bool tied, bool? name, bool? profile}) =>
          UserPublicNameFields.useNamePublicly({
            _useName: name,
            _publicProfile: profile,
          }, canEditPublicProfile: tied);

      expect(read(name: true, profile: false, tied: false), isTrue);
      expect(read(name: false, profile: true, tied: false), isFalse);
      expect(read(tied: false), isFalse);

      expect(read(name: true, profile: true, tied: true), isTrue);
      expect(read(name: true, profile: false, tied: true), isFalse);
      expect(read(name: true, tied: true), isFalse);
      expect(read(name: false, profile: true, tied: true), isFalse);
      expect(read(profile: true, tied: true), isFalse);
    });

    testWidgets('Issue 61: with enabled off no tick follows a tap', (
      tester,
    ) async {
      final single = await pumpCluster(
        tester,
        const UserPublicNameFields(
          enabled: false,
          canEditUseNamePublicly: true,
        ),
      );
      expectEveryFieldOff(tester);
      await tapCheckbox(tester, _useName);
      expect(single.value[_useName], isFalse);

      final pair = await pumpCluster(
        tester,
        const UserPublicNameFields(enabled: false, canEditPublicProfile: true),
        initial: const {_publicProfile: true, _useName: true},
      );
      expectEveryFieldOff(tester);
      await tapCheckbox(tester, _publicProfile);
      await tapCheckbox(tester, _useName);
      expect(pair.value, {_publicProfile: true, _useName: true});
    });

    testWidgets('Issue 61: the two ticks fit a phone', (tester) async {
      await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Issue 61: UserRoleFields', () {
    testWidgets('Issue 61: with canAssignAdmin alone it shows the admin '
        'tick under Roles', (tester) async {
      await pumpCluster(tester, const UserRoleFields(canAssignAdmin: true));

      expect(rowLabels(tester), ['Roles']);
      expect(fieldIds(tester), [_admin]);
      expect(find.text('Make this user an Admin'), findsOneWidget);
      expect(find.text('This user is a coach'), findsNothing);
    });

    testWidgets('Issue 61: with canAssignCoach alone it shows the coach '
        'tick', (tester) async {
      await pumpCluster(tester, const UserRoleFields(canAssignCoach: true));

      expect(fieldIds(tester), [_coach]);
      expect(find.text('This user is a coach'), findsOneWidget);
      expect(find.text('Make this user an Admin'), findsNothing);
    });

    testWidgets('Issue 61: with both, both ticks start unticked and each '
        'follows its own tap', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserRoleFields(canAssignAdmin: true, canAssignCoach: true),
      );

      expect(fieldIds(tester), [_admin, _coach]);
      expect(form.value, {_admin: false, _coach: false});

      await tapCheckbox(tester, _coach);
      expect(form.value, {_admin: false, _coach: true});

      await tapCheckbox(tester, _admin);
      expect(form.value, {_admin: true, _coach: true});

      await tapCheckbox(tester, _coach);
      expect(form.value, {_admin: true, _coach: false});
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: with enabled off neither tick follows a tap', (
      tester,
    ) async {
      final form = await pumpCluster(
        tester,
        const UserRoleFields(
          enabled: false,
          canAssignAdmin: true,
          canAssignCoach: true,
        ),
      );

      expectEveryFieldOff(tester);
      await tapCheckbox(tester, _admin);
      await tapCheckbox(tester, _coach);
      expect(form.value, {_admin: false, _coach: false});
    });
  });

  group('Issue 61: UserDefaultPasswordField', () {
    Future<({ShadFormState form, List<bool> changes, List<int> shown})> pump(
      WidgetTester tester, {
      bool value = true,
      bool enabled = true,
      bool withShow = true,
      Size size = kFormSurface,
    }) async {
      final changes = <bool>[];
      final shown = <int>[];
      final form = await pumpCluster(
        tester,
        UserDefaultPasswordField(
          value: value,
          enabled: enabled,
          onChanged: changes.add,
          onShow: withShow ? () => shown.add(shown.length) : null,
        ),
        size: size,
      );
      return (form: form, changes: changes, shown: shown);
    }

    final show = find.widgetWithText(ShadButton, 'Show');

    testWidgets('Issue 61: it is one tick, ticked from its value, with the '
        'Show action beside it', (tester) async {
      final host = await pump(tester);

      expect(fieldIds(tester), [_useDefault]);
      expect(find.text('Use default password'), findsOneWidget);
      expect(_ticked(tester, _useDefault), isTrue);
      expect(host.form.value[_useDefault], isTrue);
      expect(show, findsOneWidget);
      expectNoHostChrome(tester, allowedButtonTexts: {'Show'});
    });

    testWidgets('Issue 61: a tap tells the host the new value', (tester) async {
      final host = await pump(tester);

      await tapCheckbox(tester, _useDefault);

      expect(host.changes, [false]);
      expect(host.form.value[_useDefault], isFalse);
    });

    testWidgets('Issue 61: Show calls the host, once a tap', (tester) async {
      final host = await pump(tester);

      await tester.tap(show);
      await tester.pumpAndSettle();

      expect(host.shown, hasLength(1));
      expect(host.changes, isEmpty);
    });

    testWidgets('Issue 61: Show is absent when the host gives no action', (
      tester,
    ) async {
      await pump(tester, withShow: false);

      expect(show, findsNothing);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: Show is absent while the default password is '
        'not used', (tester) async {
      await pump(tester, value: false);

      expect(_ticked(tester, _useDefault), isFalse);
      expect(show, findsNothing);
    });

    testWidgets('Issue 61: with enabled off neither the tick nor Show '
        'responds', (tester) async {
      final host = await pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await tapCheckbox(tester, _useDefault);
      await tester.tap(show, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(host.changes, isEmpty);
      expect(host.shown, isEmpty);
      expect(tester.widget<ShadButton>(show).onPressed, isNull);
      expect(host.form.value[_useDefault], isTrue);
    });

    testWidgets('Issue 61: it fits a phone with Show beside the tick', (
      tester,
    ) async {
      await pump(tester, size: kPhoneSurface);

      expect(show, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
