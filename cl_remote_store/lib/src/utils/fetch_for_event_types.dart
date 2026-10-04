import 'package:club_sdk_2/club_sdk_2.dart';

/// Calls [fetch] once per type in [types] and concatenates the results, or
/// once unfiltered (`null`) when [types] covers every [EventType].
Future<List<T>> fetchForEventTypes<T>(
  Set<EventType> types,
  Future<List<T>> Function(EventType? type) fetch,
) async {
  if (types.containsAll(EventType.values)) return fetch(null);
  final results = await Future.wait([
    for (final type in EventType.values)
      if (types.contains(type)) fetch(type),
  ]);
  return [for (final list in results) ...list];
}
