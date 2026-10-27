import 'package:cl_club_applications/src/widgets/profile_complete_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'applications_harness.dart';

/// The signed-in member with every printed field filled: Download of their
/// own form does not ask "Is your profile complete?".
UserPrivate completeProfileUser() => applicationsUser().copyWith(
  firstName: () => 'Member',
  lastName: () => 'A',
  dateOfBirthUtc: () => DateTime.utc(2000, 3, 4),
  gender: () => Gender.female,
  phone: () => '+919800000000',
  email: () => 'member_a@example.com',
  address: () => const Address(city: 'Pune'),
  nationality: () => 'Indian',
  preferredLanguages: const ['Marathi'],
  clubDistrict: () => 'Pune',
  preferredPositions: const ['Forward'],
  pastExperience: () => 'Two seasons',
);

/// Answers "Is your profile complete?" with **Yes** (club_client#340) and
/// lets the download run.
Future<void> answerProfileComplete(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProfileCompleteDialog.yesKey));
  await tester.pumpAndSettle();
}
