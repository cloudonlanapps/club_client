import 'package:cl_club_members/src/utils/temporary_password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 221: a temporary password per created user', () {
    test('Issue 221: 12 characters, none of them a look-alike', () {
      for (var i = 0; i < 200; i++) {
        final password = generateTemporaryPassword();
        expect(password, hasLength(12));
        expect(password, matches(RegExp(r'^[A-Za-z2-9]+$')));
        expect(password, isNot(matches(RegExp('[0O1lIo]'))));
      }
    });

    test('Issue 221: no two are the same, and none is ChangeMe123', () {
      final drawn = {
        for (var i = 0; i < 1000; i++) generateTemporaryPassword(),
      };
      expect(drawn, hasLength(1000));
      expect(drawn, isNot(contains('ChangeMe123')));
    });
  });
}
