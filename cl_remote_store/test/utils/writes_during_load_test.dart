// The writes a master makes while it loads are applied over what the load
// brings back (club_client#137).
import 'dart:async';

import 'package:cl_remote_store/src/utils/writes_during_load.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue 137: a put and a remove made during a load are applied over '
      'its listing, in order', () async {
    final writes = WritesDuringLoad<int, String>();
    final gate = Completer<Map<int, String>>();

    final load = writes.load(() => gate.future);
    writes
      ..put(null, 2, 'created')
      ..put(null, 2, 'renamed')
      ..remove(null, 1);
    gate.complete({1: 'one', 3: 'three'});

    expect(await load, {3: 'three', 2: 'renamed'});
  });

  test('Issue 137: a write made with no load in flight is not kept for the '
      'next load', () async {
    final writes = WritesDuringLoad<int, String>()..put(null, 2, 'stale');

    expect(await writes.load(() async => {1: 'one'}), {1: 'one'});

    writes.remove(null, 1);
    expect(await writes.load(() async => {1: 'one'}), {1: 'one'});
  });

  test(
    'Issue 137: the writes go over a listing that cannot be changed',
    () async {
      final writes = WritesDuringLoad<int, String>();
      final gate = Completer<Map<int, String>>();

      final load = writes.load(() => gate.future);
      writes.put(null, 1, 'one');
      gate.complete(const {});

      expect(await load, {1: 'one'});
    },
  );

  test('Issue 137: when a newer load takes over, it applies the writes made '
      'since it began and the older one applies none', () async {
    final writes = WritesDuringLoad<int, String>();
    final first = Completer<Map<int, String>>();
    final second = Completer<Map<int, String>>();

    final older = writes.load(() => first.future);
    writes.put(null, 1, 'before the newer load');
    final newer = writes.load(() => second.future);
    writes.put(null, 2, 'during the newer load');
    first.complete({});
    second.complete({1: 'listed'});

    expect(await older, isEmpty);
    expect(await newer, {1: 'listed', 2: 'during the newer load'});
  });

  test('Issue 137: a load that fails leaves the next load clean', () async {
    final writes = WritesDuringLoad<int, String>();

    final failing = writes.load(() async => throw StateError('down'));
    writes.put(null, 1, 'one');
    await expectLater(failing, throwsStateError);

    expect(await writes.load(() async => {}), isEmpty);
  });

  test('Issue 137: put and remove give back the map with the write made, '
      'or null when there is no map yet', () {
    final writes = WritesDuringLoad<int, String>();
    const current = {1: 'one'};

    expect(writes.put(current, 2, 'two'), {1: 'one', 2: 'two'});
    expect(writes.remove(current, 1), isEmpty);
    expect(current, {1: 'one'});
    expect(writes.put(null, 2, 'two'), isNull);
    expect(writes.remove(null, 1), isNull);
  });
}
