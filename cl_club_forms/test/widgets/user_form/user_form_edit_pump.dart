// What the two files of UserForm's edit-mode tests share: the member
// edited and how the form is mounted.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';

const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _nickname = UserFormFields.nicknameId;
const String _useName = UserFormFields.useNamePubliclyId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _line1 = UserFormFields.addrLine1Id;
const String _line2 = UserFormFields.addrLine2Id;
const String _city = UserFormFields.cityId;
const String _state = UserFormFields.stateId;
const String _pincode = UserFormFields.pincodeId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;
const String _ecName = UserFormFields.emergencyContactNameId;
const String _ecRelation = UserFormFields.emergencyContactRelationId;
const String _ecPhone = UserFormFields.emergencyContactPhoneId;
const String _medical = UserFormFields.medicalInfoId;

const noNameMessage = 'First name or last name is required';

/// The member being edited.
Map<String, dynamic> editedMember() => {
  _first: 'Robin',
  _middle: 'K',
  _last: 'Rao',
  _nickname: 'Rob',
  _useName: true,
  _gender: SignupGender.other,
  _dob: DateTime.utc(2010, 3, 4),
  _line1: '12 MG Road',
  _line2: 'Camp',
  _city: 'Pune',
  _state: 'Maharashtra',
  _pincode: '411001',
  _phone: '9876543210',
  _email: 'robin@example.test',
  _ecName: 'Meera Rao',
  _ecRelation: 'Parent',
  _ecPhone: '9876543211',
  _medical: 'Asthma',
};

const List<String> editNameIds = [_first, _middle, _last, _nickname];
const List<String> editLowerIds = [
  _line1,
  _line2,
  _city,
  _state,
  _pincode,
  _phone,
  _email,
  _ecName,
  _ecRelation,
  _ecPhone,
  _medical,
];
const editLowerRows = [
  'Address',
  'Address line 1',
  'Address line 2',
  'City',
  'State',
  'Pincode',
  'Phone *',
  'Email *',
  'Emergency contact name',
  'Emergency contact relation',
  'Emergency contact phone',
  'Medical info',
];

Future<UserFormState> pumpEdit(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  bool canEditGender = false,
  bool canEditDateOfBirth = false,
  bool canEditUseNamePublicly = false,
  bool canAssignAdmin = false,
  bool canAssignCoach = false,
  ValueChanged<bool>? onCanSubmitChanged,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserFormState>();
  await pumpForm(
    tester,
    UserForm(
      key: key,
      readOnlyUsername: 'robin',
      initialValues: initialValues ?? editedMember(),
      enabled: enabled,
      canEditGender: canEditGender,
      canEditDateOfBirth: canEditDateOfBirth,
      canEditUseNamePublicly: canEditUseNamePublicly,
      canAssignAdmin: canAssignAdmin,
      canAssignCoach: canAssignCoach,
      onCanSubmitChanged: onCanSubmitChanged,
    ),
    size: size,
  );
  return key.currentState!;
}

Future<UserFormState> pumpEditAllEditable(WidgetTester tester) => pumpEdit(
  tester,
  canEditGender: true,
  canEditDateOfBirth: true,
  canEditUseNamePublicly: true,
);
