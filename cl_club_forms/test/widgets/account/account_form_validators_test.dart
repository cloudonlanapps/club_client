import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/account/account_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: AccountFormValidators', () {
    test('Issue 61: username refuses an empty one and one of spaces', () {
      expect(AccountFormValidators.username(''), 'Username is required');
      expect(AccountFormValidators.username('   '), 'Username is required');
    });

    test('Issue 61: username accepts any text, padded or not', () {
      expect(AccountFormValidators.username('a'), isNull);
      expect(AccountFormValidators.username('  asha  '), isNull);
    });

    test('Issue 61: password refuses an empty one only', () {
      expect(AccountFormValidators.password(''), 'Password is required');
      expect(AccountFormValidators.password(' '), isNull);
      expect(AccountFormValidators.password('x'), isNull);
    });

    test('Issue 61: currentPassword refuses an empty one only', () {
      expect(
        AccountFormValidators.currentPassword(''),
        'Current password is required',
      );
      expect(AccountFormValidators.currentPassword(' '), isNull);
      expect(AccountFormValidators.currentPassword('old'), isNull);
    });

    test('Issue 61: newPassword refuses an empty one', () {
      expect(AccountFormValidators.newPassword(''), 'New password is required');
    });

    test('Issue 61: newPassword refuses one character short of the minimum '
        'and accepts the minimum', () {
      const min = ChangePasswordFormFields.passwordMinLength;
      expect(min, 8);
      expect(AccountFormValidators.newPassword('a'), 'At least 8 characters');
      expect(
        AccountFormValidators.newPassword('a' * (min - 1)),
        'At least 8 characters',
      );
      expect(AccountFormValidators.newPassword('a' * min), isNull);
      expect(AccountFormValidators.newPassword('a' * (min + 1)), isNull);
    });

    test('Issue 61: confirmation refuses an empty one only', () {
      expect(
        AccountFormValidators.confirmation(''),
        'Please re-type the new password',
      );
      expect(AccountFormValidators.confirmation('x'), isNull);
    });

    test('Issue 61: newPasswordsMatch refuses two that differ, by case or '
        'by a trailing space too', () {
      const differ = 'New passwords do not match';
      expect(AccountFormValidators.newPasswordsMatch('abc', 'abd'), differ);
      expect(AccountFormValidators.newPasswordsMatch('abc', 'ABC'), differ);
      expect(AccountFormValidators.newPasswordsMatch('abc', 'abc '), differ);
      expect(AccountFormValidators.newPasswordsMatch('abc', null), differ);
    });

    test('Issue 61: newPasswordsMatch accepts two that are the same', () {
      expect(AccountFormValidators.newPasswordsMatch('abc', 'abc'), isNull);
      expect(AccountFormValidators.newPasswordsMatch(null, null), isNull);
    });

    test('Issue 61: each message is the constant the hosts read', () {
      expect(AccountFormValidators.usernameRequired, 'Username is required');
      expect(AccountFormValidators.passwordRequired, 'Password is required');
      expect(
        AccountFormValidators.currentPasswordRequired,
        'Current password is required',
      );
      expect(
        AccountFormValidators.newPasswordRequired,
        'New password is required',
      );
      expect(
        AccountFormValidators.newPasswordTooShort,
        'At least 8 characters',
      );
      expect(
        AccountFormValidators.confirmationRequired,
        'Please re-type the new password',
      );
      expect(
        AccountFormValidators.newPasswordsDiffer,
        'New passwords do not match',
      );
    });
  });
}
