import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/camp_schedule_data.dart';
import '../../models/session_input.dart';
import 'camp_date_exclusion_calendar.dart';
import 'labeled_form_row.dart';
import 'session_split_field.dart';
import 'two_column_grid.dart';

/// `ShadForm`-compatible field for camp event schedule.
///
/// Bundles start date, training-day count, daily session start time,
/// duration, rest-day exclusions, an optional named-session split of the
/// daily duration (the same [SessionSplitField] the programme schedule
/// uses), and an optional day-split description into one [CampScheduleData].
///
/// Drop into any [ShadForm]:
///
/// ```dart
/// CampScheduleFormField(id: 'schedule', initialValue: data)
/// ```
class CampScheduleFormField extends ShadFormBuilderField<CampScheduleData> {
  CampScheduleFormField({
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
  }) : super(
         builder: (state) => CampScheduleFormFieldBody(state: state),
       );

  /// Aggregate validator surfaced from `saveAndValidate()`. Catches missing
  /// required fields. The session split always sums to the daily duration by
  /// construction, so no overlap check is needed.
  static String? aggregateValidator(CampScheduleData? value) {
    if (value == null) return 'Schedule is required';
    if (value.startDate == null) return 'Start date is required';
    if (value.trainingDays < 1) return 'Training days must be at least 1';
    if (value.sessionStartTime == null) return 'Start time is required';
    if (value.durationMinutes <= 0) return 'Duration must be greater than 0';
    return null;
  }
}

/// Body for [CampScheduleFormField]. Public per project guideline; not
/// intended for direct instantiation.
class CampScheduleFormFieldBody extends StatefulWidget {
  const CampScheduleFormFieldBody({required this.state, super.key});

  final FormFieldState<CampScheduleData> state;

  @override
  State<CampScheduleFormFieldBody> createState() =>
      CampScheduleFormFieldBodyState();
}

class CampScheduleFormFieldBodyState extends State<CampScheduleFormFieldBody> {
  late DateTime? selectedStartDate;
  late int actualTrainingDays;
  late ShadTimeOfDay? selectedSessionStartTime;
  late int durationMinutes;
  late Set<DateTime> excludedDates;
  late List<SessionInput> sessions;
  final GlobalKey<SessionSplitFieldState> _splitKey = GlobalKey();
  late TextEditingController durationController;
  late TextEditingController trainingDaysController;
  late ShadTimePickerController sessionStartTimeController;

  int get durationDays => actualTrainingDays + excludedDates.length;

  @override
  void initState() {
    super.initState();
    final initial = widget.state.value ?? const CampScheduleData();
    selectedStartDate = initial.startDate;
    actualTrainingDays = initial.trainingDays;
    selectedSessionStartTime = initial.sessionStartTime;
    durationMinutes = initial.durationMinutes;
    excludedDates = Set<DateTime>.from(initial.excludedDates);
    sessions = List<SessionInput>.from(initial.sessions);
    durationController = TextEditingController(
      text: formatDuration(durationMinutes),
    );
    trainingDaysController = TextEditingController(
      text: actualTrainingDays.toString(),
    );
    sessionStartTimeController = ShadTimePickerController(
      hour: initial.sessionStartTime?.hour,
      // Default minute and second so the picker fires onChanged once the
      // user enters Hours. The "00" the user sees in the unchanged
      // minute field is placeholder text, not a value.
      minute: initial.sessionStartTime?.minute ?? 0,
      second: 0,
    );
  }

  @override
  void dispose() {
    durationController.dispose();
    trainingDaysController.dispose();
    sessionStartTimeController.dispose();
    super.dispose();
  }

  String formatDuration(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.truncateToDouble()) return '${hours.toInt()}h';
    if (hours < 1) return '${minutes}m';
    final whole = hours.truncate();
    final fraction = minutes - whole * 60;
    if (fraction == 30) return '${whole}h 30m';
    return '${whole}h ${fraction}m';
  }

  int? parseDuration(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return null;
    final compound = RegExp(r'^(\d+)h\s*(\d+)?m?$').firstMatch(text);
    if (compound != null) {
      final hours = int.tryParse(compound.group(1)!) ?? 0;
      final mins = int.tryParse(compound.group(2) ?? '0') ?? 0;
      return hours * 60 + mins;
    }
    final decimalHours = RegExp(r'^(\d+(?:\.\d+)?)h?$').firstMatch(text);
    if (decimalHours != null) {
      final hours = double.tryParse(decimalHours.group(1)!) ?? 0;
      return (hours * 60).round();
    }
    final mOnly = RegExp(r'^(\d+)m$').firstMatch(text);
    if (mOnly != null) return int.tryParse(mOnly.group(1)!);
    return null;
  }

  String? validateDuration(String value) {
    final parsed = parseDuration(value);
    if (parsed == null || parsed <= 0) {
      return 'Duration must be greater than 0';
    }
    return null;
  }

  void emit() {
    widget.state.didChange(
      CampScheduleData(
        startDate: selectedStartDate,
        trainingDays: actualTrainingDays,
        sessionStartTime: selectedSessionStartTime,
        durationMinutes: durationMinutes,
        excludedDates: Set<DateTime>.from(excludedDates),
        sessions: List<SessionInput>.from(sessions),
      ),
    );
  }

  void onDurationTextChanged(String value) {
    final parsed = parseDuration(value);
    if (parsed == null || parsed <= 0) return;
    // Changing the daily duration resets the session split to a single full
    // segment; the SessionSplitField mirrors this via its totalMinutes change.
    setState(() {
      durationMinutes = parsed;
      sessions = const [];
    });
    emit();
  }

  // Session-split operations delegate to the shared [SessionSplitField] — the
  // same editor the programme schedule uses.
  List<int> get sessionDurations =>
      _splitKey.currentState?.sessionDurations ?? const [];

  void onSessionDurationChanged(int index, Duration picked) =>
      _splitKey.currentState?.onSessionDurationChanged(index, picked);

  void removeSession(int index) => _splitKey.currentState?.removeSession(index);

  List<SessionInput> buildSessions() =>
      _splitKey.currentState?.buildSessions() ?? const [];

  @override
  Widget build(BuildContext context) {
    final enabled = widget.state.widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        TwoColumnGrid(
          children: [
            LabeledFormRow(
              label: 'Start Date',
              required: true,
              // Sized to its content (a date) rather than stretching, so the
              // row reads as compact boxes like Start Time + Duration below.
              field: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 180,
                  child: CLDatePickerFormField(
                    initialValue: selectedStartDate,
                    enabled: enabled,
                    validator: (date) =>
                        date == null ? 'Start date is required' : null,
                    onChanged: (date) {
                      setState(() => selectedStartDate = date);
                      emit();
                    },
                  ),
                ),
              ),
            ),
            LabeledFormRow(
              label: 'Training Days',
              required: true,
              // A short number — same compact box width as Duration.
              field: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 104,
                  child: ShadInputFormField(
                    controller: trainingDaysController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    placeholder: const Text('7'),
                    validator: (v) {
                      if (v.isEmpty) return 'Required';
                      final days = int.tryParse(v);
                      if (days == null || days < 1) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final days = int.tryParse(value);
                      if (days != null && days > 0) {
                        setState(() => actualTrainingDays = days);
                        emit();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        // Start Time + Duration share a row (the same matched pairing the
        // programme and one-off schedules use); Sessions takes a full-width
        // row of its own below, giving the session-title inputs the space.
        TwoColumnGrid(
          children: [
            LabeledFormRow(
              label: 'Start Time',
              required: true,
              field: ShadTimePickerFormField(
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
                validator: (time) =>
                    time == null ? 'Start time is required' : null,
                onChanged: (time) {
                  setState(() => selectedSessionStartTime = time);
                  emit();
                },
              ),
            ),
            LabeledFormRow(
              label: 'Duration',
              required: true,
              // Constrain to roughly the time picker's footprint (2×48 + gap)
              // so the Duration box reads the same size as Start Time beside it
              // rather than stretching the full column.
              field: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 104,
                  child: ShadInputFormField(
                    controller: durationController,
                    enabled: enabled,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    enableSuggestions: false,
                    placeholder: const Text('2h'),
                    validator: validateDuration,
                    onChanged: onDurationTextChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
        LabeledFormRow(
          label: 'Sessions',
          field: SessionSplitField(
            key: _splitKey,
            totalMinutes: durationMinutes,
            startTime: selectedSessionStartTime,
            initialSessions: sessions,
            enabled: enabled,
            onChanged: (next) {
              setState(() => sessions = next);
              emit();
            },
          ),
        ),
        if (selectedStartDate != null)
          CampDateExclusionCalendar(
            campStartDate: selectedStartDate!,
            durationDays: durationDays,
            excludedDates: excludedDates,
            enabled: enabled,
            label: 'Rest Days (tap to toggle)',
            onChanged: (dates) {
              setState(() => excludedDates = dates);
              emit();
            },
          ),
      ],
    );
  }
}
