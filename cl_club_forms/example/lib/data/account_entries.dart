import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';
import 'fake_host_calls.dart';

/// The account forms: signing in, passwords and signing up.
abstract final class AccountEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'login',
      title: 'Login form',
      group: FormDemoGroup.account,
      formType: LoginForm,
      builder: (key) => LoginForm(key: key),
    ),
    FormDemoEntry(
      id: 'forgot-password',
      title: 'Forgot password form',
      group: FormDemoGroup.account,
      formType: ForgotPasswordForm,
      builder: (key) => ForgotPasswordForm(key: key),
    ),
    FormDemoEntry(
      id: 'change-password',
      title: 'Change password form',
      group: FormDemoGroup.account,
      formType: ChangePasswordForm,
      builder: (key) => ChangePasswordForm(key: key),
    ),
    FormDemoEntry(
      id: 'signup',
      title: 'Signup form',
      group: FormDemoGroup.account,
      formType: SignupForm,
      builder: (key) => SignupForm(
        key: key,
        defaultCountryCode: DemoSamples.countryCode,
        onCheckUsernameAvailable: FakeHostCalls.usernameAvailable,
      ),
    ),
    FormDemoEntry(
      id: 'signup-reapplying',
      title: 'Signup form, reapplying',
      group: FormDemoGroup.account,
      formType: SignupForm,
      builder: (key) => SignupForm(
        key: key,
        defaultCountryCode: DemoSamples.countryCode,
        username: DemoSamples.username,
        initialValues: DemoSamples.member,
      ),
    ),
  ];
}
