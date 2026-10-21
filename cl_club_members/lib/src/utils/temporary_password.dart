import 'dart:math';

/// The characters a temporary password is made of: letters and digits
/// without the ones easily misread for another (0/O/o, 1/l/I).
const String temporaryPasswordAlphabet =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';

/// Length of a temporary password: 12 characters of
/// [temporaryPasswordAlphabet] (about 70 bits), well above the server's
/// minimum of 8.
const int temporaryPasswordLength = 12;

/// A fresh random password for a user an admin creates with "Use default
/// password" ticked (club_client#221). Each user gets their own; the admin
/// passes it on and the member changes it.
///
/// [random] is for tests; the default is [Random.secure].
String generateTemporaryPassword({Random? random}) {
  final source = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < temporaryPasswordLength; i++)
      temporaryPasswordAlphabet.codeUnitAt(
        source.nextInt(temporaryPasswordAlphabet.length),
      ),
  ]);
}
