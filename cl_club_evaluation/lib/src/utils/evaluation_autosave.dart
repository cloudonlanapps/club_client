import 'dart:async';

import 'package:ui_lib/ui_lib.dart' show EvaluationAnswerValue;

/// Writes each answer of a draft once it settles: a change waits [delay]
/// for the next, and only the last is written. Writes run one at a time,
/// in order. A settled answer that [holdWhileTyping] keeps back waits,
/// unwritten, while its field has the focus ([focusChanged]): it is written
/// once the focus leaves, or by [flush].
class EvaluationAutosave {
  /// Autosave through [write], reporting failures to [onError].
  EvaluationAutosave({
    required this.delay,
    required this.write,
    required this.onError,
    this.holdWhileTyping,
  });

  /// How long an answer must stay unchanged.
  final Duration delay;

  /// Writes one answer.
  final Future<void> Function(int itemId, EvaluationAnswerValue answer) write;

  /// Told of a failed write.
  final void Function(Object error) onError;

  /// Whether a settled answer waits while its field has the focus — e.g.
  /// one that would ask a question mid-typing.
  final bool Function(int itemId, EvaluationAnswerValue answer)?
  holdWhileTyping;

  /// The ids of the items whose field has the focus.
  final Set<int> typingIn = {};

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
    timers[itemId] = Timer(delay, () => settle(itemId));
  }

  /// The answer to [itemId] has settled: written, unless held while typing.
  void settle(int itemId) {
    timers.remove(itemId);
    final answer = pending[itemId];
    if (answer == null) return;
    final held =
        typingIn.contains(itemId) &&
        (holdWhileTyping?.call(itemId, answer) ?? false);
    if (!held) unawaited(send(itemId));
  }

  /// Notes the focus entering or leaving the field of [itemId]; leaving
  /// writes the answer held there, while one still settling waits its turn.
  void focusChanged(int itemId, {required bool hasFocus}) {
    if (hasFocus) {
      typingIn.add(itemId);
      return;
    }
    typingIn.remove(itemId);
    if (!timers.containsKey(itemId) && pending.containsKey(itemId)) {
      unawaited(send(itemId));
    }
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
