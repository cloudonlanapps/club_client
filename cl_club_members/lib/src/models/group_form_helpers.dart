import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityFormValues, GroupFormFields, GroupGender, GroupMode;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, formAgeFromSdk, sdkAgeFromForm;
import 'package:club_sdk_2/club_sdk_2.dart';

/// SDK adapter for the group forms — the one place that bridges the forms'
/// flat `Map<String, dynamic>` (keyed by `GroupFormFields`, with form-local
/// `GroupMode` / `GroupGender` values) to the `cl_remote_store` create/update
/// calls. The form widgets in `cl_club_forms` are SDK-free; this helper owns
/// the translation. Mirrors `user_form_helpers.dart` / `venue_form_helpers.dart`.

/// SDK [GroupKind] → form-local [GroupMode].
GroupMode _modeFromKind(GroupKind kind) => switch (kind) {
  GroupKind.manual => GroupMode.manual,
  GroupKind.semiAuto => GroupMode.semiAuto,
  GroupKind.auto => GroupMode.auto,
};

String? _nullIfEmpty(Object? v) {
  final s = (v as String?)?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Resolved eligibility values for a submit, derived from the form's mode.
/// In manual mode all criteria are cleared (and the age check is relaxed
/// again) and `semiAuto` is left unset. No dates are sent: the server works
/// the window out from the ages.
({Age? minAge, Age? maxAge, bool strictAge, Gender? gender, bool? semiAuto})
_resolveCriteria(Map<String, dynamic> values) {
  final mode = values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
  if (mode == GroupMode.manual) {
    return (
      minAge: null,
      maxAge: null,
      strictAge: false,
      gender: null,
      semiAuto: null,
    );
  }
  return (
    minAge: sdkAgeFromForm(AgeEligibilityFormValues.minAge(values)),
    maxAge: sdkAgeFromForm(AgeEligibilityFormValues.maxAge(values)),
    strictAge: AgeEligibilityFormValues.strictAge(values),
    gender: GroupFormSubmit.genderToSdk(GroupGender.of(values)),
    semiAuto: mode == GroupMode.semiAuto,
  );
}

/// Builds initial form values from an existing [Group] (null = create mode).
/// Gender is never null: no gender criterion is [GroupGender.any].
Map<String, dynamic> buildGroupFormInitialValues(Group? group) {
  if (group == null) {
    return {
      GroupFormFields.nameId: '',
      GroupFormFields.descriptionId: '',
      GroupFormFields.modeId: GroupMode.manual,
      GroupFormFields.genderId: GroupGender.any,
      GroupFormFields.addMeId: false,
      ...AgeEligibilityFormValues.initial(),
    };
  }
  return {
    GroupFormFields.nameId: group.name,
    GroupFormFields.descriptionId: group.description ?? '',
    GroupFormFields.modeId: _modeFromKind(group.kind),
    ...AgeEligibilityFormValues.initial(
      minAge: formAgeFromSdk(group.minAge),
      maxAge: formAgeFromSdk(group.maxAge),
      strictAge: group.strictAge,
    ),
    GroupFormFields.genderId: GroupFormSubmit.genderToForm(group.gender),
  };
}

/// What a refused write says to a group form, in the shape of the form's
/// `showErrors`: a message per field id, and the form-level message.
typedef GroupFormRefusal = ({
  Map<String, String> fieldErrors,
  String? formError,
});

/// Bridges group form values to the SDK create/update calls, and the
/// server's refusals back to the forms.
class GroupFormSubmit {
  const GroupFormSubmit._();

  /// The Gender entry a group's stored [gender] shows as: Boys for male,
  /// Girls for female, Any for none. A criterion the field does not offer
  /// (`other`, `preferNotToSay`, set through the API) shows as Any too.
  static GroupGender genderToForm(Gender? gender) => switch (gender) {
    Gender.male => GroupGender.boys,
    Gender.female => GroupGender.girls,
    Gender.other || Gender.preferNotToSay || null => GroupGender.any,
  };

  /// What the picked [gender] stores: male for Boys, female for Girls, and
  /// `null` (no gender criterion) for Any.
  static Gender? genderToSdk(GroupGender gender) => switch (gender) {
    GroupGender.boys => Gender.male,
    GroupGender.girls => Gender.female,
    GroupGender.any => null,
  };

  /// Shown inline when the server refuses a minimum age above the maximum.
  static const String invertedBandMessage =
      'Minimum age must not be greater than maximum age.';

  /// Shown on the mode when the server refuses a switch to auto while the
  /// group has members.
  static const String membersExistMessage =
      'This group still has members. Remove them before switching to auto.';

  /// What the create form shows for [error], or `null` when the refusal
  /// names nothing the form holds (the host then reports a failed create).
  static GroupFormRefusal? createRefusal(Object error) {
    if (error is! ServerException) return null;
    return switch (error.code) {
      SdkErrorCode.invalidState => (
        fieldErrors: const {},
        formError: invertedBandMessage,
      ),
      _ => null,
    };
  }

  /// What the eligibility editor shows for [error], or `null` when the
  /// refusal names nothing the form holds (the host then reports a failed
  /// save).
  static GroupFormRefusal? eligibilityRefusal(Object error) {
    if (error is! ServerException) return null;
    return switch (error.code) {
      SdkErrorCode.membersExist => (
        fieldErrors: const {GroupFormFields.modeId: membersExistMessage},
        formError: null,
      ),
      SdkErrorCode.membersIneligible => (
        fieldErrors: const {},
        formError: membersIneligibleMessage(error),
      ),
      SdkErrorCode.invalidState => (
        fieldErrors: const {},
        formError: invertedBandMessage,
      ),
      _ => null,
    };
  }

  /// Names the members the new criteria would leave out, from the refusal's
  /// `membernames`.
  static String membersIneligibleMessage(ServerException error) {
    final names =
        (error.details?['membernames'] as List?)
            ?.map((n) => n.toString())
            .toList() ??
        const <String>[];
    final namesText = names.isEmpty ? 'some members' : names.join(', ');
    return "These members don't meet the new criteria: $namesText. "
        'Remove or update them, then retry.';
  }

  /// Create a new group from the create form's values.
  static Future<Group> create({
    required Map<String, dynamic> values,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    return notifier.createGroup(
      name: (values[GroupFormFields.nameId] as String).trim(),
      description: _nullIfEmpty(values[GroupFormFields.descriptionId]),
      minAge: c.minAge,
      maxAge: c.maxAge,
      strictAge: c.strictAge,
      gender: c.gender,
      semiAuto: c.semiAuto,
    );
  }

  /// Update [group]'s mode + criteria from the eligibility editor's values.
  /// Name / description are only sent when present in [values].
  ///
  /// In a criteria-driven mode the gender is sent only when the form's
  /// differs from the entry [group]'s stored gender shows as
  /// ([genderToForm]): a stored criterion the field does not offer, which
  /// shows as Any, is then kept by a save that leaves Gender alone. A changed
  /// gender is sent, Any as `null`. A Manual group always clears it.
  static Future<Group> updateEligibility({
    required Map<String, dynamic> values,
    required Group group,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    final mode =
        values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
    final keepsGender =
        mode.usesCriteria &&
        GroupGender.of(values) == genderToForm(group.gender);
    final hasName = values.containsKey(GroupFormFields.nameId);
    final hasDescription = values.containsKey(GroupFormFields.descriptionId);
    return notifier.updateGroup(
      group.id,
      name: hasName ? (values[GroupFormFields.nameId] as String).trim() : null,
      description: hasDescription
          ? () => _nullIfEmpty(values[GroupFormFields.descriptionId])
          : null,
      minAge: () => c.minAge,
      maxAge: () => c.maxAge,
      strictAge: c.strictAge,
      gender: keepsGender ? null : () => c.gender,
      semiAuto: c.semiAuto,
    );
  }
}
