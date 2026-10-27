import 'package:club_sdk_2/club_sdk_2.dart' show Address, Guardian, UserPrivate;

import '../constants/application_view_strings.dart';

/// Age below which a member's form prints their guardian.
const int guardianAgeLimit = 18;

/// The fields every application form prints from [user]'s profile that are
/// blank on it, by the profile's labels, in the profile's order
/// (club_client#340). The server prints the same member block on every
/// form (club_server `member_document`).
///
/// Always: first and last name, date of birth, gender, phone, email and
/// address. While [extendedProfile]: nationality, preferred language, club
/// district, preferred position, past experience and, for a member under
/// [guardianAgeLimit] on [today] by date of birth, the guardian. With no
/// date of birth the date itself is listed and the guardian is not. The
/// middle name (optional) and the membership date (an admin's) are never
/// listed.
///
/// A text is blank when null, empty or whitespace; an address when none of
/// its parts is filled; a guardian when it has neither a name nor a phone.
List<String> blankProfileFields(
  UserPrivate user, {
  required bool extendedProfile,
  required DateTime today,
}) {
  final dateOfBirth = user.dateOfBirthUtc;
  return [
    if (isBlankText(user.firstName)) ApplicationViewStrings.fieldFirstName,
    if (isBlankText(user.lastName)) ApplicationViewStrings.fieldLastName,
    if (dateOfBirth == null) ApplicationViewStrings.fieldDateOfBirth,
    if (user.gender == null) ApplicationViewStrings.fieldGender,
    if (isBlankText(user.phone)) ApplicationViewStrings.fieldPhone,
    if (isBlankText(user.email)) ApplicationViewStrings.fieldEmail,
    if (isBlankAddress(user.address)) ApplicationViewStrings.fieldAddress,
    if (extendedProfile) ...[
      if (isBlankText(user.nationality))
        ApplicationViewStrings.fieldNationality,
      if (isBlankText(user.preferredLanguage))
        ApplicationViewStrings.fieldPreferredLanguage,
      if (isBlankText(user.clubDistrict))
        ApplicationViewStrings.fieldClubDistrict,
      if (isBlankText(user.preferredPosition))
        ApplicationViewStrings.fieldPreferredPosition,
      if (isBlankText(user.pastExperience))
        ApplicationViewStrings.fieldPastExperience,
      if (dateOfBirth != null &&
          ageOn(dateOfBirth, today) < guardianAgeLimit &&
          isBlankGuardian(user.guardian))
        ApplicationViewStrings.fieldGuardian,
    ],
  ];
}

/// Whether [text] is null, empty or whitespace.
bool isBlankText(String? text) => text == null || text.trim().isEmpty;

/// Whether [address] has none of its parts filled.
bool isBlankAddress(Address? address) =>
    address == null ||
    [
      address.addrLine1,
      address.addrLine2,
      address.city,
      address.state,
      address.pincode,
    ].every(isBlankText);

/// Whether [guardian] has neither a name nor a phone.
bool isBlankGuardian(Guardian? guardian) =>
    guardian == null ||
    (isBlankText(guardian.name) && isBlankText(guardian.phone));

/// Age in whole years on [today]'s calendar day of someone born on
/// [dateOfBirthUtc], a date-only value at UTC midnight.
int ageOn(DateTime dateOfBirthUtc, DateTime today) {
  final years = today.year - dateOfBirthUtc.year;
  final birthdayPassed =
      today.month > dateOfBirthUtc.month ||
      (today.month == dateOfBirthUtc.month && today.day >= dateOfBirthUtc.day);
  return birthdayPassed ? years : years - 1;
}
