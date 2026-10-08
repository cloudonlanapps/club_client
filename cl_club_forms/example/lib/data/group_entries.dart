import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';

/// The forms of a group of members.
abstract final class GroupEntries {
  /// A group that fills itself by criteria: girls of 8 to 12.
  static Map<String, dynamic> get criteria => {
    ...GroupCreateForm.emptyValues,
    GroupFormFields.modeId: GroupMode.auto,
    GroupFormFields.genderId: GroupGender.girls,
    ...AgeEligibilityFormValues.initial(
      minAge: const FormAge(years: 8),
      maxAge: const FormAge(years: 12),
      strictAge: true,
    ),
  };

  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'group-create',
      title: 'Group create form',
      group: FormDemoGroup.groups,
      formType: GroupCreateForm,
      builder: (key) => GroupCreateForm(key: key),
    ),
    FormDemoEntry(
      id: 'group-eligibility',
      title: 'Group eligibility form',
      group: FormDemoGroup.groups,
      formType: GroupEligibilityForm,
      builder: (key) => GroupEligibilityForm(key: key, initialValues: criteria),
    ),
  ];
}
