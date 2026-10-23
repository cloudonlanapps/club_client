// Seeding through the SDK, for tests that need data the site only reads.
//
// The website has no screen that creates anything, so a test's fixtures are
// written through the SDK as the super-admin, and removed the same way.
//
// Owns:
//   * sudoClient      - a logged-in SDK client for the super-admin.
//   * dayAt           - a whole-minute UTC time relative to today.
//   * weeklyOn        - the one rule shape the server takes for a programme.
//   * seedCoach       - a coach, with or without a public profile and a photo.
//   * removeEvent, removeVenue, removeUser - delete a fixture for good.

import 'package:cl_remote_store/cl_remote_store.dart' show kUserAvatarTag;
import 'package:club_sdk_2/club_sdk_2.dart';

import 'pump.dart' show createTestClient;

/// A logged-in SDK client for the super-admin. Log it out when done.
Future<SecureClient> sudoClient({
  required String baseUrl,
  required String username,
  required String password,
}) async {
  final client = await createTestClient(baseUrl: baseUrl);
  await client.auth.login(username, password);
  return client;
}

/// Today at [hour]:00 UTC plus [days] (negative for the past). Never a fixed
/// date: the server refuses a camp or one-off past its scheduling horizon.
DateTime dayAt(int days, {int hour = 10}) {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day, hour).add(
    Duration(days: days),
  );
}

const _weekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// A programme's rule, weekly on [start]'s weekday.
String weeklyOn(DateTime start) =>
    'FREQ=WEEKLY;BYDAY=${_weekdays[start.weekday - 1]}';

/// The password of every user a test seeds.
const seededPassword = 'seeded-password-1';

/// A coach as the site names one: first and last name, used publicly.
String coachDisplayName(String firstName, String lastName) =>
    '$firstName $lastName';

/// Creates the coach [username] as [admin].
///
/// A public profile is the coach's own choice, which an admin cannot make
/// for them, so with [publicProfile] the coach logs in and turns it on. With
/// [photo] a public avatar is uploaded and attached; the returned record is
/// that file, or null.
Future<Media?> seedCoach(
  SecureClient admin, {
  required String baseUrl,
  required String username,
  required String firstName,
  required String lastName,
  required bool publicProfile,
  String? bio,
  bool photo = false,
}) async {
  await admin.users.createUser(
    username: username,
    email: '$username@example.com',
    passwordHash: seededPassword,
    phone: '0000000000',
    dateOfBirthUtc: DateTime.utc(1990),
    gender: Gender.female,
    firstName: firstName,
    lastName: lastName,
    bio: bio,
  );
  await admin.users.assignRole(username, 'coach');

  final coach = await createTestClient(baseUrl: baseUrl);
  await coach.auth.login(username, seededPassword);
  try {
    await coach.users.updateUser(
      username,
      useNamePublicly: true,
      isPublicProfile: publicProfile,
    );
  } finally {
    await coach.auth.logout();
  }

  if (!photo) return null;
  final media = await admin.media.upload(
    fileBytes: onePixelPng,
    filename: '$username.png',
    contentType: 'image/png',
    preserveOriginal: true,
    accessRoles: const ['public'],
    ownerUsername: username,
  );
  await admin.userMedia.attach(
    username,
    tag: kUserAvatarTag,
    mediaUuid: media.uuid,
  );
  return media;
}

/// Deletes the event for good.
Future<void> removeEvent(SecureClient admin, int eventId) async {
  final event = await admin.events.getEvent(eventId);
  if (event.deletedAtUtc == null) await admin.events.deleteEvent(eventId);
  await admin.events.hardDeleteEvent(eventId);
}

/// Deletes the venue for good.
Future<void> removeVenue(SecureClient admin, int venueId) async {
  await admin.venues.deleteVenue(venueId);
  await admin.venues.hardDeleteVenue(venueId);
}

/// Deletes the user for good.
Future<void> removeUser(SecureClient admin, String username) async {
  await admin.users.deleteUser(username);
  await admin.users.hardDeleteUser(username);
}

/// A valid 1x1 white PNG (69 bytes).
const List<int> onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00, //
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, //
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0x0D, 0xEF, 0x46, 0xB8, 0x00, 0x00, 0x00, //
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];
