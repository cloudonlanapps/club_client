// Issue 230: DOB UTC midnight mismatch.
//
// The DOB picker emits a *local* DateTime; group/event date-bounds are stored
// as UTC midnight. When the host TZ is east of UTC, a user born on the same
// calendar date as the lower bound was reported as ineligible because the
// local DateTime serialized to the previous UTC day. The user form now floors
// DOB to UTC midnight on submit (mirroring the server's `truncate_to_utc_day`
// fix for `users.date_of_birth` from `club_server#100`). These tests
// pin that contract: a DOB constructed exactly as the picker emits it, then
// passed through the form submit floor, must satisfy the eligibility check
// at both inclusive boundaries — and fail one day outside either.

import 'package:cl_remote_store/src/utils/event_eligibility.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show UserFormAssembly;

Event _ageWindow({
  required DateTime dobOnOrAfterUtc,
  required DateTime dobOnOrBeforeUtc,
}) {
  final now = DateTime.utc(2026);
  return Event(
    id: 1,
    title: 'E',
    description: '',
    type: EventType.camp,
    visibility: Visibility.private,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
  );
}

UserPrivate _userWithPickedDob(DateTime pickedLocal) {
  // Simulate the production submit path: the picker emits a local DateTime,
  // the form floors it to UTC midnight before writing to the SDK.
  final floored = UserFormAssembly.floorToUtcMidnight(pickedLocal)!;
  return UserPrivate(
    username: 'u',
    displayName: 'U',
    firstName: 'U',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2020),
    dateOfBirthUtc: floored,
  );
}

void main() {
  final event = _ageWindow(
    // Spelling out month/day keeps the boundary-date intent obvious even
    // though they match Dart's defaults.
    dobOnOrAfterUtc: DateTime.utc(2014, 1, 1),
    dobOnOrBeforeUtc: DateTime.utc(2017, 12, 31),
  );

  group('Issue 230: DOB UTC midnight mismatch (post-floor contract)', () {
    test('DOB exactly on the lower bound (local 1-Jan-2014) → eligible', () {
      // Spelling out month/day keeps the boundary-date intent obvious even
      // though they match Dart's defaults.
      final picked = DateTime(2014, 1, 1);
      expect(
        checkEventEligibility(event: event, user: _userWithPickedDob(picked)),
        isNull,
      );
    });

    test('DOB exactly on the upper bound (local 31-Dec-2017) → eligible', () {
      final picked = DateTime(2017, 12, 31);
      expect(
        checkEventEligibility(event: event, user: _userWithPickedDob(picked)),
        isNull,
      );
    });

    test('DOB one day below the lower bound (local 31-Dec-2013) → '
        'dobOutOfWindow', () {
      final picked = DateTime(2013, 12, 31);
      final f = checkEventEligibility(
        event: event,
        user: _userWithPickedDob(picked),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.dobOutOfWindow);
    });

    test('DOB one day above the upper bound (local 1-Jan-2018) → '
        'dobOutOfWindow', () {
      // Spelling out month/day keeps the boundary-date intent obvious even
      // though they match Dart's defaults.
      final picked = DateTime(2018, 1, 1);
      final f = checkEventEligibility(
        event: event,
        user: _userWithPickedDob(picked),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.dobOutOfWindow);
    });

    test('DOB inside the window (local 1-Jun-2015) → eligible', () {
      final picked = DateTime(2015, 6, 15);
      expect(
        checkEventEligibility(event: event, user: _userWithPickedDob(picked)),
        isNull,
      );
    });
  });
}
