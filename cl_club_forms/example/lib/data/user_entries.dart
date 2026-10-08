import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';
import 'fake_host_calls.dart';

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
        canAssignAdmin: true,
        canAssignCoach: true,
        onCheckUsernameAvailable: FakeHostCalls.usernameAvailable,
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
      builder: (key) =>
          UserContactForm(key: key, initialValues: DemoSamples.member),
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
      id: 'identity-documents-consent',
      title: 'Identity documents consent form',
      group: FormDemoGroup.users,
      formType: IdentityDocumentsConsentForm,
      builder: (key) => IdentityDocumentsConsentForm(key: key),
    ),
  ];
}
