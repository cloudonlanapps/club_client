import 'dart:async';

import 'package:ui_lib/ui_lib.dart' show EvaluationAnswerValue;

/// Writes each answer of a draft once it settles: a change waits [delay]
/// for the next, and only the last is written. Writes run one at a time,
/// in order.
class EvaluationAutosave {
  /// Autosave through [write], reporting failures to [onError].
  EvaluationAutosave({
    required this.delay,
    required this.write,
    required this.onError,
  });

  /// How long an answer must stay unchanged.
  final Duration delay;

  /// Writes one answer.
  final Future<void> Function(int itemId, EvaluationAnswerValue answer) write;

  /// Told of a failed write.
  final void Function(Object error) onError;

  /// The waits running, by item id.
  final Map<int, Timer> timers = {};

  /// The answers waiting to be written, by item id.
  final Map<int, EvaluationAnswerValue> pending = {};

  /// The last write queued; each write starts after it.
  Future<void> queue = Future<void>.value();

  /// Writes [answer] to [itemId] once it has settled.
  void schedule(int itemId, EvaluationAnswerValue answer) {
    pending[itemId] = answer;
    timers.remove(itemId)?.cancel();
    timers[itemId] = Timer(delay, () => send(itemId));
  }

  /// Queues the pending answer to [itemId], if any.
  Future<void> send(int itemId) {
    timers.remove(itemId)?.cancel();
    final answer = pending.remove(itemId);
    if (answer == null) return queue;
    return queue = queue.then((_) async {
      try {
        await write(itemId, answer);
      } on Object catch (e) {
        onError(e);
      }
    });
  }

  /// Writes every pending answer now, and waits for every write.
  Future<void> flush() async {
    for (final id in pending.keys.toList()) {
      unawaited(send(id));
    }
    await queue;
  }

  /// Stops waiting; pending answers are still written.
  void dispose() => unawaited(flush());
}
