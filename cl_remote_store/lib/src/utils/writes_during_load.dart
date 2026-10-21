/// The local writes a master makes while one of its loads is in flight
/// (club_client#74, #137).
///
/// The listing a load brings back may have been read before a write reached
/// the server. A master runs each load through [load] and makes each local
/// write with [put] or [remove]; the writes made since the load
/// began are applied again over its listing, so a row created while the
/// master loads is not lost and a removed one does not come back.
class WritesDuringLoad<K, V> {
  Object? _load;
  final _writes = <void Function(Map<K, V> map)>[];

  /// Runs [fetch] as the master's load and returns its map with the writes
  /// made meanwhile applied over it.
  Future<Map<K, V>> load(Future<Map<K, V>> Function() fetch) async {
    final load = _load = Object();
    _writes.clear();
    try {
      final fetched = await fetch();
      // A newer load has taken over: this result is dropped, and the writes
      // are that load's to apply.
      if (!identical(_load, load) || _writes.isEmpty) return fetched;
      final map = Map.of(fetched);
      for (final write in _writes) {
        write(map);
      }
      return map;
    } finally {
      if (identical(_load, load)) _load = null;
    }
  }

  /// The master puts [value] at [key]. Returns its map with the row put, or
  /// null when [current] is null: it has no map yet, and the row reaches it
  /// when the load ends.
  Map<K, V>? put(Map<K, V>? current, K key, V value) {
    if (_load != null) _writes.add((map) => map[key] = value);
    return current == null ? null : {...current, key: value};
  }

  /// The master replaces its whole map with [next] (a save of the whole
  /// map, club_client#234). Returns [next]: unlike a put, the result does
  /// not depend on what the master held.
  Map<K, V> replaceAll(Map<K, V> next) {
    if (_load != null) {
      _writes.add(
        (map) => map
          ..clear()
          ..addAll(next),
      );
    }
    return Map.of(next);
  }

  /// The master removes [key]. Returns its map without the row, or null when
  /// [current] is null.
  Map<K, V>? remove(Map<K, V>? current, K key) {
    if (_load != null) _writes.add((map) => map.remove(key));
    return current == null ? null : (Map.of(current)..remove(key));
  }
}
