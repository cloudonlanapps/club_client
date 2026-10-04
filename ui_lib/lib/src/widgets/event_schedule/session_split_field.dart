import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/session_input.dart';
import 'duration_picker_dropdown.dart';

/// Shared "split a window into named session segments" editor.
///
/// Used by both the programme and camp schedule fields so the two share one
/// session editor. Splits a fixed [totalMinutes] window (whose first segment
/// starts at [startTime]) into named segments, owning the per-segment
/// durations + name controllers and the absorb/spill reallocation logic.
///
/// Emits the resulting sessions via [onChanged] — empty for the trivial
/// single unnamed segment, so the host doesn't store a redundant
/// `[Session 1]` list. The host owns the Duration input; when [totalMinutes]
/// changes the editor resets to a single full segment.
class SessionSplitField extends StatefulWidget {
  const SessionSplitField({
    required this.totalMinutes,
    required this.startTime,
    required this.initialSessions,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int totalMinutes;
  final ShadTimeOfDay? startTime;
  final List<SessionInput> initialSessions;
  final ValueChanged<List<SessionInput>> onChanged;
  final bool enabled;

  /// Sum minutes from a `SessionInput` start/end pair. Tolerant of both
  /// 24-hour `HH:MM[:SS]` and legacy `h:mm AM/PM` strings.
  static int sessionMinutes(SessionInput s) {
    final start = parseHM(s.startTime);
    final end = parseHM(s.endTime);
    if (start == null || end == null) return 0;
    return end - start;
  }

  static int? parseHM(String hm) =>
      parseStandardHM(hm) ?? parseTwelveHourHM(hm);

  /// Strict 24-hour `HH:MM` or `HH:MM:SS`. Returns null on any departure
  /// from that shape — the canonical write format.
  static int? parseStandardHM(String hm) {
    final text = hm.trim();
    final parts = text.split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Backwards-compat fallback for legacy `h:mm AM/PM` strings.
  static int? parseTwelveHourHM(String hm) {
    var text = hm.trim().toUpperCase();
    var pmOffset = 0;
    var isAm = false;
    if (text.endsWith('AM')) {
      isAm = true;
      text = text.substring(0, text.length - 2).trim();
    } else if (text.endsWith('PM')) {
      pmOffset = 12 * 60;
      text = text.substring(0, text.length - 2).trim();
    } else {
      return null;
    }
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    var hour = h;
    if (hour == 12 && (isAm || pmOffset > 0)) hour = 0;
    return hour * 60 + m + pmOffset;
  }

  static String formatHM(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String formatDuration(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.truncateToDouble()) return '${hours.toInt()}h';
    if (hours < 1) return '${minutes}m';
    final whole = hours.truncate();
    final fraction = minutes - whole * 60;
    if (fraction == 30) return '${whole}h 30m';
    return '${whole}h ${fraction}m';
  }

  @override
  State<SessionSplitField> createState() => SessionSplitFieldState();
}

class SessionSplitFieldState extends State<SessionSplitField> {
  late List<int> sessionDurations;
  late List<TextEditingController> sessionNameControllers;

  @override
  void initState() {
    super.initState();
    _seed(widget.initialSessions, widget.totalMinutes);
  }

  void _seed(List<SessionInput> sessions, int total) {
    if (sessions.isEmpty) {
      sessionDurations = [total];
      sessionNameControllers = [TextEditingController()];
    } else {
      sessionDurations = [
        for (final s in sessions) SessionSplitField.sessionMinutes(s),
      ];
      sessionNameControllers = [
        for (final s in sessions) TextEditingController(text: s.name),
      ];
    }
  }

  @override
  void didUpdateWidget(SessionSplitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The host's Duration input changed: reset to a single full segment.
    // The host resets its own stored sessions to `[]` in the same gesture,
    // so the editor only needs to mirror that visually (no emit here).
    if (oldWidget.totalMinutes != widget.totalMinutes) {
      for (final c in sessionNameControllers) {
        c.dispose();
      }
      setState(() {
        sessionDurations = [widget.totalMinutes];
        sessionNameControllers = [TextEditingController()];
      });
    }
  }

  @override
  void dispose() {
    for (final c in sessionNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get assignedMinutes => sessionDurations.fold(0, (a, b) => a + b);

  int sumBefore(int index) =>
      sessionDurations.take(index).fold<int>(0, (a, b) => a + b);

  void onSessionDurationChanged(int index, Duration picked) {
    final pickedMinutes = picked.inMinutes;
    setState(() {
      final oldValue = sessionDurations[index];
      final delta = pickedMinutes - oldValue;
      sessionDurations[index] = pickedMinutes;

      if (delta > 0) {
        var toAbsorb = delta;
        while (toAbsorb > 0 && sessionDurations.length > index + 1) {
          final lastIdx = sessionDurations.length - 1;
          final dur = sessionDurations[lastIdx];
          if (dur <= toAbsorb) {
            sessionNameControllers[lastIdx].dispose();
            sessionDurations.removeAt(lastIdx);
            sessionNameControllers.removeAt(lastIdx);
            toAbsorb -= dur;
          } else {
            sessionDurations[lastIdx] = dur - toAbsorb;
            toAbsorb = 0;
          }
        }
      } else if (delta < 0) {
        final freed = -delta;
        if (index + 1 < sessionDurations.length) {
          sessionDurations[index + 1] += freed;
        } else {
          sessionDurations.add(freed);
          sessionNameControllers.add(TextEditingController());
        }
      }
    });
    _emit();
  }

  void removeSession(int index) {
    if (sessionDurations.length <= 1) return;
    setState(() {
      final freed = sessionDurations.removeAt(index);
      sessionNameControllers.removeAt(index).dispose();
      sessionDurations[sessionDurations.length - 1] += freed;
    });
    _emit();
  }

  void onSessionNameChanged(int index, String name) => _emit();

  /// Returns `[]` for the trivial single-row case so the host doesn't store a
  /// redundant `[Session 1]` list.
  List<SessionInput> buildSessions() {
    final start = widget.startTime;
    if (start == null || sessionDurations.length <= 1) {
      return const [];
    }
    final result = <SessionInput>[];
    var cursor = start.hour * 60 + start.minute;
    for (var i = 0; i < sessionDurations.length; i++) {
      final dur = sessionDurations[i];
      final name = sessionNameControllers[i].text.trim();
      result.add(
        SessionInput(
          name: name.isEmpty ? 'Session ${i + 1}' : name,
          startTime: SessionSplitField.formatHM(cursor),
          endTime: SessionSplitField.formatHM(cursor + dur),
        ),
      );
      cursor += dur;
    }
    return result;
  }

  void _emit() => widget.onChanged(buildSessions());

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final enabled = widget.enabled;
    final remainder = widget.totalMinutes - assignedMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (var i = 0; i < sessionDurations.length; i++)
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: sessionNameControllers[i],
                  enabled: enabled,
                  keyboardType: TextInputType.text,
                  placeholder: Text('Session ${i + 1}'),
                  onChanged: (text) => onSessionNameChanged(i, text),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: DurationPickerDropdown(
                  value: Duration(minutes: sessionDurations[i]),
                  enabled: enabled,
                  max: Duration(
                    minutes: widget.totalMinutes - sumBefore(i),
                  ),
                  onChanged: (picked) => onSessionDurationChanged(i, picked),
                ),
              ),
              SizedBox(
                width: 28,
                child: sessionDurations.length > 1
                    ? IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: enabled ? () => removeSession(i) : null,
                        icon: const Icon(LucideIcons.x),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        if (remainder > 0)
          Text(
            '${SessionSplitField.formatDuration(remainder)} unassigned.',
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
      ],
    );
  }
}
