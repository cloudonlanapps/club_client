import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/camp_schedule_data.dart';
import '../../models/session_input.dart';
import '../form/labeled_form_row.dart';
import 'camp_date_exclusion_calendar.dart';
import 'camp_schedule_form_validators.dart';
import 'schedule_duration_field.dart';
import 'session_split_field.dart';
import 'time_picker_empty_parts.dart';
import 'two_column_grid.dart';

/// The longest day of a camp the Duration picker offers.
const int maxCampDurationMinutes = 8 * 60;

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
  final GlobalKey<FormFieldState<ShadTimeOfDay>> _startTimeKey = GlobalKey();
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
    )..addListener(onStartTimeControllerChanged);
  }

  @override
  void dispose() {
    trainingDaysController.dispose();
    sessionStartTimeController.dispose();
    super.dispose();
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

  void onDurationChanged(int minutes) {
    // Changing the daily duration resets the session split to a single full
    // segment; the SessionSplitField mirrors this via its totalMinutes change.
    setState(() {
      durationMinutes = minutes;
      sessions = const [];
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
      spacing: FormSpacing.rowGap,
      children: [
        TwoColumnGrid(
          runSpacing: FormSpacing.rowGap,
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
                    validator: CampScheduleFormValidators.startDate,
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
                    validator: CampScheduleFormValidators.trainingDays,
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
                  validator: CampScheduleFormValidators.startTime,
                  onChanged: onSessionStartTimeChanged,
                ),
              ),
            ),
            LabeledFormRow(
              label: 'Duration',
              required: true,
              field: ScheduleDurationField(
                minutes: durationMinutes,
                longestMinutes: maxCampDurationMinutes,
                enabled: enabled,
                onChanged: onDurationChanged,
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
          LabeledFormRow(
            label: 'Rest Days (tap to toggle)',
            field: CampDateExclusionCalendar(
              campStartDate: selectedStartDate!,
              durationDays: durationDays,
              excludedDates: excludedDates,
              enabled: enabled,
              onChanged: (dates) {
                setState(() => excludedDates = dates);
                emit();
              },
            ),
          ),
      ],
    );
  }
}
