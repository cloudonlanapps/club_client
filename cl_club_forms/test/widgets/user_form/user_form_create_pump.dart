// What the two files of UserForm's create-mode tests share: how the form
// is mounted and filled.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _username = UserFormFields.usernameId;
const String _password = UserFormFields.passwordId;
const String _confirm = UserFormFields.confirmPasswordId;
const String _useDefault = UserFormFields.useDefaultPasswordId;
const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;

const noNameMessage = 'First name or last name is required';
const List<String> createRows = [
  'Username *',
  'First name *',
  'Middle name',
  'Last name *',
  'Gender *',
  'Date of birth *',
  'Phone *',
  'Email *',
];
const List<String> createIds = [
  _username,
  _useDefault,
  _first,
  _middle,
  _last,
  _gender,
  _dob,
  _phone,
  _email,
];

final Finder showButton = find.widgetWithText(ShadButton, 'Show');

Future<UserFormState> pumpCreate(
  WidgetTester tester, {
  bool enabled = true,
  bool available = true,
  bool canAssignAdmin = false,
  bool canAssignCoach = false,
  VoidCallback? onShowDefaultPassword,
  ValueChanged<bool>? onCanSubmitChanged,
  Map<String, dynamic>? initialValues,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserFormState>();
  await pumpForm(
    tester,
    UserForm(
      defaultCountryCode: '91',
      key: key,
      enabled: enabled,
      initialValues: initialValues,
      canAssignAdmin: canAssignAdmin,
      canAssignCoach: canAssignCoach,
      onShowDefaultPassword: onShowDefaultPassword,
      onCheckUsernameAvailable: (_) async => available,
      onCanSubmitChanged: onCanSubmitChanged,
    ),
    size: size,
  );
  return key.currentState!;
}

/// Fills a creating form with valid values, the username confirmed and the
/// default password kept.
Future<void> fillCreate(WidgetTester tester, UserFormState state) async {
  await checkUsername(tester, _username, 'robin');
  await enterField(tester, _first, 'Robin');
  await enterField(tester, _phone, '9876543210');
  await enterField(tester, _email, 'robin@example.test');
  await setField(tester, state, _gender, SignupGender.female);
  await setField(tester, state, _dob, DateTime(2010, 3, 4));
}

/// Unticks the default password and types [password] twice.
Future<void> typeOwnPassword(
  WidgetTester tester, {
  String password = 'secret-password',
  String? confirm,
}) async {
  await tapCheckbox(tester, _useDefault);
  await enterField(tester, _password, password);
  await enterField(tester, _confirm, confirm ?? password);
}
