// Issue 67: every form of cl_club_forms, turned off while one of its text
// inputs has the keyboard focus, takes no typing. The check itself is the
// harness's `expectKeyboardIgnoredWhenOff`.
import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

/// One form, as its host mounts it. `typed` is false for a form whose own
/// rows may hold no text input; the others must have one tried.
typedef _Case = ({
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

final List<_Case> _cases = [
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
        IdentityDocumentsConsentForm(enabled: enabled),
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
      initialAddress: '1 Rink Rd',
      initialMapUri: '',
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
      initialCoaches: const [],
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
      initialDay: _day,
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

void main() {
  group('Issue 67: a form turned off takes no typing', () {
    test('Issue 67: every form of the package is among the forms tried', () {
      final mixedIn = RegExp(r'with\s+FormContract<(\w+)>');
      final forms = <String>{
        for (final file in Directory('lib/src/widgets').listSync(
          recursive: true,
        ))
          if (file is File && file.path.endsWith('.dart'))
            for (final match in mixedIn.allMatches(file.readAsStringSync()))
              match.group(1)!,
      };
      expect(forms, isNotEmpty);
      final tried = {for (final c in _cases) c.name.split(',').first};
      expect(forms.difference(tried), isEmpty, reason: 'forms not tried');
    });

    for (final c in _cases) {
      testWidgets('Issue 67: ${c.name} turned off takes no typing in the '
          'input that had the focus', (tester) async {
        final tried = await expectKeyboardIgnoredWhenOff(tester, c.build);
        if (c.typed) expect(tried, greaterThan(0), reason: 'inputs tried');
      });
    }

    testWidgets('Issue 67: a form that opens turned off gives its first '
        'input no focus', (tester) async {
      await pumpForm(tester, const LoginForm(enabled: false));

      expect(tester.testTextInput.hasAnyClients, isFalse);
      tester.testTextInput.enterText('typed while off');
      await tester.pumpAndSettle();
      final form = tester.state<ShadFormState>(find.byType(ShadForm));
      expect(form.value[LoginFormFields.usernameId], '');
    });
  });
}
