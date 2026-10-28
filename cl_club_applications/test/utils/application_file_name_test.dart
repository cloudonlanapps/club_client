import 'package:cl_club_applications/src/utils/application_file_name.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

UserPrivate _member({
  String? firstName,
  String? middleName,
  String? lastName,
  String? nickname,
}) => UserPrivate(
  username: 'robin_h',
  displayName: nickname ?? 'Robin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  firstName: firstName,
  middleName: middleName,
  lastName: lastName,
  nickname: nickname,
);

void main() {
  group('Issue 404: memberFormFileName', () {
    test('Issue 404: names the form after the application and the member’s '
        'full name', () {
      expect(
        memberFormFileName(
          'Trial',
          _member(firstName: 'Robin', middleName: 'of', lastName: 'Loxley'),
        ),
        'Trial - Robin of Loxley.pdf',
      );
    });

    test('Issue 404: uses the full name, not the nickname', () {
      expect(
        memberFormFileName(
          'Trial',
          _member(firstName: 'Robin', lastName: 'Hood', nickname: 'Hoodie'),
        ),
        'Trial - Robin Hood.pdf',
      );
    });

    test('Issue 404: skips blank name parts', () {
      expect(
        memberFormFileName(
          'Trial',
          _member(firstName: ' Robin ', middleName: '  ', lastName: 'Hood'),
        ),
        'Trial - Robin Hood.pdf',
      );
    });

    test('Issue 404: a member with no name is named by their username', () {
      expect(
        memberFormFileName('Trial', _member(nickname: 'Hoodie')),
        'Trial - robin_h.pdf',
      );
    });

    test('Issue 404: replaces the characters a file name cannot hold', () {
      expect(
        memberFormFileName('U/12: form?', _member(firstName: 'A"B')),
        'U_12_ form_ - A_B.pdf',
      );
    });
  });
}
