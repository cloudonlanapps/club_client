import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserFormFields;
import 'package:cl_member_onboarding/src/models/reapply_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the phone a reapplication carried.
class _RecordingNotifier extends ClUsersMasterNotifier {
  final UserPrivate answer = UserPrivate(
    username: 'robin',
    displayName: 'Robin',
    status: UserStatus.registered,
    isSuperAdmin: false,
    roles: const UserRoles(),
    email: 'robin@example.test',
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );

  String? phone;
  Gender? gender;

  @override
  Future<UserPrivate> reapplyForSelf({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirthUtc,
    Gender? gender,
    String? phone,
    String? email,
  }) async {
    this.phone = phone;
    this.gender = gender;
    return answer;
  }
}

Future<String?> _reappliedPhone(String typed, String code) async {
  final notifier = _RecordingNotifier();
  final updated = await ReapplyFormSubmit.reapply(
    notifier: notifier,
    defaultCountryCode: code,
    values: {
      UserFormFields.emailId: 'robin@example.test',
      UserFormFields.phoneId: typed,
      UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
      UserFormFields.genderId: SignupGender.female,
      UserFormFields.firstNameId: null,
      UserFormFields.middleNameId: null,
      UserFormFields.lastNameId: null,
    },
  );
  expect(updated, same(notifier.answer));
  expect(notifier.gender, Gender.female);
  return notifier.phone;
}

void main() {
  group('Issue 31: ReapplyFormSubmit.reapply stores an international '
      'phone', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          expect(await _reappliedPhone(typed, code), '+${code}9876543210');
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      expect(await _reappliedPhone('+44 98765 43210', '91'), '+449876543210');
      expect(await _reappliedPhone('0044 98765-43210', '91'), '+449876543210');
    });
  });

  group('Issue 59: the reapply adapter speaks the form by its named ids', () {
    test('Issue 59: the initial values are keyed by the form ids, and a '
        'field never filled has no entry', () {
      final user = UserPrivate(
        username: 'robin',
        displayName: 'Robin',
        status: UserStatus.registered,
        isSuperAdmin: false,
        roles: const UserRoles(),
        email: 'robin@example.test',
        firstName: 'Robin',
        gender: Gender.other,
        createdAtUtc: DateTime.utc(2024, 6, 15),
      );

      expect(buildReapplyFormInitialValues(user), {
        UserFormFields.firstNameId: 'Robin',
        UserFormFields.genderId: SignupGender.other,
        UserFormFields.emailId: 'robin@example.test',
      });
    });

    test('Issue 59: no bare string field id is left in the adapter', () {
      final source = File(
        'lib/src/models/reapply_form_helpers.dart',
      ).readAsStringSync();
      expect(RegExp(r"""\[['"]\w+['"]\]""").hasMatch(source), isFalse);
      expect(RegExp(r"""['"]\w+['"]:""").hasMatch(source), isFalse);
    });
  });
}
