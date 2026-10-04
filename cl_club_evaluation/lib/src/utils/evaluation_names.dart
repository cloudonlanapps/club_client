import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEventDetailProvider, clUserInfoProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/evaluation_view_strings.dart';

/// Names an evaluation shows instead of ids: a person's display name and
/// an event's title, read from the providers any signed-in user may read.
abstract final class EvaluationNames {
  /// [username]'s display name; the username until it loads.
  static String person(WidgetRef ref, String username) =>
      ref.watch(clUserInfoProvider(username)).valueOrNull?.displayName ??
      username;

  /// The title of event [eventId] as [member] sees it, or "General" for
  /// none; empty until it loads.
  static String event(WidgetRef ref, {required String member, int? eventId}) {
    if (eventId == null) return EvaluationViewStrings.general;
    final key = (username: member, eventId: eventId);
    return ref.watch(clMyEventDetailProvider(key)).valueOrNull?.title ?? '';
  }
}
