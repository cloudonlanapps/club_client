// Every form of cl_club_forms as its host mounts it, for the checks that
// run on each of them (Issues 67, 93, 94 and 97).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One form, as its host mounts it. `typed` is false for a form whose own
/// rows may hold no text input; the others must have one tried.
typedef FormCase = ({
  String name,
  Widget Function({required bool enabled}) build,
  bool typed,
});

const _six = ShadTimeOfDay(hour: 6, minute: 0, second: 0);

const _venues = [
  EventVenueOption(id: 7, name: 'North Rink'),
  EventVenueOption(id: 9, name: 'Hall'),
];

final _day = DateTime(2030, 5, 14);

const _countryCode = '91';

const _inquiryCopy = InquiryFormCopy(
  nameLabel: 'Name',
  namePlaceholder: 'Your name',
  emailLabel: 'Email',
  emailPlaceholder: 'you@example.com',
  phoneLabel: 'Phone',
  phonePlaceholder: 'Your phone',
  messageLabel: 'Message',
  messagePlaceholder: 'Your message',
  nameRequired: 'Name is required',
  emailRequired: 'Email is required',
  emailInvalid: 'Enter a valid email',
  messageRequired: 'Message is required',
);

final _oneOff = OneOffScheduleData(
  date: _day,
  startTime: _six,
  durationMinutes: 90,
);

final _programme = ProgrammeScheduleData(
  weekdays: const {DateTime.monday, DateTime.thursday},
  startDate: DateTime(2030, 5),
  sessionStartTime: _six,
);

/// Every form of the package, each variant that mounts differently.
final List<FormCase> formCases = [
  (
    name: 'LoginForm',
    build: ({required enabled}) => LoginForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'ChangePasswordForm',
    build: ({required enabled}) => ChangePasswordForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'ForgotPasswordForm',
    build: ({required enabled}) => ForgotPasswordForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'SignupForm',
    build: ({required enabled}) => SignupForm(
      enabled: enabled,
      defaultCountryCode: _countryCode,
      onCheckUsernameAvailable: (_) async => true,
    ),
    typed: true,
  ),
  (
    name: 'UserForm, creating',
    build: ({required enabled}) => UserForm(
      enabled: enabled,
      defaultCountryCode: _countryCode,
      onCheckUsernameAvailable: (_) async => true,
    ),
    typed: true,
  ),
  (
    name: 'UserPersonalDetailsForm',
    build: ({required enabled}) => UserPersonalDetailsForm(
      enabled: enabled,
      initialValues: const {UserFormFields.firstNameId: 'Asha'},
    ),
    typed: true,
  ),
  (
    name: 'UserContactForm',
    build: ({required enabled}) => UserContactForm(
      enabled: enabled,
      defaultCountryCode: _countryCode,
      initialValues: const {},
    ),
    typed: true,
  ),
  (
    name: 'InquiryForm',
    build: ({required enabled}) =>
        InquiryForm(enabled: enabled, copy: _inquiryCopy),
    typed: true,
  ),
  (
    name: 'UserAddressForm',
    build: ({required enabled}) =>
        UserAddressForm(enabled: enabled, initialValues: const {}),
    typed: true,
  ),
  (
    name: 'ClubDetailsForm',
    build: ({required enabled}) =>
        ClubDetailsForm(enabled: enabled, initialValues: const {}),
    typed: true,
  ),
  (
    name: 'ClubContactForm',
    build: ({required enabled}) =>
        ClubContactForm(enabled: enabled, initialValues: const {}),
    typed: true,
  ),
  (
    name: 'ClubAddressForm',
    build: ({required enabled}) =>
        ClubAddressForm(enabled: enabled, initialValues: const {}),
    typed: true,
  ),
  (
    name: 'ClubLanguageForm',
    build: ({required enabled}) => ClubLanguageForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'IdentityDocumentsConsentForm',
    build: ({required enabled}) =>
        IdentityDocumentsConsentForm(enabled: enabled, onShowPolicy: () {}),
    typed: false,
  ),
  (
    name: 'RenameForm',
    build: ({required enabled}) => RenameForm(
      enabled: enabled,
      initialValue: 'Juniors',
      label: 'Group Name',
    ),
    typed: true,
  ),
  (
    name: 'LocationEditForm',
    build: ({required enabled}) => LocationEditForm(
      enabled: enabled,
      initialValues: const {
        LocationEditFormFields.addressId: '1 Rink Rd',
        LocationEditFormFields.mapUriId: '',
      },
    ),
    typed: true,
  ),
  (
    name: 'VenueCreateForm',
    build: ({required enabled}) => VenueCreateForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'GroupCreateForm',
    build: ({required enabled}) => GroupCreateForm(
      enabled: enabled,
      initialValues: {
        ...GroupCreateForm.emptyValues,
        GroupFormFields.modeId: GroupMode.auto,
      },
    ),
    typed: true,
  ),
  (
    name: 'GroupEligibilityForm',
    build: ({required enabled}) => GroupEligibilityForm(
      enabled: enabled,
      initialValues: {
        ...GroupCreateForm.emptyValues,
        GroupFormFields.modeId: GroupMode.auto,
      },
    ),
    typed: true,
  ),
  (
    name: 'EventEligibilityForm',
    build: ({required enabled}) => EventEligibilityForm(
      enabled: enabled,
      initialValues: {
        EventFormFields.genderId: EventGender.any,
        ...AgeEligibilityFormValues.initial(),
      },
    ),
    typed: true,
  ),
  (
    name: 'EventStaffForm',
    build: ({required enabled}) => EventStaffForm(
      enabled: enabled,
      initialValues: const {
        EventFormFields.coachNamesId: <EventStaffMember>[],
      },
      onPickOrganizer: () async => null,
      onPickCoaches: (_) async => null,
    ),
    typed: false,
  ),
  (
    name: 'EventStaffForm, of a programme',
    build: ({required enabled}) => EventStaffForm(
      enabled: enabled,
      initialValues: {
        EventFormFields.coachNamesId: const <EventStaffMember>[],
        EventFormFields.effectiveFromId: _day,
      },
      fromOptions: [_day, _day.add(const Duration(days: 7))],
      onPickOrganizer: () async => null,
      onPickCoaches: (_) async => null,
    ),
    typed: false,
  ),
  (
    name: 'EventCancellationForm',
    build: ({required enabled}) => EventCancellationForm(enabled: enabled),
    typed: true,
  ),
  (
    name: 'CreditGrantForm',
    build: ({required enabled}) => CreditGrantForm(
      enabled: enabled,
      programmes: const [CreditProgrammeOption(id: 9, title: 'Skating')],
      initialValues: CreditGrantForm.defaultValues(today: _day),
      today: _day,
    ),
    typed: true,
  ),
  (
    name: 'CreditExtendForm',
    build: ({required enabled}) =>
        CreditExtendForm(enabled: enabled, currentValidUntil: _day),
    typed: true,
  ),
  (
    name: 'CreditReverseForm',
    build: ({required enabled}) =>
        CreditReverseForm(enabled: enabled, unspent: 4),
    typed: true,
  ),
  (
    name: 'CreditTransferForm',
    build: ({required enabled}) =>
        CreditTransferForm(enabled: enabled, balance: 8, today: _day),
    typed: true,
  ),
  for (final type in EventFormType.values)
    (
      name: 'EventCreateForm, ${type.name}',
      build: ({required enabled}) => EventCreateForm(
        enabled: enabled,
        eventType: type,
        venues: _venues,
        initialValues: EventCreateForm.defaultValues(type, now: _day),
      ),
      typed: true,
    ),
  (
    name: 'CampScheduleForm',
    build: ({required enabled}) => CampScheduleForm(
      enabled: enabled,
      initialValue: CampScheduleData(
        startDate: _day,
        trainingDays: 5,
        sessionStartTime: _six,
        durationMinutes: 120,
      ),
    ),
    typed: false,
  ),
  (
    name: 'OneOffScheduleForm',
    build: ({required enabled}) => OneOffScheduleForm(
      enabled: enabled,
      initialValue: OneOffScheduleValue(schedule: _oneOff, venueId: 7),
      venues: _venues,
    ),
    typed: false,
  ),
  (
    name: 'OccurrenceRescheduleForm',
    build: ({required enabled}) => OccurrenceRescheduleForm(
      enabled: enabled,
      initialValues: {
        OccurrenceRescheduleFormFields.scheduleId: _oneOff,
        OccurrenceRescheduleFormFields.venueId: 7,
      },
      venues: _venues,
    ),
    typed: false,
  ),
  (
    name: 'ProgrammeScheduleAdjustForm',
    build: ({required enabled}) => ProgrammeScheduleAdjustForm(
      enabled: enabled,
      initialValue: ProgrammeScheduleAdjustValue(
        from: DateTime.utc(2030, 5, 13, 6),
        schedule: _programme,
        venueId: 7,
      ),
      fromOptions: [DateTime.utc(2030, 5, 13, 6), DateTime.utc(2030, 5, 16, 6)],
      venues: _venues,
    ),
    typed: false,
  ),
  (
    name: 'ProgrammeEndDateForm',
    build: ({required enabled}) => ProgrammeEndDateForm(
      enabled: enabled,
      initialValues: {
        ProgrammeEndDateFormFields.lastDayId: _day,
      },
      reasonRequired: true,
      resultOf: (day) => 'Last session: day ${day.day}.',
    ),
    typed: false,
  ),
  (
    name: 'EventTimetableForm',
    build: ({required enabled}) => EventTimetableForm(
      enabled: enabled,
      schedules: const [
        TimetableScheduleOption(
          id: 11,
          label: 'From 1 Jul 2026 (current)',
          startTime: _six,
          totalMinutes: 120,
          sessions: [
            SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
            SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
          ],
        ),
      ],
    ),
    typed: false,
  ),
];
