import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';

/// The forms of a member's record.
abstract final class UserEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'user-create',
      title: 'User form',
      group: FormDemoGroup.users,
      formType: UserForm,
      builder: (key) => UserForm(
        key: key,
        defaultCountryCode: DemoSamples.countryCode,
        canAssignAdmin: true,
        canAssignCoach: true,
        onShowDefaultPassword: () {},
      ),
    ),
    FormDemoEntry(
      id: 'user-personal-details',
      title: 'User personal details form',
      group: FormDemoGroup.users,
      formType: UserPersonalDetailsForm,
      builder: (key) => UserPersonalDetailsForm(
        key: key,
        initialValues: DemoSamples.member,
        canEditDateOfBirth: true,
        canEditGender: true,
        canEditUseNamePublicly: true,
        canEditPublicProfile: true,
      ),
    ),
    FormDemoEntry(
      id: 'user-personal-details-protected',
      title: 'User personal details form, protected fields locked',
      group: FormDemoGroup.users,
      formType: UserPersonalDetailsForm,
      builder: (key) =>
          UserPersonalDetailsForm(key: key, initialValues: DemoSamples.member),
    ),
    FormDemoEntry(
      id: 'user-contact',
      title: 'User contact form',
      group: FormDemoGroup.users,
      formType: UserContactForm,
      builder: (key) => UserContactForm(
        key: key,
        defaultCountryCode: DemoSamples.countryCode,
        initialValues: DemoSamples.member,
      ),
    ),
    FormDemoEntry(
      id: 'user-address',
      title: 'User address form',
      group: FormDemoGroup.users,
      formType: UserAddressForm,
      builder: (key) =>
          UserAddressForm(key: key, initialValues: DemoSamples.member),
    ),
    FormDemoEntry(
      id: 'user-sports-details',
      title: 'User sports details form',
      group: FormDemoGroup.users,
      formType: UserSportsDetailsForm,
      builder: (key) => UserSportsDetailsForm(
        key: key,
        initialValues: DemoSamples.member,
        positions: DemoSamples.positions,
      ),
    ),
    FormDemoEntry(
      id: 'user-background',
      title: 'User background form',
      group: FormDemoGroup.users,
      formType: UserBackgroundForm,
      builder: (key) => UserBackgroundForm(
        key: key,
        initialValues: DemoSamples.member,
        languages: DemoSamples.memberLanguages,
      ),
    ),
    FormDemoEntry(
      id: 'user-guardian',
      title: 'User guardian form',
      group: FormDemoGroup.users,
      formType: UserGuardianForm,
      builder: (key) => UserGuardianForm(
        key: key,
        defaultCountryCode: DemoSamples.countryCode,
        initialValues: DemoSamples.member,
      ),
    ),
    FormDemoEntry(
      id: 'membership-date',
      title: 'Membership date form',
      group: FormDemoGroup.users,
      formType: MembershipDateForm,
      builder: (key) =>
          MembershipDateForm(key: key, initialValue: DateTime.utc(2025, 4, 2)),
    ),
    FormDemoEntry(
      id: 'identity-documents-consent',
      title: 'Identity documents consent form',
      group: FormDemoGroup.users,
      formType: IdentityDocumentsConsentForm,
      builder: (key) =>
          IdentityDocumentsConsentForm(key: key, onShowPolicy: () {}),
    ),
  ];
}
