import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: UserFormValidators.username', () {
    test('Issue 61: an empty username, or one of spaces, is required', () {
      expect(UserFormValidators.username(''), 'Username is required');
      expect(UserFormValidators.username('   '), 'Username is required');
    });

    test('Issue 61: two characters are too few and three are enough', () {
      expect(UserFormFields.usernameMinLength, 3);
      expect(UserFormValidators.username('a'), 'At least 3 characters');
      expect(UserFormValidators.username('ab'), 'At least 3 characters');
      expect(UserFormValidators.username('abc'), isNull);
    });

    test('Issue 61: the length is counted without the padding', () {
      expect(UserFormValidators.username(' ab '), 'At least 3 characters');
      expect(UserFormValidators.username(' abc '), isNull);
    });

    test('Issue 61: an uppercase letter, a space, a dash or a dot is '
        'refused', () {
      const message = 'Only lowercase letters, digits, and _';
      for (final bad in ['Robin', 'ro bin', 'ro-bin', 'ro.bin', 'robin!']) {
        expect(UserFormValidators.username(bad), message, reason: bad);
      }
    });

    test('Issue 61: lowercase letters, digits and _ are accepted', () {
      for (final good in ['robin', 'robin_9', '___', '123', 'a1_']) {
        expect(UserFormValidators.username(good), isNull, reason: good);
      }
    });
  });

  group('Issue 61: UserFormValidators.email', () {
    test('Issue 61: an empty email, or one of spaces, is required', () {
      expect(UserFormValidators.email(''), 'Email is required');
      expect(UserFormValidators.email('  '), 'Email is required');
    });

    test('Issue 61: an email without @ is refused', () {
      expect(UserFormValidators.email('robin'), 'Enter a valid email');
      expect(
        UserFormValidators.email('robin.example.test'),
        'Enter a valid email',
      );
    });

    test('Issue 61: an address with @ is accepted, padded or not', () {
      expect(UserFormValidators.email('robin@example.test'), isNull);
      expect(UserFormValidators.email('  robin@example.test '), isNull);
    });
  });

  group('Issue 61: UserFormValidators, the password', () {
    test('Issue 61: an empty password is required', () {
      expect(UserFormValidators.password(''), 'Password is required');
    });

    test('Issue 61: seven characters are too few and eight are enough', () {
      expect(UserFormFields.passwordMinLength, 8);
      expect(UserFormValidators.password('1234567'), 'At least 8 characters');
      expect(UserFormValidators.password('12345678'), isNull);
      expect(UserFormValidators.password('123456789'), isNull);
    });

    test('Issue 61: spaces count as characters of a password', () {
      expect(UserFormValidators.password(' ' * 8), isNull);
    });

    test('Issue 61: an empty confirmation is required, anything else is '
        'left to the rule across the two', () {
      expect(
        UserFormValidators.confirmPassword(''),
        'Please confirm the password',
      );
      expect(UserFormValidators.confirmPassword('x'), isNull);
    });

    test('Issue 61: passwordsMatch refuses two that differ', () {
      const differ = 'Passwords do not match';
      expect(UserFormValidators.passwordsDiffer, differ);
      expect(UserFormValidators.passwordsMatch('abc', 'abd'), differ);
      expect(UserFormValidators.passwordsMatch('abc', 'ABC'), differ);
      expect(UserFormValidators.passwordsMatch('abc', 'abc '), differ);
      expect(UserFormValidators.passwordsMatch('abc', null), differ);
      expect(UserFormValidators.passwordsMatch(null, 'abc'), differ);
    });

    test('Issue 61: passwordsMatch accepts two that are the same, and takes '
        'a missing one as empty', () {
      expect(UserFormValidators.passwordsMatch('abc', 'abc'), isNull);
      expect(UserFormValidators.passwordsMatch(null, null), isNull);
      expect(UserFormValidators.passwordsMatch(null, ''), isNull);
      expect(UserFormValidators.passwordsMatch('', null), isNull);
    });
  });

  group('Issue 61: UserFormValidators, the phones', () {
    test('Issue 61: phone is required', () {
      expect(UserFormValidators.phone(''), 'Phone number is required');
      expect(UserFormValidators.phone('   '), 'Phone number is required');
    });

    test('Issue 61: phone refuses nine characters and accepts ten', () {
      expect(UserFormFields.phoneMinLength, 10);
      expect(
        UserFormValidators.phone('987654321'),
        'Enter a valid phone number',
      );
      expect(UserFormValidators.phone('9876543210'), isNull);
      expect(UserFormValidators.phone('+91 9876543210'), isNull);
    });

    test('Issue 61: phone counts its length without the padding', () {
      expect(
        UserFormValidators.phone('  987654321  '),
        'Enter a valid phone number',
      );
    });

    test('Issue 61: phoneOptional accepts an empty phone', () {
      expect(UserFormValidators.phoneOptional(''), isNull);
      expect(UserFormValidators.phoneOptional('   '), isNull);
    });

    test('Issue 61: phoneOptional refuses nine characters and accepts '
        'ten', () {
      expect(
        UserFormValidators.phoneOptional('987654321'),
        'Enter a valid phone number',
      );
      expect(UserFormValidators.phoneOptional('9876543210'), isNull);
    });
  });

  group('Issue 61: UserFormValidators, gender, date of birth and pincode', () {
    test('Issue 61: gender is required', () {
      expect(UserFormValidators.gender(null), 'Gender is required');
    });

    test('Issue 61: every gender is accepted', () {
      for (final gender in SignupGender.values) {
        expect(UserFormValidators.gender(gender), isNull, reason: gender.name);
      }
    });

    test('Issue 61: date of birth is required', () {
      expect(UserFormValidators.dateOfBirth(null), 'Date of birth is required');
      expect(UserFormValidators.dateOfBirth(DateTime(2010, 3, 4)), isNull);
    });

    test('Issue 61: pincode may be empty', () {
      expect(UserFormValidators.pincode(''), isNull);
      expect(UserFormValidators.pincode('  '), isNull);
    });

    test('Issue 61: pincode refuses five digits, seven digits and '
        'anything that is not a digit', () {
      const message = 'Enter a valid 6-digit pincode';
      for (final bad in ['41100', '4110011', '41100a', '411 001', '-11001']) {
        expect(UserFormValidators.pincode(bad), message, reason: bad);
      }
    });

    test('Issue 61: pincode accepts six digits, padded or not', () {
      expect(UserFormValidators.pincode('411001'), isNull);
      expect(UserFormValidators.pincode(' 411001 '), isNull);
      expect(UserFormValidators.pincode('000000'), isNull);
    });
  });

  group('Issue 61: UserFormValidators.atLeastOneName', () {
    test('Issue 61: neither name is refused, empty, of spaces or missing', () {
      const message = 'First name or last name is required';
      expect(UserFormValidators.atLeastOneName('', ''), message);
      expect(UserFormValidators.atLeastOneName('  ', ' '), message);
      expect(UserFormValidators.atLeastOneName(null, null), message);
    });

    test('Issue 61: either name alone is enough', () {
      expect(UserFormValidators.atLeastOneName('Robin', ''), isNull);
      expect(UserFormValidators.atLeastOneName(null, 'Rao'), isNull);
      expect(UserFormValidators.atLeastOneName('Robin', 'Rao'), isNull);
    });
  });

  test('Issue 61: the availability message is the one the hosts read', () {
    expect(
      UserFormValidators.availabilityCheckRequired,
      'Run the availability check before creating the account.',
    );
    expect(
      UserFormValidators.confirmPasswordRequired,
      'Please confirm the password',
    );
  });
}
