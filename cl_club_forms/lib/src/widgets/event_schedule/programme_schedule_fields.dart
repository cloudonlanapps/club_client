import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/programme_schedule_data.dart';
import '../../models/session_input.dart';
import '../form/labeled_form_row.dart';
import 'programme_schedule_form_validators.dart';
import 'schedule_duration_field.dart';
import 'session_split_field.dart';
import 'time_picker_empty_parts.dart';
import 'two_column_grid.dart';
import 'weekday_selector.dart';

/// Hard cap on the sum of programme session durations. A single
/// programme session running longer than four hours is almost certainly
/// a configuration mistake; reject it at the form layer.
const int maxProgrammeDurationMinutes = 4 * 60;

/// `ShadForm`-compatible field for programme event schedule.
///
/// Bundles weekday selection, date range, session start time, total
/// duration, and an optional named-session split into a single
/// [ProgrammeScheduleData] value.
///
/// Drop into any [ShadForm]:
///
/// ```dart
/// ProgrammeScheduleFormField(id: 'schedule', initialValue: data)
/// ```
class ProgrammeScheduleFormField
    extends ShadFormBuilderField<ProgrammeScheduleData> {
  ProgrammeScheduleFormField({
    super.key,
    super.id,
    super.label,
    super.description,
    super.error,
    super.enabled,
    super.initialValue,
    super.validator,
    super.onChanged,
    super.onReset,
    super.onSaved,
    super.autovalidateMode,
    super.forceErrorText,
    bool showDateRange = true,
  }) : super(
         builder: (state) => ProgrammeScheduleFormFieldBody(
           state: state,
           showDateRange: showDateRange,
         ),
       );

  /// Aggregate validator surfaced on `saveAndValidate()`.
  static String? aggregateValidator(ProgrammeScheduleData? value) {
    if (value == null) return 'Schedule is required';
    if (value.weekdays.isEmpty) return 'Pick at least one day';
    if (value.startDate == null) return 'Start date is required';
    if (value.sessionStartTime == null) return 'Start time is required';
    if (value.totalDurationMinutes <= 0) {
      return 'Duration must be greater than 0';
    }
    if (value.totalDurationMinutes > maxProgrammeDurationMinutes) {
      return 'Programme session cannot exceed 4h';
    }
    if (!value.hasNoEndDate &&
        value.endDate != null &&
        value.startDate != null &&
        value.endDate!.isBefore(value.startDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }

  /// Session-segment helpers live on the shared [SessionSplitField]; kept here
  /// as thin delegators for callers that reference them via this field.
  static int sessionMinutes(SessionInput s) =>
      SessionSplitField.sessionMinutes(s);

  static int? parseHM(String hm) => SessionSplitField.parseHM(hm);

  static String formatHM(int minutes) => SessionSplitField.formatHM(minutes);
}

/// Body for [ProgrammeScheduleFormField]. Public per project guideline.
class ProgrammeScheduleFormFieldBody extends StatefulWidget {
  const ProgrammeScheduleFormFieldBody({
    required this.state,
    this.showDateRange = true,
    super.key,
  });

  final FormFieldState<ProgrammeScheduleData> state;

  /// Whether the Start Date and End Date inputs are shown. Hidden when the
  /// host decides when the schedule begins (an adjustment from a session).
  final bool showDateRange;

  @override
  State<ProgrammeScheduleFormFieldBody> createState() =>
      ProgrammeScheduleFormFieldBodyState();
}

class ProgrammeScheduleFormFieldBodyState
    extends State<ProgrammeScheduleFormFieldBody> {
  late Set<int> selectedWeekdays;
  late DateTime? selectedStartDate;
  late DateTime? selectedEndDate;
  late bool hasNoEndDate;
  late ShadTimeOfDay? selectedSessionStartTime;
  late int totalDurationMinutes;
  late List<SessionInput> sessions;
  final GlobalKey<SessionSplitFieldState> _splitKey = GlobalKey();
  final GlobalKey<FormFieldState<ShadTimeOfDay>> _startTimeKey = GlobalKey();
  late ShadTimePickerController sessionStartTimeController;
  int endDateResetCounter = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.state.value ?? const ProgrammeScheduleData();
    selectedWeekdays = Set<int>.from(data.weekdays);
    selectedStartDate = data.startDate;
    selectedEndDate = data.endDate;
    hasNoEndDate = data.hasNoEndDate;
    selectedSessionStartTime = data.sessionStartTime;
    totalDurationMinutes = data.totalDurationMinutes;
    sessions = List<SessionInput>.from(data.sessions);
    if (sessions.isNotEmpty) {
      totalDurationMinutes = sessions.fold(
        0,
        (a, s) => a + SessionSplitField.sessionMinutes(s),
      );
    }
    sessionStartTimeController = ShadTimePickerController(
      hour: data.sessionStartTime?.hour,
      // Pre-seed so onChanged fires once the user enters Hours. See
      // CLAUDE.md form rule 11.
      minute: data.sessionStartTime?.minute ?? 0,
      second: 0,
    )..addListener(onStartTimeControllerChanged);
  }

  @override
  void dispose() {
    sessionStartTimeController.dispose();
    super.dispose();
  }

  ProgrammeScheduleData currentData() => ProgrammeScheduleData(
    weekdays: Set<int>.from(selectedWeekdays),
    startDate: selectedStartDate,
    endDate: selectedEndDate,
    hasNoEndDate: hasNoEndDate,
    sessionStartTime: selectedSessionStartTime,
    totalDurationMinutes: totalDurationMinutes,
    sessions: List<SessionInput>.from(sessions),
  );

  void emit() => widget.state.didChange(currentData());

  void onTotalDurationChanged(int minutes) {
    // Changing the total resets the split to a single full segment; the
    // SessionSplitField mirrors this via its totalMinutes change.
    setState(() {
      totalDurationMinutes = minutes;
      sessions = const [];
    });
    emit();
  }

  String? validateEndDate(DateTime? date) {
    if (date == null) return null;
    if (selectedStartDate != null && date.isBefore(selectedStartDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }

  void clearEndDate() {
    setState(() {
      selectedEndDate = null;
      hasNoEndDate = true;
      endDateResetCounter++;
    });
    emit();
  }

  /// The picker reports a time only once every part of it is filled. With
  /// a part emptied the start time is empty too, so the required rule
  /// refuses it.
  void onStartTimeControllerChanged() {
    if (sessionStartTimeController.value != null) return;
    if (selectedSessionStartTime == null) return;
    _startTimeKey.currentState?.didChange(null);
  }

  /// A start time that is set or moved takes the session split with it: the
  /// split editor lays its rows out from the new start.
  void onSessionStartTimeChanged(ShadTimeOfDay? time) {
    setState(() {
      selectedSessionStartTime = time;
      sessions = _splitKey.currentState?.sessionsFrom(time) ?? sessions;
    });
    emit();
  }

  // Session-split operations delegate to the shared [SessionSplitField], the
  // single owner of the segment editor. Kept as instance methods/getters so
  // callers (and tests) can drive the split through this body.
  List<int> get sessionDurations =>
      _splitKey.currentState?.sessionDurations ?? const [];

  void onSessionDurationChanged(int index, Duration picked) =>
      _splitKey.currentState?.onSessionDurationChanged(index, picked);

  void removeSession(int index) => _splitKey.currentState?.removeSession(index);

  List<SessionInput> buildSessions() =>
      _splitKey.currentState?.buildSessions() ?? const [];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final enabled = widget.state.widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        LabeledFormRow(
          label: 'Days of Week',
          required: true,
          field: FormField<Set<int>>(
            initialValue: selectedWeekdays,
            validator: ProgrammeScheduleFormValidators.weekdays,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeekdaySelector(
                  selectedDays: selectedWeekdays,
                  enabled: enabled,
                  onChanged: (days) {
                    field.didChange(days);
                    setState(() => selectedWeekdays = days);
                    emit();
                  },
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      field.errorText!,
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showDateRange)
          TwoColumnGrid(
            runSpacing: FormSpacing.rowGap,
            children: [
              LabeledFormRow(
                label: 'Start Date',
                required: true,
                field: CLDatePickerFormField(
                  initialValue: selectedStartDate,
                  enabled: enabled,
                  validator: ProgrammeScheduleFormValidators.startDate,
                  onChanged: (date) {
                    setState(() => selectedStartDate = date);
                    emit();
                  },
                ),
              ),
              LabeledFormRow(
                labelChild: Row(
                  children: [
                    Text(
                      'End Date',
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (selectedEndDate != null)
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: enabled ? clearEndDate : null,
                        child: Text(
                          'Clear',
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                field: CLDatePickerFormField(
                  key: ValueKey('endDate_$endDateResetCounter'),
                  initialValue: selectedEndDate,
                  enabled: enabled,
                  placeholder: const Text('Ongoing'),
                  validator: validateEndDate,
                  onChanged: (date) {
                    setState(() {
                      selectedEndDate = date;
                      hasNoEndDate = date == null;
                    });
                    emit();
                  },
                ),
              ),
            ],
          ),
        TwoColumnGrid(
          runSpacing: FormSpacing.rowGap,
          children: [
            LabeledFormRow(
              label: 'Start Time',
              required: true,
              field: TimePickerEmptyParts(
                controller: sessionStartTimeController,
                child: ShadTimePickerFormField(
                  key: _startTimeKey,
                  controller: sessionStartTimeController,
                  initialValue: selectedSessionStartTime,
                  enabled: enabled,
                  showSeconds: false,
                  hourLabel: const SizedBox.shrink(),
                  minuteLabel: const SizedBox.shrink(),
                  // Match the plain inputs beside it: 14px digits (the picker
                  // defaults to 16) and no label gap (labels are hidden).
                  gap: 0,
                  style: ShadTheme.of(context).textTheme.muted,
                  validator: ProgrammeScheduleFormValidators.startTime,
                  onChanged: onSessionStartTimeChanged,
                ),
              ),
            ),
            LabeledFormRow(
              label: 'Duration',
              required: true,
              field: ScheduleDurationField(
                minutes: totalDurationMinutes,
                longestMinutes: maxProgrammeDurationMinutes,
                enabled: enabled,
                onChanged: onTotalDurationChanged,
              ),
            ),
          ],
        ),
        LabeledFormRow(
          label: 'Sessions',
          field: SessionSplitField(
            key: _splitKey,
            totalMinutes: totalDurationMinutes,
            startTime: selectedSessionStartTime,
            initialSessions: sessions,
            enabled: enabled,
            onChanged: (next) {
              setState(() => sessions = next);
              emit();
            },
          ),
        ),
      ],
    );
  }
}
