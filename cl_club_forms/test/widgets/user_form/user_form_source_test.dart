import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

const _widgets = 'lib/src/widgets';

/// The eight account and user forms.
const _forms = [
  '$_widgets/account/login_form.dart',
  '$_widgets/account/change_password_form.dart',
  '$_widgets/account/forgot_password_form.dart',
  '$_widgets/signup/signup_form.dart',
  '$_widgets/user_form/user_form.dart',
  '$_widgets/user_form/user_personal_details_form.dart',
  '$_widgets/user_form/user_contact_form.dart',
  '$_widgets/user_form/user_address_form.dart',
];

/// The forms and everything they are built from.
List<File> _sources() => [
  for (final dir in ['account', 'signup', 'user_form'])
    ...Directory(
      '$_widgets/$dir',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
];

void main() {
  group('Issue 53: the account and user forms are built from the helpers', () {
    test('Issue 53: every form mixes in FormContract and takes enabled', () {
      for (final path in _forms) {
        final source = File(path).readAsStringSync();
        expect(source, contains('with FormContract<'), reason: path);
        expect(source, contains('final bool enabled;'), reason: path);
      }
    });

    test('Issue 53: no form keeps a submit callback, a submitting flag, a '
        'button, a title or a width', () {
      for (final path in _forms) {
        final source = File(path).readAsStringSync();
        for (final gone in [
          'handleSubmit',
          'onSubmit;',
          'isSubmitting',
          'ShadButton',
          'ConstrainedBox',
          'textTheme.h',
        ]) {
          expect(source, isNot(contains(gone)), reason: '$path: $gone');
        }
      }
    });

    test('Issue 53: no field labels itself, and no gap is a number', () {
      for (final file in _sources()) {
        // The username field's own hint and check row are parts of one
        // composite field, not rows of a form.
        if (file.path.endsWith('username_availability_field.dart')) continue;
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains(' label: const Text(')),
          reason: file.path,
        );
        expect(source, isNot(contains('SizedBox(height')), reason: file.path);
        expect(
          RegExp(r'spacing: \d').hasMatch(source),
          isFalse,
          reason: file.path,
        );
      }
    });

    test('Issue 53: each user field is declared once, in a shared cluster', () {
      // A field id → the files that declare a field with it.
      final declarations = <String, Set<String>>{};
      for (final file in _sources()) {
        final source = file.readAsStringSync();
        for (final match in RegExp(
          r'\bid: UserFormFields\.(\w+Id)\b',
        ).allMatches(source)) {
          declarations.putIfAbsent(match.group(1)!, () => {}).add(file.path);
        }
      }
      expect(declarations, isNotEmpty);
      expect(
        {
          for (final entry in declarations.entries)
            if (entry.value.length != 1) entry.key: entry.value,
        },
        isEmpty,
        reason: 'fields declared in more than one file',
      );
      for (final path in _forms.skip(3)) {
        expect(
          File(path).readAsStringSync(),
          isNot(contains('id: UserFormFields.')),
          reason: '$path declares a field itself',
        );
      }
    });
  });

  group('Issue 59: the account and user forms name their field ids', () {
    test('Issue 59: no bare string field id is left in the forms', () {
      for (final file in _sources()) {
        final source = file.readAsStringSync();
        expect(
          RegExp(r"""\bid: ['"]""").hasMatch(source),
          isFalse,
          reason: file.path,
        );
        expect(
          RegExp(r"""\[['"]\w+['"]\]""").hasMatch(source),
          isFalse,
          reason: '${file.path} reads a value by a bare string',
        );
      }
    });

    test('Issue 59: the ids keep the values the adapters and the '
        'integration suite know', () {
      expect(
        [LoginFormFields.usernameId, LoginFormFields.passwordId],
        ['username', 'password'],
      );
      expect(
        [
          ChangePasswordFormFields.currentId,
          ChangePasswordFormFields.nextId,
          ChangePasswordFormFields.confirmId,
        ],
        ['current', 'next', 'confirm'],
      );
      expect(ForgotPasswordFormFields.emailId, 'email');
      expect(UserFormFields.userIds, [
        'username',
        'password',
        'confirmPassword',
        'useDefaultPassword',
        'firstName',
        'middleName',
        'lastName',
        'nickname',
        'useNamePublicly',
        'isPublicProfile',
        'gender',
        'dateOfBirthUtc',
        'addrLine1',
        'addrLine2',
        'city',
        'state',
        'pincode',
        'email',
        'phone',
        'emergencyContactName',
        'emergencyContactRelation',
        'emergencyContactPhone',
        'medicalInfo',
        'assignAdmin',
        'assignCoach',
      ]);
      expect(
        UserFormFields.signupIds.toSet().difference(
          UserFormFields.userIds.toSet(),
        ),
        isEmpty,
      );
    });
  });
}
