import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleData,
        CampScheduleForm,
        CampScheduleFormFields,
        CampScheduleFormState,
        EventTimetableFormValidators;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../models/camp_schedule_form_helpers.dart';
import '../../models/stale_version_message.dart';
import '../../utils/time_formatter.dart' show formatTimeRange;
import '../events_preview/cl_event_schedule.dart' show ClEventScheduleBody;
import 'schedule_note.dart';

/// Inline schedule (reschedule) section for a camp event detail page.
///
/// Read mode reuses [ClEventScheduleBody]; edit mode hosts the SDK-free
/// [CampScheduleForm] (the same editor the create flow uses) and commits via
/// [CampScheduleFormSubmit.updateSchedule]. The edit pencil shows only when the
/// viewer is an admin and the camp may still be rescheduled
/// ([canRescheduleCamp]). Mirrors `EventEligibilityCard`.
class CampScheduleSection extends ConsumerStatefulWidget {
  const CampScheduleSection({
    required this.event,
    required this.canEdit,
    this.lockReason,
    super.key,
  });

  final Event event;

  /// Whether the viewer is allowed to manage the schedule at all (i.e. an
  /// admin). The pencil is shown to such viewers even when the camp can't
  /// currently be rescheduled, so they get a tap-time explanation rather than a
  /// silently missing affordance. Non-admins see read-only with no pencil.
  final bool canEdit;

  /// Why the schedule can't be rescheduled right now (camp started / series
  /// cancelled), or `null` when it can. When set, tapping the pencil surfaces
  /// this as a toast instead of opening the editor, and it's shown as a muted
  /// lock note below the schedule.
  final String? lockReason;

  @override
  ConsumerState<CampScheduleSection> createState() =>
      CampScheduleSectionState();
}

class CampScheduleSectionState extends ConsumerState<CampScheduleSection> {
  final _formKey = GlobalKey<CampScheduleFormState>();

  /// Set by the pre-edit check when the admin agreed to discard the series'
  /// per-occurrence overrides; forwarded to the reschedule so it clears them.
  bool _resetOverrides = false;

  /// Whether a save is in flight: the form's fields are then off.
  bool saving = false;

  /// Per-occurrence daily duration of the event as currently stored.
  int get _currentDurationMinutes =>
      widget.event.endTimeUtc.difference(widget.event.startTimeUtc).inMinutes;

  bool get _hasSplit => (widget.event.sessions?.length ?? 0) >= 2;

  /// Runs when the admin taps the edit pencil, before the editor opens. Lists
  /// the series' per-occurrence overrides (rescheduled or cancelled days);
  /// rescheduling the series clears them, so we surface exactly which days are
  /// affected and require confirmation. Returns `true` to open the editor.
  ///
  /// Detection uses [Occurrence.isRescheduled] (true for any start/end/venue/
  /// organizer override) plus a `cancelled` status — the same set the server's
  /// reschedule guard counts. If the lookup fails we open the editor anyway;
  /// the on-save guard still catches `OCCURRENCE_OVERRIDES_PRESENT`.
  Future<bool> _onBeforeEdit() async {
    _resetOverrides = false;
    // Camp started or series cancelled: explain on tap instead of editing.
    final lock = widget.lockReason;
    if (lock != null) {
      ShadToaster.of(context).show(ShadToast(description: Text(lock)));
      return false;
    }
    final event = widget.event;
    List<Occurrence> overrides;
    try {
      final occurrences = await ref.read(
        clOccurrencesProvider((
          from: event.startTimeUtc,
          to: lastOccurrenceEndUtc(event),
        )).future,
      );
      overrides = occurrences
          .where((o) => o.eventId == event.id && _isOverride(o))
          .toList();
    } on Object catch (_) {
      return true; // fail open; the on-save guard is the safety net
    }
    if (overrides.isEmpty) return true;
    if (!mounted) return false;
    final proceed = await _confirmClearOverrides(overrides);
    if (proceed != true) return false;
    _resetOverrides = true;
    return true;
  }

  bool _isOverride(Occurrence o) =>
      o.isRescheduled || o.status == OccurrenceStatus.cancelled;

  Future<bool> _save(Map<String, dynamic> values) async {
    final data = values[CampScheduleFormFields.scheduleId] as CampScheduleData;
    // Changing the daily duration clears the session split (the form resets it
    // on a duration change). Remind the admin before committing so they don't
    // silently lose a timetable they meant to keep.
    final durationChanged = data.durationMinutes != _currentDurationMinutes;
    if (_hasSplit && durationChanged && data.sessions.isEmpty) {
      final proceed = await _confirmSplitReset();
      if (proceed != true) return false; // stay in edit mode to re-add sessions
    }
    // `_resetOverrides` reflects the admin's decision from the pre-edit check.
    setState(() => saving = true);
    try {
      return await _commit(data, resetOverrides: _resetOverrides);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Commits the reschedule (a single atomic call carrying the window and the
  /// session split — see #706). The pre-edit check usually settles overrides up
  /// front, but if any appear between opening the editor and saving the server
  /// rejects the whole change with `OCCURRENCE_OVERRIDES_PRESENT` (atomically,
  /// so nothing is applied); we then ask whether to discard those edits and
  /// retry once with `resetOverrides: true`. A stale version (#68) closes the
  /// editor on the reloaded camp and says who changed it and when. A split
  /// the server refuses shows on the schedule field.
  Future<bool> _commit(
    CampScheduleData data, {
    required bool resetOverrides,
  }) async {
    try {
      await CampScheduleFormSubmit.updateSchedule(
        event: widget.event,
        data: data,
        notifier: ref.read(clEventsMasterProvider.notifier),
        resetOverrides: resetOverrides,
      );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Schedule updated.')),
      );
      return true;
    } on StaleVersionException catch (e) {
      // Someone else changed the camp since it was loaded, and the camp
      // master has reloaded it. Close the editor on the reloaded schedule
      // rather than keep edits made against the old one.
      if (!mounted) return true;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This camp')),
        ),
      );
      return true;
    } on ServerException catch (e) {
      if (e.code == SdkErrorCode.occurrenceOverridesPresent &&
          !resetOverrides) {
        final proceed = await _confirmOverrideReset(e);
        if (proceed != true) return false; // keep the per-occurrence edits
        return _commit(data, resetOverrides: true);
      }
      if (!mounted) return false;
      if (e.code == SdkErrorCode.invalidSessionsTotal) {
        _formKey.currentState?.showErrors(
          fieldErrors: {CampScheduleFormFields.scheduleId: _messageFor(e)},
        );
        return false;
      }
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(_messageFor(e))),
      );
      return false;
    } on Object catch (_) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update schedule. Please try again.'),
        ),
      );
      return false;
    }
  }

  String _messageFor(ServerException e) {
    switch (e.code) {
      case SdkErrorCode.eventAlreadyStarted:
        return campStartedMessage;
      case SdkErrorCode.invalidSessionsTotal:
        return EventTimetableFormValidators.totalMismatchMessage;
      case SdkErrorCode.occurrenceOverridesPresent:
        return 'Some occurrences have been individually edited. Reset those '
            'before rescheduling the series.';
      default:
        return 'Could not update schedule. Please try again.';
    }
  }

  Future<bool?> _confirmOverrideReset(ServerException e) {
    final raw = e.details?['occurrenceTimeUtcs'];
    final count = raw is List ? raw.length : null;
    final phrase = switch (count) {
      null => 'Some occurrences have',
      1 => '1 occurrence has',
      _ => '$count occurrences have',
    };
    return showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Discard individual occurrence edits?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep edits'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard & reschedule'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '$phrase been individually rescheduled or cancelled. Rescheduling '
            'the whole series discards those per-occurrence changes. Continue?',
          ),
        ),
      ),
    );
  }

  /// Pre-edit confirmation listing exactly which days carry an override, shown
  /// before the editor opens. Confirming clears them on the subsequent
  /// reschedule and the admin re-applies any still needed afterward.
  Future<bool?> _confirmClearOverrides(List<Occurrence> overrides) {
    final theme = ShadTheme.of(context);
    final shown = overrides.take(8).toList();
    final extra = overrides.length - shown.length;
    return showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('This series has individual day edits'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear & reschedule'),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Rescheduling the whole series will clear these per-day '
                'changes. You can re-apply them after rescheduling.',
                style: theme.textTheme.p,
              ),
              const SizedBox(height: 12),
              for (final o in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${_describeOverride(o)}',
                    style: theme.textTheme.small,
                  ),
                ),
              if (extra > 0)
                Text('• and $extra more…', style: theme.textTheme.small),
            ],
          ),
        ),
      ),
    );
  }

  /// Human-readable summary of what was overridden on [o].
  String _describeOverride(Occurrence o) {
    final day = formatDate(o.originalStartTimeUtc.toLocal());
    if (o.status == OccurrenceStatus.cancelled) {
      final reason = o.cancelReason?.trim();
      return reason == null || reason.isEmpty
          ? '$day — cancelled'
          : '$day — cancelled ($reason)';
    }
    if (o.actualStartTimeUtc != o.originalStartTimeUtc) {
      final time = formatTimeRange(o.actualStartTimeUtc, o.actualEndTimeUtc);
      return '$day — moved to $time';
    }
    if (o.venueId != widget.event.venueId) return '$day — venue changed';
    if ((o.organizerName ?? '') != (widget.event.organizerName ?? '')) {
      return '$day — organizer changed';
    }
    return '$day — rescheduled';
  }

  Future<bool?> _confirmSplitReset() {
    return showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Session split will be cleared'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Go back'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Changing the daily duration clears the named-session split. '
            'Continue and re-add the sessions afterward, or go back to keep '
            'the current duration.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final hint = widget.lockReason;
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Schedule',
      leadingIcon: LucideIcons.calendarClock,
      canEdit: widget.canEdit,
      editMaxWidth: 560,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClEventScheduleBody(event: event),
          if (widget.canEdit && hint != null) ...[
            const SizedBox(height: 12),
            ScheduleNote(text: hint),
          ],
        ],
      ),
      editBuilder: () => CampScheduleForm(
        key: _formKey,
        initialValue: buildCampScheduleInitialValues(event),
        enabled: !saving,
      ),
      onValidate: () => _formKey.currentState?.validate(),
      isDirty: () => _formKey.currentState?.isDirty ?? false,
      onBeforeEdit: _onBeforeEdit,
      onSave: _save,
    );
  }
}
