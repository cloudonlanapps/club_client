import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The event types this club runs (club_core#115).
///
/// Club configuration, not server capability: the host app overrides it from
/// its `club.json` (`eventTypes`). Staff lists, occurrence feeds and create
/// shortcuts cover these types only. Defaults to camps alone, which is what a
/// club that does not configure it has always seen.
final Provider<Set<EventType>> clubEventTypesProvider =
    Provider<Set<EventType>>((ref) => const {EventType.camp});
