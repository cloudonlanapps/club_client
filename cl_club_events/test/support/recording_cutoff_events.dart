import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

/// An events master holding [event] that records each of the five cutoff
/// calls with the event `version` it was sent, as `verb(v<version>)`
/// (`verb(vnull)` when the caller gave none), and throws [error] when set.
class RecordingCutoffEvents extends ClEventsMasterNotifier {
  RecordingCutoffEvents(this.event);

  final Event event;

  /// The cutoff calls, in order.
  final List<String> calls = [];

  /// When set, every cutoff call throws this instead of answering.
  Exception? error;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  Event answer(String verb, int? version) {
    calls.add('$verb(v$version)');
    final refused = error;
    if (refused != null) throw refused;
    return event;
  }

  @override
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
    int? version,
  }) async => answer('cancelSeries', version);

  @override
  Future<Event> undoCancelSeries(int eventId, {int? version}) async =>
      answer('undoCancelSeries', version);

  @override
  Future<Event> terminate(
    int eventId, {
    required String reason,
    required DateTime cutoffTimeUtc,
    int? version,
  }) async => answer('terminate', version);

  @override
  Future<Event> extend(
    int eventId, {
    required DateTime cutoffTimeUtc,
    String? reason,
    int? version,
  }) async => answer('extend', version);

  @override
  Future<Event> extendIndefinitely(
    int eventId, {
    String? reason,
    int? version,
  }) async => answer('extendIndefinitely', version);
}

/// The refusal of a cutoff call whose event `another_admin` changed first.
StaleVersionException staleCutoff() => StaleVersionException(
  message: 'stale',
  version: 9,
  updatedAtUtc: DateTime.utc(2026, 9, 26, 10),
  updatedBy: 'another_admin',
);
