import 'package:club_sdk_2/club_sdk_2.dart';

/// API base the fixtures' media URLs are built against.
const testApiBase = 'https://api.example.test/v1';

/// The venue every fixture event is held at.
const testVenue = PublicVenue(publicId: 'pv-rink', name: 'Riverside Rink');

/// A public event of [type], starting 4 May 2026 10:00 local.
PublicEvent testPublicEvent({
  String publicId = 'pe-1',
  String title = 'Spring Camp',
  String description = '',
  EventType type = EventType.camp,
  String? rrule,
  DateTime? start,
  Duration length = const Duration(hours: 2),
  List<EventSession>? sessions,
  bool isPast = false,
  bool isFeatured = false,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  List<MediaRef> gallery = const [],
  List<PublicProfile> coaches = const [],
  EventMarketingBasic? marketing,
}) {
  final startLocal = start ?? DateTime(2026, 5, 4, 10);
  return PublicEvent(
    publicId: publicId,
    title: title,
    description: description,
    type: type,
    venueId: testVenue.publicId,
    rrule: rrule,
    startTimeUtc: startLocal.toUtc(),
    endTimeUtc: startLocal.add(length).toUtc(),
    sessions: sessions,
    isPast: isPast,
    isFeatured: isFeatured,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
    gallery: gallery,
    venue: testVenue,
    coaches: coaches,
    marketing: marketing,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}
