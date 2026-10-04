/// A [SecureClient] whose every source is a `Fake`, so a provider test can
/// supply the one source it exercises and ignore the rest.
///
/// `SecureClient` requires every source, and gains one whenever the SDK
/// grows a domain. Building it here rather than in each test file means a
/// new source is added once.
library;

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminSource extends Fake implements AdminSource {}

class _FakeAuthSource extends Fake implements AuthSource {}

class _FakeUserSource extends Fake implements UserSource {}

class _FakeGroupSource extends Fake implements GroupSource {}

class _FakeVenueSource extends Fake implements VenueSource {}

class _FakeEventSource extends Fake implements EventSource {}

class _FakeEventMarketingSource extends Fake implements EventMarketingSource {}

class _FakeOccurrenceSource extends Fake implements OccurrenceSource {}

class _FakeEnrollmentSource extends Fake implements EnrollmentSource {}

class _FakeAttendanceSource extends Fake implements AttendanceSource {}

class _FakeMyEventsSource extends Fake implements MyEventsSource {}

class _FakeMyGroupsSource extends Fake implements MyGroupsSource {}

class _FakeNotificationSource extends Fake implements NotificationSource {}

class _FakeBroadcastSource extends Fake implements BroadcastSource {}

class _FakeCapabilitiesSource extends Fake implements CapabilitiesSource {}

class _FakeCreditSource extends Fake implements CreditSource {}

class _FakeMyCreditsSource extends Fake implements MyCreditsSource {}

class _FakeAuditLogSource extends Fake implements AuditLogSource {}

class _FakeMediaSource extends Fake implements MediaSource {}

class _FakeUserMediaSource extends Fake implements UserMediaSource {}

class _FakeEventMediaSource extends Fake implements EventMediaSource {}

class _FakeGroupMediaSource extends Fake implements GroupMediaSource {}

class _FakeVenueMediaSource extends Fake implements VenueMediaSource {}

class _FakeEvaluationSource extends Fake implements EvaluationSource {}

class _FakeMyEvaluationsSource extends Fake implements MyEvaluationsSource {}

class _FakeEvaluationMediaSource extends Fake
    implements EvaluationMediaSource {}

class _FakeInquirySource extends Fake implements InquirySource {}

class _FakePublicSource extends Fake implements PublicSource {}

/// Builds a fully-faked client; pass the sources this test drives.
SecureClient fakeSecureClient({
  AdminSource? admin,
  AuthSource? auth,
  UserSource? users,
  GroupSource? groups,
  VenueSource? venues,
  EventSource? events,
  EventMarketingSource? eventMarketing,
  OccurrenceSource? occurrences,
  EnrollmentSource? enrollments,
  AttendanceSource? attendance,
  MyEventsSource? myEvents,
  MyGroupsSource? myGroups,
  NotificationSource? notifications,
  BroadcastSource? broadcasts,
  CapabilitiesSource? capabilities,
  CreditSource? credits,
  MyCreditsSource? myCredits,
  AuditLogSource? auditLog,
  MediaSource? media,
  UserMediaSource? userMedia,
  EventMediaSource? eventMedia,
  GroupMediaSource? groupMedia,
  VenueMediaSource? venueMedia,
  EvaluationSource? evaluations,
  MyEvaluationsSource? myEvaluations,
  EvaluationMediaSource? evaluationMedia,
  InquirySource? inquiries,
  PublicSource? public,
}) {
  return SecureClient(
    admin: admin ?? _FakeAdminSource(),
    auth: auth ?? _FakeAuthSource(),
    users: users ?? _FakeUserSource(),
    groups: groups ?? _FakeGroupSource(),
    venues: venues ?? _FakeVenueSource(),
    events: events ?? _FakeEventSource(),
    eventMarketing: eventMarketing ?? _FakeEventMarketingSource(),
    occurrences: occurrences ?? _FakeOccurrenceSource(),
    enrollments: enrollments ?? _FakeEnrollmentSource(),
    attendance: attendance ?? _FakeAttendanceSource(),
    myEvents: myEvents ?? _FakeMyEventsSource(),
    myGroups: myGroups ?? _FakeMyGroupsSource(),
    notifications: notifications ?? _FakeNotificationSource(),
    broadcasts: broadcasts ?? _FakeBroadcastSource(),
    capabilities: capabilities ?? _FakeCapabilitiesSource(),
    credits: credits ?? _FakeCreditSource(),
    myCredits: myCredits ?? _FakeMyCreditsSource(),
    auditLog: auditLog ?? _FakeAuditLogSource(),
    media: media ?? _FakeMediaSource(),
    userMedia: userMedia ?? _FakeUserMediaSource(),
    eventMedia: eventMedia ?? _FakeEventMediaSource(),
    groupMedia: groupMedia ?? _FakeGroupMediaSource(),
    venueMedia: venueMedia ?? _FakeVenueMediaSource(),
    evaluations: evaluations ?? _FakeEvaluationSource(),
    myEvaluations: myEvaluations ?? _FakeMyEvaluationsSource(),
    evaluationMedia: evaluationMedia ?? _FakeEvaluationMediaSource(),
    inquiries: inquiries ?? _FakeInquirySource(),
    public: public ?? _FakePublicSource(),
  );
}
