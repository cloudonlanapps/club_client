/// A scriptable [PublicSource] and a container wired to it, for the public
/// provider tests (club_core#53).
library;

import 'package:cl_remote_store/src/providers/public_source.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The API base every public test runs against.
const String testApiBase = 'https://api.example.com/v1';

/// A [PublicSource] answering from fields a test sets, recording each call.
class FakePublicSource extends Fake implements PublicSource {
  List<PublicEvent> events = const [];
  PublicEvent? event;
  EventMarketing? marketing;
  Exception? marketingError;
  List<PublicProfile> staff = const [];
  List<PublicVenue> venues = const [];
  PublicVenue? venue;
  PublicClubInfo clubInfo = const PublicClubInfo();
  String token = 'token-1';

  /// When set, every read throws it.
  Exception? failWith;

  final List<String> calls = [];
  final List<Map<String, Object?>> listEventArgs = [];
  final List<bool> staffGuestArgs = [];
  final List<Map<String, Object?>> inquiries = [];

  void fail() {
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<PaginatedList<PublicEvent>> listPublicEvents({
    EventType? type,
    DateTime? from,
    DateTime? to,
    bool? featured,
    String? venueId,
    int? offset,
    int? limit,
  }) async {
    calls.add('listPublicEvents');
    listEventArgs.add({'type': type, 'featured': featured, 'limit': limit});
    fail();
    return PaginatedList(
      items: events,
      total: events.length,
      limit: limit ?? 20,
      offset: 0,
    );
  }

  @override
  Future<PublicEvent> getPublicEvent(String publicId) async {
    calls.add('getPublicEvent:$publicId');
    fail();
    return event!;
  }

  @override
  Future<EventMarketing> getPublicEventMarketing(String publicId) async {
    calls.add('getPublicEventMarketing:$publicId');
    final error = marketingError;
    if (error != null) throw error;
    return marketing!;
  }

  @override
  Future<List<PublicProfile>> listPublicStaff({
    bool includeGuests = false,
  }) async {
    calls.add('listPublicStaff');
    staffGuestArgs.add(includeGuests);
    fail();
    return staff;
  }

  @override
  Future<List<PublicVenue>> listPublicVenues() async {
    calls.add('listPublicVenues');
    fail();
    return venues;
  }

  @override
  Future<PublicVenue> getPublicVenue(String publicId) async {
    calls.add('getPublicVenue:$publicId');
    fail();
    return venue!;
  }

  @override
  Future<PublicClubInfo> getPublicClubInfo() async {
    calls.add('getPublicClubInfo');
    fail();
    return clubInfo;
  }

  @override
  Future<String> getInquiryFormToken() async {
    calls.add('getInquiryFormToken');
    fail();
    return token;
  }

  @override
  Future<void> submitInquiry({
    required InquiryKind kind,
    required String name,
    required String email,
    required String message,
    required String token,
    String? phone,
    Map<String, dynamic>? extra,
    String? website,
  }) async {
    calls.add('submitInquiry');
    fail();
    inquiries.add({
      'kind': kind,
      'name': name,
      'email': email,
      'message': message,
      'token': token,
      'phone': phone,
      'extra': extra,
      'website': website,
    });
  }
}

/// A network monitor that records what the providers told it, instead of
/// pinging `/health`.
class RecordingNetworkStatus extends NetworkStatusNotifier {
  RecordingNetworkStatus(super.ref);

  int checks = 0;
  int onlines = 0;

  @override
  void checkNow() => checks++;

  @override
  void markOnline() => onlines++;
}

/// A container whose public source is [source] and whose network monitor
/// is a [RecordingNetworkStatus], plus any further [overrides].
ProviderContainer publicContainer(
  FakePublicSource source, {
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: testApiBase),
      ),
      clPublicSourceProvider.overrideWithValue(source),
      networkStatusProvider.overrideWith(RecordingNetworkStatus.new),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// The recording monitor [container] was built with.
RecordingNetworkStatus networkMonitor(ProviderContainer container) =>
    container.read(networkStatusProvider.notifier) as RecordingNetworkStatus;

/// A minimal public venue.
PublicVenue testVenue(String publicId) =>
    PublicVenue(publicId: publicId, name: 'Rink $publicId');

/// A minimal public event.
PublicEvent testEvent(
  String publicId, {
  EventType type = EventType.camp,
  bool isPast = false,
  bool isFeatured = false,
}) => PublicEvent(
  publicId: publicId,
  title: 'Event $publicId',
  description: '',
  type: type,
  venueId: 'v1',
  startTimeUtc: DateTime.utc(2026, 10),
  endTimeUtc: DateTime.utc(2026, 10, 2),
  venue: testVenue('v1'),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  isPast: isPast,
  isFeatured: isFeatured,
);
