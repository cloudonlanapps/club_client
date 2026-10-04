import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEnrollmentsMasterProvider,
        clEvaluationTemplatesMasterProvider,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EnrollmentStatus, UserInfo, UserPrivate, UserStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationStartChoice;

import '../constants/evaluation_view_strings.dart';
import '../models/start_review_options.dart';
import 'evaluation_names.dart';

/// Reads what the start form offers from the masters.
abstract final class StartReviewChoices {
  /// The enrolment statuses that count as taking part in an event.
  static const Set<EnrollmentStatus> enrolled = {
    EnrollmentStatus.accepted,
    EnrollmentStatus.assigned,
    EnrollmentStatus.assignedTrial,
    EnrollmentStatus.withdrawRequested,
  };

  /// Of [events], the ones each member is [enrolled] in, keyed by username.
  static Map<String, List<EvaluationStartChoice>> byMember(
    WidgetRef ref,
    List<EvaluationStartChoice> events,
  ) {
    final result = <String, List<EvaluationStartChoice>>{};
    for (final e in events) {
      final roster =
          ref.watch(clEnrollmentsMasterProvider(e.id)).valueOrNull ?? const {};
      for (final MapEntry(key: username, value: status) in roster.entries) {
        if (enrolled.contains(status)) {
          (result[username] ??= []).add(e);
        }
      }
    }
    return result;
  }

  /// The active events [coach] (a username) coaches, by title.
  static List<EvaluationStartChoice> coachedEvents(
    WidgetRef ref,
    String coach,
  ) {
    final events = ref.watch(clEventsMasterProvider).valueOrNull ?? const {};
    return [
      for (final e in events.values)
        if (e.isActive && (e.coachNames ?? const []).contains(coach))
          (id: e.id, label: e.title),
    ]..sort((a, b) => a.label.compareTo(b.label));
  }

  /// The events [coach] may review [member] for — the ones the start form
  /// offers once that member is chosen: [coachedEvents] the member is
  /// [enrolled] in.
  static List<EvaluationStartChoice> eventsFor(
    WidgetRef ref, {
    required String coach,
    required String member,
  }) => byMember(ref, coachedEvents(ref, coach))[member] ?? const [];

  /// The options for [coach]; [templateId], [username] and [eventId] fix
  /// the matching field. The member list is read only when the member is
  /// not fixed.
  static StartReviewOptions read(
    WidgetRef ref, {
    required UserPrivate coach,
    int? templateId,
    String? username,
    int? eventId,
  }) {
    final templates =
        ref.watch(clEvaluationTemplatesMasterProvider).valueOrNull ?? const {};
    final events = ref.watch(clEventsMasterProvider).valueOrNull ?? const {};
    final users = username == null
        ? ref.watch(clUsersMasterProvider).valueOrNull ?? const {}
        : const <String, UserInfo>{};
    final template = templateId == null ? null : templates[templateId];
    final event = eventId == null ? null : events[eventId];
    final coached = coachedEvents(ref, coach.username);
    return (
      templates: [
        for (final t in templates.values)
          if (t.deletedAtUtc == null) (id: t.id, label: t.name),
      ]..sort((a, b) => a.label.compareTo(b.label)),
      members: [
        for (final u in users.values)
          if (u.status == UserStatus.active &&
              !u.isSuperAdmin &&
              u.username != coach.username)
            (username: u.username, label: u.displayName),
      ]..sort((a, b) => a.label.compareTo(b.label)),
      events: coached,
      eventsByMember: eventId == null ? byMember(ref, coached) : const {},
      fixedTemplate: templateId == null
          ? null
          : (id: templateId, label: template?.name ?? ''),
      fixedMember: username == null
          ? null
          : (username: username, label: EvaluationNames.person(ref, username)),
      fixedEvent: eventId == null
          ? null
          : (id: eventId, label: event?.title ?? EvaluationViewStrings.event),
    );
  }
}
